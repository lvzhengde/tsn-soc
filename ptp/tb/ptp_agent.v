/*++
// ptpv2 endpoint agent 
--*/
`include "ptpv2_defines.v"

module ptp_agent (
  //rtc and sw register interface
  input                  rtc_clk  ,
  input                  rst_sys_n ,

  input                  intxms_i,
  input                  int_rx_ptp_i,
  input                  int_tx_ptp_i,
  
  //xgmii/gmii/mii interface
  input                  rx_clk , 
  input                  tx_clk ,

`ifdef GFE_DESIGN
  input                  rx_en_i ,
  input                  rx_er_i ,
  input [7:0]            rxd_i  ,

  output reg             tx_en_o ,
  output reg             tx_er_o ,
  output reg [7:0]       txd_o  ,
`else
  input  [63:0]          xge_rxd_i,
  input  [7:0]           xge_rxc_i,

  output reg [63:0]      xge_txd_o,
  output reg [7:0]       xge_txc_o,
`endif

  //++ 
  //_standard ip register bus interface
  //--
  input                  bus2ip_clk   ,
  input                  bus2ip_rst_n  ,
  output reg  [31:0]     bus2ip_addr_o ,
  output reg  [31:0]     bus2ip_data_o ,
  output reg             bus2ip_rd_ce_o ,         //active high
  output reg             bus2ip_wr_ce_o ,         //active high
  input   [31:0]         ip2bus_data_i   
);  
`include "utils.v"

  parameter    CLOCK_MS = 0;     //0: ptp slave, others: ptp master;

  reg  [5:0]   clk_ctl;

  reg   [7:0]  frame_mem[255:0];
  integer      frame_len;
  reg   [7:0]  rcvd_frame[255:0];
  reg   [79:0] t1, t2, t3, t4;

`ifdef GFE_DESIGN
  reg          mii_mode;
`endif

  reg  [15:0]  tx_vlan_tag;
  reg  [15:0]  tx_length_type;
  reg  [15:0]  tx_ether2_type;
  reg  [15:0]  tx_udp_dport;
  reg  [3:0]   tx_messageType;
  reg  [15:0]  tx_sequenceId;
  reg  [79:0]  tx_timestamp;
  reg          peer_delay;

  reg tx_half_aligned;

  //++
  //_initial outputs
  //--
  initial begin
`ifdef GFE_DESIGN
    tx_en_o = 1'b0; 
    tx_er_o = 1'b0; 
    txd_o   = 8'h0; 
`else
    xge_txd_o = {8{`IDLE}};
    xge_txc_o = 8'hff;
    tx_half_aligned = 0;
`endif

    bus2ip_addr_o  = 32'h0; 
    bus2ip_data_o  = 32'h0; 
    bus2ip_rd_ce_o = 1'b0 ;      
    bus2ip_wr_ce_o = 1'b0 ;      
  end

  integer idx;

  initial begin
    frame_len = 0;

    t1 = 80'h0;
    t2 = 80'h0;
    t3 = 80'h0;
    t4 = 80'h0;

    clk_ctl = 5'b0;
`ifdef GFE_DESIGN
    mii_mode   = 1'b0;
`endif

    tx_vlan_tag = 0;
    tx_length_type = 0;
    tx_ether2_type = 0;
    tx_udp_dport = 0;
    tx_messageType = 0;
    tx_sequenceId = 0;
    tx_timestamp = 0;

    peer_delay     = 0;

    for(idx = 0; idx < 256; idx = idx + 1) begin
      frame_mem[idx] = 0;
      rcvd_frame[idx] = 0;
    end
  end

  //++
  //master send Sync and Follow_Up messages
  //--
  always begin : MASTER_SEND
    reg  [31:0] mt_temp1, mt_temp2, mt_temp3;

    @(posedge rst_sys_n);           //wait reset release
    tx_sequenceId = 16'h0;

    #5000;
    
    if(CLOCK_MS != 0) begin
      while(rst_sys_n == 1'b1) begin
        @(posedge intxms_i);            //xms(10ms or 8ms) interrupt
        repeat(50) @(posedge tx_clk);
        tx_sequenceId = tx_sequenceId + 1;
        tx_timestamp = 80'h0;
        ptpv2_send_message(tx_length_type, tx_ether2_type, tx_vlan_tag, 16'd319, 4'h0, tx_timestamp, tx_sequenceId, clk_ctl);  //send sync message
        repeat(600) @(posedge tx_clk);
        //read tx_timestamp
        read_reg({`TSU_BLK_ADDR, `TX_TS_ADDR0}, mt_temp1);
        read_reg({`TSU_BLK_ADDR, `TX_TS_ADDR1}, mt_temp2);
        read_reg({`TSU_BLK_ADDR, `TX_TS_ADDR2}, mt_temp3);
        
        t1 = {mt_temp1, mt_temp2, mt_temp3[31:16]}; //egress timestamp;


        if(clk_ctl[0] == 1'b0) begin //two-step clock
          repeat(50) @(posedge tx_clk);
          tx_timestamp = t1;
          ptpv2_send_message(tx_length_type, tx_ether2_type, tx_vlan_tag, 16'd320, 4'h8, tx_timestamp, tx_sequenceId, clk_ctl);  //send follow_up message
        end
      end
    end 
  end

  //++
  //slave send Delay_Req or Pdelay_Req message
  //--
  integer  intervalxms;

  always @(posedge tx_clk) begin
    if(rst_sys_n == 1'b0) begin
      intervalxms = 0;
      peer_delay = 0;

      tx_vlan_tag = 0;
      tx_length_type = 0;
      tx_ether2_type = 0;
      tx_udp_dport = 0;
      tx_messageType = 0;

      tx_sequenceId = 0;
      tx_timestamp = 0;


      for(idx = 0; idx < 256; idx = idx + 1) begin
        frame_mem[idx] = 0;
        rcvd_frame[idx] = 0;
      end

    end
  end

  always begin : SLAVE_SEND
    reg  [31:0] st_temp1, st_temp2, st_temp3;

    @(posedge rst_sys_n);             //wait reset release
    intervalxms = 0;
    tx_sequenceId = 16'h0;

    #5000;
    
    if(CLOCK_MS == 0) begin
      while(rst_sys_n == 1'b1) begin
        @(posedge intxms_i);           //xms(10ms or 8ms) interrupt
        intervalxms = intervalxms + 1;

        if(intervalxms == 4) begin
          intervalxms = 0;
          repeat(10000) @(posedge tx_clk);
          tx_sequenceId = tx_sequenceId + 1;
          
          if(peer_delay == 1'b0) begin    //delay request-response mechanism
            tx_timestamp = 80'h0;
            repeat(6000) @(posedge tx_clk);
            ptpv2_send_message(tx_length_type, tx_ether2_type, tx_vlan_tag, 16'd319, 4'h1, tx_timestamp, tx_sequenceId, clk_ctl);  //send delay_req message
            repeat(500) @(posedge tx_clk);
            read_reg({`TSU_BLK_ADDR, `TX_TS_ADDR0}, st_temp1);
            read_reg({`TSU_BLK_ADDR, `TX_TS_ADDR1}, st_temp2);
            read_reg({`TSU_BLK_ADDR, `TX_TS_ADDR2}, st_temp3);
            
            t3 = {st_temp1, st_temp2, st_temp3[31:16]}; //egress timestamp;
          end
          else begin                           //peer delay mechanism
            tx_timestamp = 80'h0;
            repeat(6000) @(posedge tx_clk);
            ptpv2_send_message(tx_length_type, tx_ether2_type, tx_vlan_tag, 16'd319, 4'h2, tx_timestamp, tx_sequenceId, clk_ctl);  //send pdelay_req message
            repeat(500) @(posedge tx_clk);
            read_reg({`TSU_BLK_ADDR, `TX_TS_ADDR0}, st_temp1);
            read_reg({`TSU_BLK_ADDR, `TX_TS_ADDR1}, st_temp2);
            read_reg({`TSU_BLK_ADDR, `TX_TS_ADDR2}, st_temp3);
            
            t1 = {st_temp1, st_temp2, st_temp3[31:16]}; //egress timestamp
          end
        end
      end
    end 
  end

  //++
  //master receive Delay_Req or Pdelay_Req messages
  //
    reg  [79:0]  rx_timestamp;
    reg          rx_is_ptp_message;
    reg  [3:0]   rx_messageType;
    reg  [63:0]  rx_correctionField;
    reg  [79:0]  rx_sourcePortIdentity;
    reg  [15:0]  rx_sequenceId;

  initial begin
    rx_timestamp = 0;
    rx_is_ptp_message = 0;

    rx_messageType = 0;
    rx_correctionField = 0;
    rx_sourcePortIdentity = 0;
    rx_sequenceId = 0;
  end

  always begin : MASTER_RECEIVE
    reg  [31:0] mr_temp1, mr_temp2, mr_temp3, mr_temp4;

    @(posedge rst_sys_n);

    #100;

    if(CLOCK_MS != 0) begin
      while(rst_sys_n == 1'b1) begin
        @(posedge int_rx_ptp_i);
        repeat(500) @(posedge tx_clk);
        parse_message(rx_messageType, rx_correctionField, rx_sourcePortIdentity, rx_sequenceId, rx_timestamp, rx_is_ptp_message);

        tx_sequenceId = rx_sequenceId;
        if(rx_messageType == 4'h1 && peer_delay == 1'b0) begin         //delay_req message received
          read_reg({`TSU_BLK_ADDR, `RX_TS_ADDR0}, mr_temp1);
          read_reg({`TSU_BLK_ADDR, `RX_TS_ADDR1}, mr_temp2);
          read_reg({`TSU_BLK_ADDR, `RX_TS_ADDR2}, mr_temp3);

          t4 = {mr_temp1, mr_temp2, mr_temp3[31:16]}; //ingress timestamp;
          tx_timestamp = t4;
          ptpv2_send_message(tx_length_type, tx_ether2_type, tx_vlan_tag, 16'd320, 4'h9, tx_timestamp, tx_sequenceId, clk_ctl);  //send delay_resp message
        end
        else if(rx_messageType == 4'h2 && peer_delay == 1'b1) begin    //pdelay_req message received
          read_reg({`TSU_BLK_ADDR, `RX_TS_ADDR0}, mr_temp1);
          read_reg({`TSU_BLK_ADDR, `RX_TS_ADDR1}, mr_temp2);
          read_reg({`TSU_BLK_ADDR, `RX_TS_ADDR2}, mr_temp3);
          read_reg({`TSU_BLK_ADDR, `RX_TVID_ADDR}, mr_temp4);

          t2 = {mr_temp1, mr_temp2, mr_temp3[31:16]}; //ingress timestamp;
          tx_timestamp = t2;

          //if(clk_ctl[0] == 1'b1) begin      //one-step clock
          //  tx_timestamp = 80'h0;
          //end

          ptpv2_send_message(tx_length_type, tx_ether2_type, tx_vlan_tag, 16'd319, 4'h3, tx_timestamp, tx_sequenceId, clk_ctl);  //send pdelay_resp message
          repeat(500) @(posedge tx_clk);
          read_reg({`TSU_BLK_ADDR, `TX_TS_ADDR0}, mr_temp1);
          read_reg({`TSU_BLK_ADDR, `TX_TS_ADDR1}, mr_temp2);
          read_reg({`TSU_BLK_ADDR, `TX_TS_ADDR2}, mr_temp3);
          t3 = {mr_temp1, mr_temp2, mr_temp3[31:16]}; //egress timestamp;

          if(clk_ctl[0] == 1'b0) begin      //two-step clock
            repeat(50) @(posedge tx_clk);
            tx_timestamp = t3;
            ptpv2_send_message(tx_length_type, tx_ether2_type, tx_vlan_tag, 16'd320, 4'ha, tx_timestamp, tx_sequenceId, clk_ctl);  //send pdelay_resp_follow_up message
          end
        end
      end
    end
  end

  //++
  //slave receive sync, follow_up, delay_resp, pdelay_resp, pdelay_resp_follow_up messages
  //--
    reg        [31:0]  path_delay;
    reg        [31:0]  pre_path_delay;
    reg        [31:0]  t3_t2, t4_t1;
    reg signed [47:0]  sc_diff;
    reg signed [31:0]  ns_diff;

  always @(posedge rx_clk) begin
    if(rst_sys_n == 1'b0) begin
      path_delay = 32'h0;
      pre_path_delay = 0;
      t1 = 0;
      t2 = 0;
      t3 = 0;
      t4 = 0;
      t3_t2 = 0;
      t4_t1 = 0;
      sc_diff = 0;
      ns_diff = 0;

      rx_messageType = 0;
      rx_correctionField = 0;
      rx_sourcePortIdentity = 0;
      rx_sequenceId = 0;
      rx_timestamp = 0;
      rx_is_ptp_message = 0;
    end
  end
  
  always begin : SLAVE_RECEIVE
    reg  [31:0] sr_temp1, sr_temp2, sr_temp3, sr_temp4, sr_temp5;

    @(posedge rst_sys_n);
    sc_diff = 0;
    ns_diff = 0;
    path_delay = 32'h0;
    pre_path_delay = 0;
    t1 = 0;
    t2 = 0;
    t3 = 0;
    t4 = 0;
    t3_t2 = 0;
    t4_t1 = 0;

    #100;

    if(CLOCK_MS == 0) begin
      while(rst_sys_n == 1'b1) begin
        @(posedge int_rx_ptp_i);
        repeat(500) @(posedge tx_clk);
        parse_message(rx_messageType, rx_correctionField, rx_sourcePortIdentity, rx_sequenceId, rx_timestamp, rx_is_ptp_message);
     
        if(rx_messageType == 4'h0) begin       //sync message received
          read_reg({`TSU_BLK_ADDR, `RX_TS_ADDR0}, sr_temp1);
          read_reg({`TSU_BLK_ADDR, `RX_TS_ADDR1}, sr_temp2);
          read_reg({`TSU_BLK_ADDR, `RX_TS_ADDR2}, sr_temp3);
          t2 = {sr_temp1, sr_temp2, sr_temp3[31:16]}; //ingress timestamp 
        
          if(clk_ctl[0] == 1'b1) begin    //one-step clock
            t1 = rx_timestamp;
            sc_diff = $signed(t1[79:32]) - $signed(t2[79:32]);
            ns_diff = $signed(t1[31:0]) + $signed(path_delay) - $signed(t2[31:0]);
           
            if(ns_diff >= 32'd1000000000) begin
              ns_diff = ns_diff - 32'd1000000000;
              sc_diff = sc_diff + 1;
            end
            else if(ns_diff < 0) begin
              ns_diff = ns_diff + 32'd1000000000;
              sc_diff = sc_diff - 1;
            end
              
            //adjust clock offset
            //set nanosecond offset
            write_reg({`RTC_BLK_ADDR, `NS_OFST_ADDR}, ns_diff[31:0]);
            //set second offset
            write_reg({`RTC_BLK_ADDR, `SC_OFST_ADDR0}, {16'b0, sc_diff[47:32]});
            write_reg({`RTC_BLK_ADDR, `SC_OFST_ADDR1},  sc_diff[31:0]);
            //offset adjustment take effect
            write_reg({`RTC_BLK_ADDR, `RTC_CTL_ADDR}, 32'h1);
          end  
        end
        else if(rx_messageType == 4'h8) begin  //follow_up message received
          if(clk_ctl[0] == 1'b0) begin    //two-step clock
            t1 = rx_timestamp;
            sc_diff = $signed(t1[79:32]) - $signed(t2[79:32]);
            ns_diff = $signed(t1[31:0]) + $signed(path_delay) - $signed(t2[31:0]);
           
            if(ns_diff >= 32'd1000000000) begin
              ns_diff = ns_diff - 32'd1000000000;
              sc_diff = sc_diff + 1;
            end
            else if(ns_diff < 0) begin
              ns_diff = ns_diff + 32'd1000000000;
              sc_diff = sc_diff - 1;
            end
              
            //adjust clock offset
            //set nanosecond offset
            write_reg({`RTC_BLK_ADDR, `NS_OFST_ADDR}, ns_diff[31:0]);
            //set second offset
            write_reg({`RTC_BLK_ADDR, `SC_OFST_ADDR0}, {16'b0, sc_diff[47:32]});
            write_reg({`RTC_BLK_ADDR, `SC_OFST_ADDR1}, sc_diff[31:0]);
            //offset adjustment take effect
            write_reg({`RTC_BLK_ADDR, `RTC_CTL_ADDR}, 32'h1);
          end  
        end
        else if(rx_messageType == 4'h9) begin  //delay_resp message received
          t4 = rx_timestamp;
          if(t4[31:0] > t1[31:0])
            t4_t1 = t4[31:0] - t1[31:0];
          else
            t4_t1 = t4[31:0] + 32'd1000000000 - t1[31:0];

          if(t3[31:0] > t2[31:0])
            t3_t2 = t3[31:0] - t2[31:0];
          else
            t3_t2 = t3[31:0] + 32'd1000000000 - t2[31:0];

          path_delay = (t4_t1 - t3_t2) >> 1;
        end
        else if(rx_messageType == 4'h3) begin  //pdelay_resp message received
          read_reg({`TSU_BLK_ADDR, `RX_TS_ADDR0}, sr_temp1);
          read_reg({`TSU_BLK_ADDR, `RX_TS_ADDR1}, sr_temp2);
          read_reg({`TSU_BLK_ADDR, `RX_TS_ADDR2}, sr_temp3);
          t4 = {sr_temp1, sr_temp2, sr_temp3[31:16]}; 
          if(t4[31:0] > t1[31:0])
            t4_t1 = t4[31:0] - t1[31:0];
          else
            t4_t1 = t4[31:0] + 32'd1000000000 - t1[31:0];

          if(clk_ctl[0] == 1'b0)          //two-step clock
            t2 = rx_timestamp;
          else begin                         //one-step clock
            t3_t2 = rx_correctionField[47:16];
            path_delay = (t4_t1 - t3_t2) >> 1;
          end
        end
        else if(rx_messageType == 4'ha) begin  //pdelay_resp_follow_up message received
          t3 = rx_timestamp;

          if(t4[31:0] > t1[31:0])
            t4_t1 = t4[31:0] - t1[31:0];
          else
            t4_t1 = t4[31:0] + 32'd1000000000 - t1[31:0];

          if(t3[31:0] > t2[31:0])
            t3_t2 = t3[31:0] - t2[31:0];
          else
            t3_t2 = t3[31:0] + 32'd1000000000 - t2[31:0];

          pre_path_delay = path_delay;
          path_delay = (t4_t1 - t3_t2) >> 1;
          if(path_delay >= 1000)
            path_delay = pre_path_delay;
        end
      end
    end
  end


  //++
  //task for sending ptpv2 messages
  //--
  task ptpv2_send_message(input [15:0] length_type, input [15:0] ether2_type, input [15:0] vlan_tag, input [15:0] udp_dport,
                    input [3:0] messageType, input [79:0] timestamp, input [15:0] sequenceId, input [4:0] vclk_ctl);
    integer j;
    integer h_l;
    integer tx_octets;
    reg [7:0] temp;

    begin
      temp = 0;
      frame_len = assemble_frame(length_type, ether2_type, vlan_tag, udp_dport, messageType, timestamp, sequenceId, vclk_ctl);
      
`ifdef GFE_DESIGN
      tx_en_o = 1'b0; 
      tx_er_o = 1'b0; 
      txd_o = 8'h0; 
`else
      xge_txd_o = {8{`IDLE}};
      xge_txc_o = 8'hff;
`endif
      #100;

      //transmit ge/fe frames.
`ifdef GFE_DESIGN
      if(mii_mode == 1'b0) begin   //gigabit ethernet
        for(j = 0; j < frame_len; j = j+1) begin
          temp = frame_mem[j];
          @(posedge tx_clk) 
          tx_en_o = 1;
          txd_o   = temp[7:0];
        end

        @(posedge tx_clk) 
        tx_en_o = 0;
        txd_o   = 0;
      end
      else begin                     //100m/10m ethernet
        for(j = 0; j < frame_len; j = j+1) begin
          temp = frame_mem[j];
          @(posedge tx_clk) 
          tx_en_o = 1;
          txd_o = temp[3:0];

          @(posedge tx_clk) 
          tx_en_o = 1;
          txd_o = temp[7:4];
        end

        @(posedge tx_clk) 
        tx_en_o = 0;
        txd_o = 0;
      end

      //transmit xge-like frames
      //note: indexed part-select is given by bit_vect[msb_base_expr -: width_expr]
      //width_expr shall be a constant expression.
`else 
      tx_octets = 0; 
      //transmit the first tuple
      @(posedge tx_clk) 
      if(tx_half_aligned == 0) begin
        xge_txd_o[7:0] = `START; 
        xge_txc_o[0] = 1;
        for(j = 1; j < 8; j = j+1) begin 
          xge_txd_o[j*8+7-:8] = frame_mem[j]; //xge_txdo[j*8+7-:8] is indexed part-select
          xge_txc_o[j] = 0;
        end 
        tx_octets = tx_octets + 8;
      end
      else begin
        h_l = 4;
        xge_txd_o[h_l*8+7-:8] = `START; 
        xge_txc_o[h_l] = 1;
        for(j = h_l+1; j < 8; j = j+1) begin
          xge_txd_o[j*8+7-:8] = frame_mem[j-h_l];
          xge_txc_o[j] = 0;
        end 
        tx_octets = tx_octets + h_l;
      end

      //transmit the intervening tuples
      while (tx_octets <= (frame_len-8)) begin
        @(posedge tx_clk) 
        for(j = 0; j < 8; j = j+1) begin
          xge_txd_o[j*8+7-:8] = frame_mem[tx_octets+j];
          xge_txc_o[j] = 0;
        end 
        tx_octets = tx_octets + 8;
      end

      //transmit the last tuple
      @(posedge tx_clk) 
      for(j = 0; j < 8; j = j+1) begin
        if((tx_octets+j) < frame_len) begin
         xge_txd_o[j*8+7-:8] = frame_mem[tx_octets+j];
         xge_txc_o[j] = 0;
        end
        else if((tx_octets+j) == frame_len) begin
         xge_txd_o[j*8+7-:8] = `TERMINATE;
         xge_txc_o[j] = 1;
        end
        else begin
         xge_txd_o[j*8+7-:8] = `IDLE;
         xge_txc_o[j] = 1;
        end
      end 
      tx_octets = frame_len + 1;

      //change half aligned alternatively
      tx_half_aligned = ~tx_half_aligned;

      //_i_d_l_e state
      @(posedge tx_clk) 
      xge_txd_o = {8{`IDLE}};
      xge_txc_o = 8'hff;
`endif

    end
  endtask

  //++
  //monitor packets----------
  //--
  reg  [11:0]  eth_count ;
  reg  [3:0]   first_nibble;
  integer      recv_frame_len;

  initial begin
    eth_count = 0;
    first_nibble = 0;
    recv_frame_len = 255;
  end
  
`ifdef GFE_DESIGN 
  always @(posedge rx_clk) begin
    if(rx_en_i == 1'b1)
      eth_count <= eth_count + 1;
    else
      eth_count <= 12'd0;
  end
 
  always @(posedge rx_clk) begin
    if(mii_mode == 1'b0) begin  //gigabit ethernet
      if(rx_en_i == 1'b1 && eth_count < 255) begin
        rcvd_frame[eth_count[11:0]] = rxd_i[7:0];      
      end
    end
    else begin                   //100_m/10_m _ethernet
      if(rx_en_i == 1'b1) begin
        if(eth_count[0] == 1'b0) 
          first_nibble <= rxd_i[3:0];
        else if(eth_count > 0 && eth_count < 511)
          rcvd_frame[eth_count[11:1]] = {rxd_i[3:0],first_nibble[3:0]};
      end
    end
  end

`else 
  //xge-like design
  always @(posedge rx_clk) begin : XGE_RCV_PROC
    integer i;

    for(i = 0; i < 8; i = i+1) begin
      if(xge_rxc_i[i] == 1 && xge_rxd_i[i*8+7-:8] == `START) begin 
        eth_count = 0;
        rcvd_frame[eth_count[7:0]] = 8'h55;
        eth_count = eth_count + 1;
      end
      else if(xge_rxc_i[i] == 0  && eth_count < 255) begin
        rcvd_frame[eth_count[7:0]] = xge_rxd_i[i*8+7-:8];      
        eth_count = eth_count + 1;
      end
      else if(xge_rxc_i[i] == 1 && xge_rxd_i[i*8+7-:8] == `TERMINATE)
        eth_count = 0;
    end //for i
  end
`endif  
 
  //++
  //_parsing ptpv2 messages
  //--
  task parse_message;
    output  [3:0]   messageType;
    output  [63:0]  correctionField;
    output  [79:0]  sourcePortIdentity;
    output  [15:0]  sequenceId;
    output  [79:0]  timestamp;
    output          is_ptp_message;

    reg [7:0]  eth_data;
    reg [15:0] eth_type;
    reg [15:0] ppp_id;
    reg [7:0]  snap_dsap;
    reg [7:0]  snap_ssap;
    reg [15:0] snap_length_type;
    reg [7:0]  next_layer_protocol;
    reg [15:0] destination_udp_port;
    integer k,m;
    integer eth_base_addr;
    integer ptp_base_addr;
    integer protocol_overhead;

    begin
      //initial variables
      messageType = 0;
      correctionField = 0;
      sourcePortIdentity = 0;
      sequenceId = 0;
      timestamp = 0;
      is_ptp_message = 0;

      eth_data = 0;
      eth_type = 0;
      next_layer_protocol = 0;
      destination_udp_port = 0;
      ppp_id = 0;
      snap_dsap = 0;
      snap_ssap = 0;
      snap_length_type = 0;
      k = 0;
      m = 0;
      eth_base_addr = 0;
      ptp_base_addr = 0;
      protocol_overhead = 0;
      //end initial

      for(k=0; k<recv_frame_len; k=k+1) begin
        eth_data = rcvd_frame[k];
        if(eth_data == 8'hd5) begin
          eth_base_addr = k+1;
          k = recv_frame_len;
        end
      end

      //get protocal_overhead;
      m = eth_base_addr + 12;
      protocol_overhead = 0;
      is_ptp_message = 0;

      eth_type = {rcvd_frame[m], rcvd_frame[m+1]};
      if(eth_type == 16'h8100) begin              //single vlan 
        eth_type = {rcvd_frame[m+4], rcvd_frame[m+5]};
        protocol_overhead = 4;
      end
      if(eth_type == 16'h88a8 || eth_type == 16'h9100 || eth_type == 16'h9200 || eth_type == 16'h9300 || 
                     eth_type == 16'h8100) begin  //double vlan
        eth_type = {rcvd_frame[m+8], rcvd_frame[m+9]};
        protocol_overhead = 8;
      end

      if(eth_type == 16'h88f7) begin         //ptpv2 in ethernet2 
        is_ptp_message = 1;
      end
      else if(eth_type == 16'h0800) begin   //may be ptpv2 in ipv4
        m = eth_base_addr + 14 + protocol_overhead;
        next_layer_protocol = rcvd_frame[m+9];
        destination_udp_port = {rcvd_frame[m+22], rcvd_frame[m+23]};

        if(next_layer_protocol == 8'd17 && (destination_udp_port == 16'd319 || destination_udp_port == 16'd320)) begin
          is_ptp_message = 1;
          protocol_overhead = protocol_overhead + 28;
        end
      end
      else if(eth_type == 16'h86dd) begin //may be ptpv2 in ipv6
        m = eth_base_addr + 14 + protocol_overhead;
        next_layer_protocol = rcvd_frame[m+6];
        destination_udp_port = {rcvd_frame[m+42], rcvd_frame[m+43]};

        if(next_layer_protocol == 8'd17 && (destination_udp_port == 16'd319 || destination_udp_port == 16'd320)) begin
          is_ptp_message = 1;
          protocol_overhead = protocol_overhead + 48;
        end
      end
      else if(eth_type == 16'h8864) begin  //pppo_e
        m = eth_base_addr + 14 + protocol_overhead;
        ppp_id = {rcvd_frame[m+6], rcvd_frame[m+7]};

        if(ppp_id == 16'h0021) begin         //pppoe, may be ptp over ipv4
          next_layer_protocol = rcvd_frame[m+17];
          destination_udp_port = {rcvd_frame[m+30], rcvd_frame[m+31]};

          if(next_layer_protocol == 8'd17 && (destination_udp_port == 16'd319 || destination_udp_port == 16'd320)) begin
            is_ptp_message = 1;
            protocol_overhead = protocol_overhead + 36;
          end
        end
        else if(ppp_id == 16'h0057) begin    //pppoe, may be ptp over ipv6
          next_layer_protocol = rcvd_frame[m+14];
          destination_udp_port = {rcvd_frame[m+50], rcvd_frame[m+51]};

          if(next_layer_protocol == 8'd17 && (destination_udp_port == 16'd319 || destination_udp_port == 16'd320)) begin
            is_ptp_message = 1;
            protocol_overhead = protocol_overhead + 56;
          end
        end
      end
      else if(eth_type <= 16'd1500) begin   //snap
        m = eth_base_addr + 14 + protocol_overhead;
        snap_dsap = rcvd_frame[m];
        snap_ssap = rcvd_frame[m+1];
        snap_length_type = {rcvd_frame[m+6], rcvd_frame[m+7]};

        if(snap_dsap == 8'haa && snap_ssap == 8'haa && snap_length_type == 16'h0800) begin       //may be ptp over ipv4 
          next_layer_protocol = rcvd_frame[m+17];
          destination_udp_port = {rcvd_frame[m+30], rcvd_frame[m+31]};

          if(next_layer_protocol == 8'd17 && (destination_udp_port == 16'd319 || destination_udp_port == 16'd320)) begin
            is_ptp_message = 1;
            protocol_overhead = protocol_overhead + 36;
          end
        end
        else if(snap_dsap == 8'haa && snap_ssap == 8'haa && snap_length_type == 16'h86dd) begin  //may be ptp over ipv6
          next_layer_protocol = rcvd_frame[m+14];
          destination_udp_port = {rcvd_frame[m+50], rcvd_frame[m+51]};

          if(next_layer_protocol == 8'd17 && (destination_udp_port == 16'd319 || destination_udp_port == 16'd320)) begin
            is_ptp_message = 1;
            protocol_overhead = protocol_overhead + 56;
          end
        end
        else if(snap_dsap == 8'haa && snap_ssap == 8'haa && snap_length_type == 16'h88f7) begin  //snap 802.3
          is_ptp_message = 1;
          protocol_overhead = protocol_overhead + 8;
        end
      end
      else begin
        is_ptp_message = 0;
      end
          
      if(is_ptp_message == 1) begin
        ptp_base_addr = eth_base_addr+14+protocol_overhead;

        eth_data = rcvd_frame[ptp_base_addr];
        messageType = eth_data[3:0];
  
        //extract related data fields
        correctionField[63:56] = rcvd_frame[ptp_base_addr+8];
        correctionField[55:48] = rcvd_frame[ptp_base_addr+9];
        correctionField[47:40] = rcvd_frame[ptp_base_addr+10];
        correctionField[39:32] = rcvd_frame[ptp_base_addr+11];
        correctionField[31:24] = rcvd_frame[ptp_base_addr+12];
        correctionField[23:16] = rcvd_frame[ptp_base_addr+13];
        correctionField[15:8]  = rcvd_frame[ptp_base_addr+14];
        correctionField[7:0]   = rcvd_frame[ptp_base_addr+15];

        sourcePortIdentity[79:72] = rcvd_frame[ptp_base_addr+20];
        sourcePortIdentity[71:64] = rcvd_frame[ptp_base_addr+21];
        sourcePortIdentity[63:56] = rcvd_frame[ptp_base_addr+22];
        sourcePortIdentity[55:48] = rcvd_frame[ptp_base_addr+23];
        sourcePortIdentity[47:40] = rcvd_frame[ptp_base_addr+24];
        sourcePortIdentity[39:32] = rcvd_frame[ptp_base_addr+25];
        sourcePortIdentity[31:24] = rcvd_frame[ptp_base_addr+26];
        sourcePortIdentity[23:16] = rcvd_frame[ptp_base_addr+27];
        sourcePortIdentity[15:8]  = rcvd_frame[ptp_base_addr+28];
        sourcePortIdentity[7:0]   = rcvd_frame[ptp_base_addr+29];

        sequenceId[15:8] = rcvd_frame[ptp_base_addr+30];
        sequenceId[7:0]  = rcvd_frame[ptp_base_addr+31];

        timestamp[79:72] = rcvd_frame[ptp_base_addr+34];
        timestamp[71:64] = rcvd_frame[ptp_base_addr+35];
        timestamp[63:56] = rcvd_frame[ptp_base_addr+36];
        timestamp[55:48] = rcvd_frame[ptp_base_addr+37];
        timestamp[47:40] = rcvd_frame[ptp_base_addr+38];
        timestamp[39:32] = rcvd_frame[ptp_base_addr+39];
        timestamp[31:24] = rcvd_frame[ptp_base_addr+40];
        timestamp[23:16] = rcvd_frame[ptp_base_addr+41];
        timestamp[15:8]  = rcvd_frame[ptp_base_addr+42];
        timestamp[7:0]   = rcvd_frame[ptp_base_addr+43];
      end
      else begin
        messageType = 4'hf;
        correctionField = 64'h0;
        sourcePortIdentity = 80'h0;
        sequenceId = 16'h0;
        timestamp = 80'h0;
      end
    end
  endtask

  //++
  // assemble all kinds of frames
  //--
  function integer assemble_frame(input [15:0] length_type, input [15:0] ether2_type, input [15:0] vlan_tag, input [15:0] udp_dport,
                    input [3:0] messageType, input [79:0] timestamp, input [15:0] sequenceId, input [4:0] vclk_ctl);
    integer len;
    integer m;
    integer pad_len;
    integer len_sub_vlan;
    reg [31:0] frame_crc;

    begin
      len = 0;
      //preamble
      frame_mem[len+0] = 8'h55;  frame_mem[len+1] = 8'h55;  frame_mem[len+2] = 8'h55;  frame_mem[len+3] = 8'h55;
      frame_mem[len+4] = 8'h55;  frame_mem[len+5] = 8'h55;  frame_mem[len+6] = 8'h55;  frame_mem[len+7] = 8'hd5;
      len = len + 8;
     
      //destination address
      frame_mem[len+0] = 8'h01;  frame_mem[len+1] = 8'h1b;  frame_mem[len+2] = 8'h19;  frame_mem[len+3] = 8'h00;
      frame_mem[len+4] = 8'h00;  frame_mem[len+5] = 8'h00;  
      len = len + 6;

      //source address
      frame_mem[len+0] = 8'h00;  frame_mem[len+1] = 8'h80;  frame_mem[len+2] = 8'h63;  frame_mem[len+3] = 8'h00;
      frame_mem[len+4] = 8'h09;  frame_mem[len+5] = 8'hba;
      len = len + 6;

      //external vlan tag
      if(vlan_tag == 2) begin
        frame_mem[len+0] = 8'h88;  frame_mem[len+1] = 8'ha8;  frame_mem[len+2] = 8'h00;  frame_mem[len+3] = 8'h02;
        len = len + 4;
      end
      //inner vlan tag or single vlan
      if(vlan_tag == 1 || vlan_tag == 2) begin
        frame_mem[len+0] = 8'h81;  frame_mem[len+1] = 8'h00;  frame_mem[len+2] = 8'h00;  frame_mem[len+3] = 8'h02;
        len = len + 4;
      end

      //ethernet length/type field
      frame_mem[len+0] = length_type[15:8];  frame_mem[len+1] = length_type[7:0];
      len = len + 2;

      //802.3/snap header
      if(length_type <= 1500) begin
        //snap header
        frame_mem[len+0] = 8'haa;  frame_mem[len+1] = 8'haa;  frame_mem[len+2] = 8'h00;  frame_mem[len+3] = 8'h00;
        frame_mem[len+4] = 8'h00;  frame_mem[len+5] = 8'h00;  
        frame_mem[len+6] = ether2_type[15:8];  frame_mem[len+7] = ether2_type[7:0];
        len = len + 8;
      end
      else if(length_type == 16'h8864) begin
        //pppoe header
        frame_mem[len+0] = 8'h00;  frame_mem[len+1] = 8'h00;  frame_mem[len+2] = 8'h00;  frame_mem[len+3] = 8'h00;
        frame_mem[len+4] = 8'h00;  frame_mem[len+5] = 8'h00;  
        frame_mem[len+6] = ether2_type[15:8];  frame_mem[len+7] = ether2_type[7:0];
        len = len + 8;
      end

      //ipv4 header
      if(length_type == 16'h0800 || (length_type < 1500 && ether2_type == 16'h0800) || (length_type == 16'h8864 && ether2_type == 16'h0021)) begin
        frame_mem[len+0] = 8'h45;  frame_mem[len+1] = 8'h00;  frame_mem[len+2] = 8'h00;  frame_mem[len+3] = 8'h48;
        len = len + 4;
        frame_mem[len+0] = 8'h00;  frame_mem[len+1] = 8'h00;  frame_mem[len+2] = 8'h00;  frame_mem[len+3] = 8'h00;
        len = len + 4;
        frame_mem[len+0] = 8'hff;  frame_mem[len+1] = 8'd17;  frame_mem[len+2] = 8'h00;  frame_mem[len+3] = 8'h00;
        len = len + 4;
        frame_mem[len+0] = 192;    frame_mem[len+1] = 168;    frame_mem[len+2] = 1;      frame_mem[len+3] = 11;
        len = len + 4;
        frame_mem[len+0] = 224;    frame_mem[len+1] = 0;      frame_mem[len+2] = 1;      frame_mem[len+3] = 129; 
        len = len + 4;
      end

      //ipv6 header
      if(length_type == 16'h86dd || (length_type < 1500 && ether2_type == 16'h86dd) ||(length_type == 16'h8864 && ether2_type == 16'h0057)) begin
        frame_mem[len+0] = 8'h60;  frame_mem[len+1] = 8'h00;  frame_mem[len+2] = 8'h00;  frame_mem[len+3] = 8'h00;
        len = len + 4;
        frame_mem[len+0] = 8'h00;  frame_mem[len+1] = 8'h36;  frame_mem[len+2] = 8'd17;  frame_mem[len+3] = 8'hff;
        len = len + 4;
        frame_mem[len+0] = 8'h11;  frame_mem[len+1] = 8'h11;  frame_mem[len+2] = 8'h11;  frame_mem[len+3] = 8'h11;
        len = len + 4;
        frame_mem[len+0] = 8'h11;  frame_mem[len+1] = 8'h11;  frame_mem[len+2] = 8'h11;  frame_mem[len+3] = 8'h11;
        len = len + 4;
        frame_mem[len+0] = 8'h11;  frame_mem[len+1] = 8'h11;  frame_mem[len+2] = 8'h11;  frame_mem[len+3] = 8'h11;
        len = len + 4;
        frame_mem[len+0] = 8'h11;  frame_mem[len+1] = 8'h11;  frame_mem[len+2] = 8'h11;  frame_mem[len+3] = 8'h11;
        len = len + 4;
        frame_mem[len+0] = 8'hff;  frame_mem[len+1] = 8'h00;  frame_mem[len+2] = 8'h00;  frame_mem[len+3] = 8'h00;
        len = len + 4;
        frame_mem[len+0] = 8'h00;  frame_mem[len+1] = 8'h00;  frame_mem[len+2] = 8'h00;  frame_mem[len+3] = 8'h00;
        len = len + 4;
        frame_mem[len+0] = 8'h00;  frame_mem[len+1] = 8'h00;  frame_mem[len+2] = 8'h00;  frame_mem[len+3] = 8'h00;
        len = len + 4;
        frame_mem[len+0] = 8'h00;  frame_mem[len+1] = 8'h00;  frame_mem[len+2] = 8'h01;  frame_mem[len+3] = 8'h81; 
        len = len + 4;
      end

      //udp header
      if(length_type == 16'h0800 || length_type == 16'h86dd || (length_type < 1500 && (ether2_type == 16'h0800 || ether2_type == 16'h86dd))
            || (length_type == 16'h8864 && (ether2_type == 16'h0021 || ether2_type == 16'h0057))) begin
        frame_mem[len+0] = 8'h00;  frame_mem[len+1] = 8'h00;  frame_mem[len+2] = udp_dport[15:8];  frame_mem[len+3] = udp_dport[7:0];
        len = len + 4;
        frame_mem[len+0] = 8'h00;  frame_mem[len+1] = 8'h34;  frame_mem[len+2] = 8'hab;            frame_mem[len+3] = 8'hcd;
        len = len + 4;
      end

      //ptpv2 message payload
      frame_mem[len+0] = {4'h0, messageType}; frame_mem[len+1] = 8'h02;     //transport_specific, messageType : minorVersionPTP, versionPTP
      len = len + 2;

      if(messageType == 4'h0 || messageType == 4'h1 || messageType == 4'h8) begin
        frame_mem[len+0] = 8'h00; frame_mem[len+1] = 8'h2c;     //messageLength
      end
      else begin
        frame_mem[len+0] = 8'h00; frame_mem[len+1] = 8'h36;     //messageLength
      end

      len = len + 2;
      frame_mem[len+0] = 8'h00; frame_mem[len+1] = 8'h00;     //domain_number, minorSdoId
      len = len + 2;
      frame_mem[len+0] = 8'hfd; frame_mem[len+1] = 8'hff;     //flags
      len = len + 2;
      frame_mem[len+0] = 8'h00; frame_mem[len+1] = 8'h00; frame_mem[len+2] = 8'h00; frame_mem[len+3] = 8'h00;  //correctionField[63:32]
      len = len + 4;
      frame_mem[len+0] = 8'h00; frame_mem[len+1] = 8'h00; frame_mem[len+2] = 8'h00; frame_mem[len+3] = 8'h00;  //correctionField[31:0]
      len = len + 4;
    if(vclk_ctl[0] == 1'b1 && messageType == 4'h3) begin
    //messageTypeSpecific
        frame_mem[len+0] = timestamp[31:24]; frame_mem[len+1] = timestamp[23:16]; frame_mem[len+2] = timestamp[15:8]; frame_mem[len+3] = timestamp[7:0];  
        timestamp = 80'h0;
    end
    else begin
        frame_mem[len+0] = 8'h00; frame_mem[len+1] = 8'h00; frame_mem[len+2] = 8'h00; frame_mem[len+3] = 8'h00;  //messageTypeSpecific
      end
      len = len + 4;
      frame_mem[len+0] = 8'h00; frame_mem[len+1] = 8'h80; frame_mem[len+2] = 8'h63; frame_mem[len+3] = 8'hff;  //sourcePortIdentity[79:48]
      len = len + 4;
      frame_mem[len+0] = 8'hff; frame_mem[len+1] = 8'h00; frame_mem[len+2] = 8'h09; frame_mem[len+3] = 8'hba;  //sourcePortIdentity[47:16]
      len = len + 4;
      frame_mem[len+0] = 8'h00; frame_mem[len+1] = 8'h02;     //sourcePortIdentity[15:0]    
      len = len + 2;                   
      frame_mem[len+0] = sequenceId[15:8]; frame_mem[len+1] = sequenceId[7:0];     //sequenceId
      len = len + 2;
      frame_mem[len+0] = 8'h00; frame_mem[len+1] = 8'h00;     //controlField, logMessageInterval
      len = len + 2;
      frame_mem[len+0] = timestamp[79:72]; frame_mem[len+1] = timestamp[71:64];   //originTimestamp/preciseOriginTimestamp/receiveTimestamp
      len = len + 2;
      frame_mem[len+0] = timestamp[63:56]; frame_mem[len+1] = timestamp[55:48]; frame_mem[len+2] = timestamp[47:40]; frame_mem[len+3] = timestamp[39:32];
      len = len + 4;
      frame_mem[len+0] = timestamp[31:24]; frame_mem[len+1] = timestamp[23:16]; frame_mem[len+2] = timestamp[15:8]; frame_mem[len+3] = timestamp[7:0];
      len = len + 4;

      if(messageType == 4'h2 || messageType == 4'h3 || messageType == 4'h9 || messageType == 4'ha) begin
        frame_mem[len+0] = 8'h00; frame_mem[len+1] = 8'h00;
        len = len + 2;
        frame_mem[len+0] = 8'h00; frame_mem[len+1] = 8'h00; frame_mem[len+2] = 8'h00; frame_mem[len+3] = 8'h00;
        len = len + 4;
        frame_mem[len+0] = 8'h00; frame_mem[len+1] = 8'h00; frame_mem[len+2] = 8'h00; frame_mem[len+3] = 8'h00;
        len = len + 4;
      end

      //padding octets
      len_sub_vlan = (vlan_tag == 2) ? len-8 : ((vlan_tag == 1) ? len-4 : len);
      pad_len = 64 - (len_sub_vlan-8+4);
      if( length_type == 16'h86dd || (length_type < 1500 &&  ether2_type == 16'h86dd))
        pad_len = 2;

      if(pad_len > 0) begin
        for(m = 0; m < pad_len; m = m+1) begin
          frame_mem[len] = 8'h00;
          len = len + 1;
        end
      end

      //crc octets
      frame_crc = calculate_crc(len);
      frame_mem[len+0] = frame_crc[7:0];  frame_mem[len+1] = frame_crc[15:8];  frame_mem[len+2] = frame_crc[23:16];  frame_mem[len+3] = frame_crc[31:24];
      len = len + 4;
     
      assemble_frame = len;
    end
  endfunction

  //++
  //_calculate fcs
  //--
  function [31:0] calculate_crc(input integer data_len);
      integer i;
      reg [31:0] current_crc;
      reg [31:0] next_crc;
    begin
      current_crc = 32'hffffffff;
      for(i = 8; i < data_len; i = i + 1) begin
        next_crc = nextCRC32_D8(reverse_8b(frame_mem[i]), current_crc);
        current_crc = next_crc; 
      end

      calculate_crc = ~reverse_32b(current_crc);
    end
  endfunction

  //++
  //_tasks for register read/write
  //--
  task write_reg;
    input [31:0] wr_addr;
    input [31:0] wr_data;

    begin
      force bus2ip_wr_ce_o = 0;
      force bus2ip_addr_o = 32'h0;
      force bus2ip_data_o = 32'h0;

      @(posedge bus2ip_clk) begin
        force bus2ip_wr_ce_o = 1;
        force bus2ip_addr_o = wr_addr;
        force bus2ip_data_o = wr_data;
      end

      @(posedge bus2ip_clk);

      @(posedge bus2ip_clk) begin
        force bus2ip_wr_ce_o = 0;
        force bus2ip_addr_o = 32'h0;
        force bus2ip_data_o = 32'h0;
      end

      release bus2ip_wr_ce_o;
      release bus2ip_addr_o;
      release bus2ip_data_o; 
    end
  endtask

  task read_reg;
    input  [31:0] rd_addr;
    output [31:0] rd_data;

    begin
      force bus2ip_rd_ce_o = 1'b0;
      force bus2ip_addr_o = 32'h0;

      @(posedge bus2ip_clk) begin
        force bus2ip_rd_ce_o = 1'b1;
        force bus2ip_addr_o = rd_addr; 
      end

      @(posedge bus2ip_clk);
      @(posedge bus2ip_clk);

      @(posedge bus2ip_clk) 
      rd_data = ip2bus_data_i;

      @(posedge bus2ip_clk);
     
      @(posedge bus2ip_clk);
      force bus2ip_rd_ce_o = 1'b0;  

      @(posedge bus2ip_clk);
      @(posedge bus2ip_clk);
      
      force bus2ip_addr_o = 32'h0;
       
      release bus2ip_rd_ce_o;
      release bus2ip_addr_o ;
    end
  endtask

endmodule



