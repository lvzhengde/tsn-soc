/*++
//  rx frame parsing
//  start of frame should be : S Dp Dp Dp Dp Dp Dp SFD
--*/

`include "ptpv2_defines.v"

module rx_parse(
  //xgmii interface
  input               rx_clk,
  input               rx_rst_n,
  input               rx_clk_en_i,            //for adapting to gmii/mii

  input  [63:0]       rxd_i,
  input  [7:0]        rxc_i,

  //signals to rx_emb_ts
  output [63:0]       rxd_emb_o,
  output [7:0]        rxc_emb_o,

  output  [10:0]      eth_count_base_o,      
  output  [10:0]      ptp_addr_base_o,
  output  [3:0]       ptp_messageType_o,          
  output  [63:0]      ptp_correctionField_o,
  output              is_ptp_message_o,  
  output              get_sfd_done_o,

  //signals to rx_rcst
  output [63:0]       rxd_crc_p3_o,
  output [7:0]        rxc_crc_p3_o,

  //configuration register i/f
  input  [31:0]       tsu_cfg_i,
  
  //timestamp i/f, sync to rtc_clk
  output reg          rxts_trig_o,
  output reg          rxts_valid_o,
  
  output reg [79:0]   rx_sourcePortIdentity_o,  
  output reg [15:0]   rx_flagField_o,
  output reg [15:0]   rx_seqId_o,                 
  output reg [3:0]    rx_versionPTP_o,
  output reg [3:0]    rx_minorVersionPTP_o,
  output reg [3:0]    rx_messageType_o,  
  output reg [3:0]    rx_majorSdoId_o,

  //ptpv2 rx interrupt signal 
  output reg          int_rx_ptp_o
);
  parameter PTPETHPRIMAD  = 48'h011b_1900_0000;
  parameter PTPETHPDELAD  = 48'h0180_C200_000E;
  parameter PTPIPV4PRIMAD = {8'd224, 8'd0, 8'd1, 8'd129}; //PTP primary ipv4 address
  parameter PTPIPV4PDELAD = {8'd224, 8'd0, 8'd1, 8'd107}; //PTP pdelay ipv4 address
  //parameter PTPIPV6PRIMAD = 128'hff0x0000000000000000000000000181;
  parameter PTPIPV6PDELAD = 128'hff02000000000000000000000000006b;

  genvar i;   

  //xgmii input delay line
  reg  [63:0]         rxd_z1, rxd_z2, rxd_z3, rxd_z4, rxd_z5, rxd_z6;
  reg  [7:0]          rxc_z1, rxc_z2, rxc_z3, rxc_z4, rxc_z5, rxc_z6;

  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n) begin
       {rxd_z1, rxd_z2, rxd_z3, rxd_z4, rxd_z5, rxd_z6} <= {6{64'h0}};
       {rxc_z1, rxc_z2, rxc_z3, rxc_z4, rxc_z5, rxc_z6} <= {6{8'h0}};
    end
    else if(rx_clk_en_i) begin
       {rxd_z1, rxd_z2, rxd_z3, rxd_z4, rxd_z5, rxd_z6} <= {rxd_i, rxd_z1, rxd_z2, rxd_z3, rxd_z4, rxd_z5}; 
       {rxc_z1, rxc_z2, rxc_z3, rxc_z4, rxc_z5, rxc_z6} <= {rxc_i, rxc_z1, rxc_z2, rxc_z3, rxc_z4, rxc_z5}; 
    end
  end

  //++
  //detect start of frame and end of frame
  //--
  reg  [7:0] is_sfd;
  reg  [7:0] is_start, is_start_z1;

  always @(posedge rx_clk or negedge rx_rst_n) begin 
    if(!rx_rst_n) 
      is_start_z1 <= 8'h0;
    else if(rx_clk_en_i) 
      is_start_z1 <= is_start;
  end

  generate
    for(i = 0; i < 8; i = i+1) begin
      always @(*) begin
        is_start[i] = 0;
        is_sfd[i] = 0;

        if(rxd_i[8*i+7: 8*i] == `START && rxc_i[i] == 1)
          is_start[i] = 1;
        if(rxd_i[8*i+7: 8*i] == `SFD && rxc_i[i] == 0)
          is_sfd[i] = 1;
      end
    end //for i
  endgenerate

  reg    get_sfd_done_p1, get_sfd_done;
  reg    get_sfd_done_z1, get_sfd_done_z2, get_sfd_done_z3, get_sfd_done_z4, get_sfd_done_z5, get_sfd_done_z6;
  reg    get_efd_done_p1, get_efd_done;                                                                     
  reg    get_efd_done_z1, get_efd_done_z2, get_efd_done_z3, get_efd_done_z4, get_efd_done_z5, get_efd_done_z6;

  //start of frame
  always @(*) begin
    if(get_efd_done_p1 && get_efd_done)
      get_sfd_done_p1 = 0;
    else if((|is_sfd) && ((|is_start) || (|is_start_z1)))
      get_sfd_done_p1 = 1;
    else
      get_sfd_done_p1 = get_sfd_done;
  end
  
  always @(posedge rx_clk or negedge rx_rst_n) begin 
    if(!rx_rst_n) 
      get_sfd_done <= 0;
    else if(rx_clk_en_i) 
      get_sfd_done <= get_sfd_done_p1;
  end

  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n)
      {get_sfd_done_z1, get_sfd_done_z2, get_sfd_done_z3, get_sfd_done_z4, get_sfd_done_z5, get_sfd_done_z6} <= {6{1'b0}};
    else if(rx_clk_en_i)
      {get_sfd_done_z1, get_sfd_done_z2, get_sfd_done_z3, get_sfd_done_z4, get_sfd_done_z5, get_sfd_done_z6} <= {get_sfd_done, 
                        get_sfd_done_z1, get_sfd_done_z2, get_sfd_done_z3, get_sfd_done_z4, get_sfd_done_z5}; 
  end
  
  //end of frame
  always @(*) begin
    if((rxd_i[`LANE0] == `TERMINATE && rxc_i[0]) || (rxd_i[`LANE1] == `TERMINATE && rxc_i[1]) ||
	     (rxd_i[`LANE2] == `TERMINATE && rxc_i[2]) || (rxd_i[`LANE3] == `TERMINATE && rxc_i[3]) ||
       (rxd_i[`LANE4] == `TERMINATE && rxc_i[4]) || (rxd_i[`LANE5] == `TERMINATE && rxc_i[5]) ||
	     (rxd_i[`LANE6] == `TERMINATE && rxc_i[6]) || (rxd_i[`LANE7] == `TERMINATE && rxc_i[7])) 
	    get_efd_done_p1 = 1; 
    else if((rxd_i[`LANE0] == `START && rxc_i[0]) || (rxd_i[`LANE1] == `START && rxc_i[1]) ||
	          (rxd_i[`LANE2] == `START && rxc_i[2]) || (rxd_i[`LANE3] == `START && rxc_i[3]) ||
            (rxd_i[`LANE4] == `START && rxc_i[4]) || (rxd_i[`LANE5] == `START && rxc_i[5]) ||
	          (rxd_i[`LANE6] == `START && rxc_i[6]) || (rxd_i[`LANE7] == `START && rxc_i[7])) 
	    get_efd_done_p1 = 0; 
    else
      get_efd_done_p1 = get_efd_done;
  end

  always @(posedge rx_clk or negedge rx_rst_n) begin 
    if(!rx_rst_n) 
      get_efd_done <= 0;
    else if(rx_clk_en_i) 
      get_efd_done <= get_efd_done_p1;
  end

  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n)
      {get_efd_done_z1, get_efd_done_z2, get_efd_done_z3, get_efd_done_z4, get_efd_done_z5, get_efd_done_z6} <= {6{1'b0}};
    else if(rx_clk_en_i)
      {get_efd_done_z1, get_efd_done_z2, get_efd_done_z3, get_efd_done_z4, get_efd_done_z5, get_efd_done_z6} <= {get_efd_done, 
                        get_efd_done_z1, get_efd_done_z2, get_efd_done_z3, get_efd_done_z4, get_efd_done_z5}; 
  end

  //++
  //ethernet octet count at lane 0
  //--
 reg  [10:0]   eth_count_base, eth_count_base_z1, eth_count_base_z2, eth_count_base_z3, 
               eth_count_base_z4, eth_count_base_z5;
 
  //note: the eth_count of SFD is set to 7 
  //eth_count_base aligned with rxd_z1 due to one sample delay
  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n)
      eth_count_base <= 0;
    else if(rx_clk_en_i) begin
      if(get_sfd_done_p1 == 1 && get_sfd_done == 0) begin
        if(is_sfd[0])
          eth_count_base <= 7;
        else if(is_sfd[1])
          eth_count_base <= 6;
        else if(is_sfd[2])    
          eth_count_base <= 5;
        else if(is_sfd[3])    
          eth_count_base <= 4;
        else if(is_sfd[4])    
          eth_count_base <= 3;
        else if(is_sfd[5])    
          eth_count_base <= 2;
        else if(is_sfd[6])    
          eth_count_base <= 1;
        else if(is_sfd[7])    
          eth_count_base <= 0;
      end
      else if(get_efd_done == 1 && get_efd_done_z1 == 0)
        eth_count_base <= 0;
      else if(get_sfd_done == 1) 
          eth_count_base <= eth_count_base + 8;
    end
  end

  //eth_count_base delay line
  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n) begin
       {eth_count_base_z1, eth_count_base_z2, eth_count_base_z3, eth_count_base_z4, eth_count_base_z5} <= {5{11'h0}};
    end
    else if(rx_clk_en_i) begin
       {eth_count_base_z1, eth_count_base_z2, eth_count_base_z3, eth_count_base_z4, eth_count_base_z5} <= {eth_count_base, 
        eth_count_base_z1, eth_count_base_z2, eth_count_base_z3, eth_count_base_z4};
    end
  end

  //rx timestamp plane trigger signal
  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n)
      rxts_trig_o <= 0;
    else if(rx_clk_en_i)
      rxts_trig_o <= (get_sfd_done_p1 == 1'b1 && get_sfd_done == 1'b0);                                                         
  end
  
  //++
  //parse layer 2 ethernet header
  //--
  reg  [47:0]      mac_da;
  reg  [47:0]      mac_sa;
  reg  [15:0]      length_type;
  reg  [15:0]      vlan1_length_type;
  reg  [15:0]      vlan2_length_type;

  reg  [47:0]      mac_da_lane[7:0];
  reg  [47:0]      mac_sa_lane[7:0];
  reg  [15:0]      length_type_lane[7:0];
  reg  [15:0]      vlan1_length_type_lane[7:0];
  reg  [15:0]      vlan2_length_type_lane[7:0];

  generate
    for(i = 0; i < 8; i = i+1) begin : PARSE_ETHERNET_HEADER
      reg [10:0] eth_count;
      reg [7:0]  rxd_lane;

      reg [47:0] mac_da_tmp;
      reg [47:0] mac_sa_tmp;
      reg [15:0] length_type_tmp;
      reg [15:0] vlan1_length_type_tmp;
      reg [15:0] vlan2_length_type_tmp;

      always @(*) begin
        rxd_lane = 8'h0;
        eth_count = 0;

        if(get_sfd_done == 1) begin
          eth_count = eth_count_base + i;
        end

        rxd_lane = rxd_z1[8*i+7: 8*i];
      end

      always @(*) begin
          mac_da_tmp = mac_da;
          mac_sa_tmp = mac_sa;
          length_type_tmp = length_type;
          vlan1_length_type_tmp = vlan1_length_type;
          vlan2_length_type_tmp = vlan2_length_type;

        if(get_sfd_done == 1 && (!rxc_z1[i])) begin
          if(eth_count == 11'd8)   mac_da_tmp[47:40]     = rxd_lane;
          if(eth_count == 11'd9)   mac_da_tmp[39:32]     = rxd_lane;        
          if(eth_count == 11'd10)  mac_da_tmp[31:24]     = rxd_lane;        
          if(eth_count == 11'd11)  mac_da_tmp[23:16]     = rxd_lane;        
          if(eth_count == 11'd12)  mac_da_tmp[15:8]      = rxd_lane;        
          if(eth_count == 11'd13)  mac_da_tmp[7:0]       = rxd_lane; 

          if(eth_count == 11'd14)  mac_sa_tmp[47:40]     = rxd_lane;
          if(eth_count == 11'd15)  mac_sa_tmp[39:32]     = rxd_lane;        
          if(eth_count == 11'd16)  mac_sa_tmp[31:24]     = rxd_lane;        
          if(eth_count == 11'd17)  mac_sa_tmp[23:16]     = rxd_lane;        
          if(eth_count == 11'd18)  mac_sa_tmp[15:8]      = rxd_lane;        
          if(eth_count == 11'd19)  mac_sa_tmp[7:0]       = rxd_lane;          
            
          if(eth_count == 11'd20)  length_type_tmp[15:8] = rxd_lane;
          if(eth_count == 11'd21)  length_type_tmp[7:0]  = rxd_lane; 
          
          if(eth_count == 11'd24)  vlan1_length_type_tmp[15:8] = rxd_lane;
          if(eth_count == 11'd25)  vlan1_length_type_tmp[7:0]  = rxd_lane; 
            
          if(eth_count == 11'd28)  vlan2_length_type_tmp[15:8] = rxd_lane;
          if(eth_count == 11'd29)  vlan2_length_type_tmp[7:0]  = rxd_lane;        
        end 
        else if(get_efd_done_z1 == 1) begin
          mac_da_tmp = 48'h0;
          mac_sa_tmp = 48'h0;
          length_type_tmp = 16'h0;
          vlan1_length_type_tmp = 16'h0;
          vlan2_length_type_tmp = 16'h0;
        end
      end //always

      always @(*) begin
        mac_da_lane[i] = mac_da_tmp;
        mac_sa_lane[i] = mac_sa_tmp;
        length_type_lane[i] = length_type_tmp;
        vlan1_length_type_lane[i] = vlan1_length_type_tmp;
        vlan2_length_type_lane[i] = vlan2_length_type_tmp;
      end
    end //for i
  endgenerate

  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n) begin
      mac_da <= 48'h0;
      mac_sa <= 48'h0;
      length_type <= 16'h0;
      vlan1_length_type <= 16'h0;
      vlan2_length_type <= 16'h0;
    end
    else if(rx_clk_en_i) begin
      mac_da <= `OR_LANE(mac_da_lane);
      mac_sa <= `OR_LANE(mac_sa_lane);
      length_type <= `OR_LANE(length_type_lane);
      vlan1_length_type <= `OR_LANE(vlan1_length_type_lane);
      vlan2_length_type <= `OR_LANE(vlan2_length_type_lane);
    end
  end

  wire ptp_mac_addr_match = ((mac_da[47:0] == PTPETHPRIMAD) || (mac_da[47:0] == PTPETHPDELAD));

  //get pppoe information-ppp_id, data input delay 2 samples
  reg  [15:0]         ppp_pid;
  reg  [15:0]         ppp_pid_lane[7:0];

  generate
    for(i = 0; i < 8; i = i+1) begin : PARSE_PPPID
      reg [10:0] eth_count;
      reg [7:0]  rxd_lane;

      reg [15:0] ppp_pid_tmp;

      always @(*) begin
        rxd_lane = 8'h0;
        eth_count = 0;

        if(get_sfd_done_z1 == 1) begin
          eth_count = eth_count_base_z1 + i;
        end

        rxd_lane = rxd_z2[8*i+7: 8*i];
      end

      always @(*) begin
        ppp_pid_tmp = ppp_pid;

        if((get_sfd_done_z1 == 1) && !rxc_z2[i]) begin
          if(length_type == 16'h8864) begin      //no vlan
            if(eth_count == 11'd28) ppp_pid_tmp[15:8]  = rxd_lane;
            if(eth_count == 11'd29) ppp_pid_tmp[7:0]   = rxd_lane;
          end
          else if(length_type == 16'h8100 && vlan1_length_type == 16'h8864) begin     //single vlan
            if(eth_count == 11'd32) ppp_pid_tmp[15:8]  = rxd_lane;
            if(eth_count == 11'd33) ppp_pid_tmp[7:0]   = rxd_lane;
          end 
          else if((length_type == 16'h88a8 || length_type == 16'h9100 || length_type == 16'h9200 || length_type == 16'h9300 
            || length_type == 16'h8100) && vlan1_length_type == 16'h8100 && vlan2_length_type == 16'h8864) begin //double vlan
            if(eth_count == 11'd36) ppp_pid_tmp[15:8]  = rxd_lane;
            if(eth_count == 11'd37) ppp_pid_tmp[7:0]   = rxd_lane;     
          end 
        end 
        else if(get_efd_done_z2 == 1) begin
          ppp_pid_tmp = 16'h0;
        end
      end //always
      
      always @(*) begin
        ppp_pid_lane[i] = ppp_pid_tmp;
      end

    end //for i
  endgenerate

  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n) 
      ppp_pid <= 16'h0;
    else if(rx_clk_en_i)
      ppp_pid <= `OR_LANE(ppp_pid_lane);
  end

  //get snap related attributes, data input delay 2 samples
  reg  [7:0]      snap_dsap;
  reg  [7:0]      snap_ssap;
  reg  [15:0]     snap_length_type;
  reg  [7:0]      snap_dsap_lane[7:0];
  reg  [7:0]      snap_ssap_lane[7:0];
  reg  [15:0]     snap_length_type_lane[7:0];

  generate
    for(i = 0; i < 8; i = i+1) begin : PARSE_SNAP
      reg [10:0] eth_count;
      reg [7:0]  rxd_lane;

      reg [7:0]  snap_dsap_tmp;
      reg [7:0]  snap_ssap_tmp;
      reg [15:0] snap_length_type_tmp;

      always @(*) begin
        rxd_lane = 8'h0;
        eth_count = 0;

        if(get_sfd_done_z1 == 1) begin
          eth_count = eth_count_base_z1 + i;
        end

        rxd_lane = rxd_z2[8*i+7: 8*i];
      end

      always @(*) begin
        snap_dsap_tmp = snap_dsap;
        snap_ssap_tmp = snap_ssap;
        snap_length_type_tmp = snap_length_type;

        if((get_sfd_done_z1 == 1) && !rxc_z2[i]) begin
          if(length_type <= 1500) begin          //no vlan
            if(eth_count == 11'd22)  snap_dsap_tmp = rxd_lane;
            if(eth_count == 11'd23)  snap_ssap_tmp = rxd_lane;
            if(eth_count == 11'd28)  snap_length_type_tmp[15:8] = rxd_lane;
            if(eth_count == 11'd29)  snap_length_type_tmp[7:0]  = rxd_lane;
          end 
          else if(length_type == 16'h8100 && vlan1_length_type <= 1500) begin     //single vlan
            if(eth_count == 11'd26)  snap_dsap_tmp = rxd_lane;                        
            if(eth_count == 11'd27)  snap_ssap_tmp = rxd_lane;                        
            if(eth_count == 11'd32)  snap_length_type_tmp[15:8] = rxd_lane;           
            if(eth_count == 11'd33)  snap_length_type_tmp[7:0]  = rxd_lane;           
          end  
          else if((length_type == 16'h88a8 || length_type == 16'h9100 || length_type == 16'h9200 || length_type == 16'h9300 
            || length_type == 16'h8100) && vlan1_length_type == 16'h8100 && vlan2_length_type <= 1500) begin //double vlan  
            if(eth_count == 11'd30)  snap_dsap_tmp = rxd_lane;                        
            if(eth_count == 11'd31)  snap_ssap_tmp = rxd_lane;                        
            if(eth_count == 11'd36)  snap_length_type_tmp[15:8] = rxd_lane;           
            if(eth_count == 11'd37)  snap_length_type_tmp[7:0]  = rxd_lane;            
          end 
        end 
        else if(get_efd_done_z2 == 1) begin
          snap_dsap_tmp = 8'h0;
          snap_ssap_tmp = 8'h0;
          snap_length_type_tmp = 16'h0;
        end
      end //always
      
      always @(*) begin
        snap_dsap_lane[i] = snap_dsap_tmp;
        snap_ssap_lane[i] = snap_ssap_tmp;
        snap_length_type_lane[i] = snap_length_type_tmp;
      end
    end //for i
  endgenerate

  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n) begin
      snap_dsap        <= 8'h0;       
      snap_ssap        <= 8'h0;       
      snap_length_type <= 16'h0;
    end
    else if(rx_clk_en_i) begin 
      snap_dsap <= `OR_LANE(snap_dsap_lane);
      snap_ssap <= `OR_LANE(snap_ssap_lane);
      snap_length_type <= `OR_LANE(snap_length_type_lane);
    end
  end

  //++
  //get ptpv2 related information
  //--

  //deal with ptp message over 802.3/ethernet
  reg            ptp_eth_flag;
  reg  [10:0]    eth_ptp_addr_base;

  always @(*) begin
    //default values
    ptp_eth_flag      = 0;
    eth_ptp_addr_base = 0;
   
    //native_ethernet-2 encapsulation
    if(length_type == 16'h88f7) begin  //no vlan
      ptp_eth_flag      = 1;
      eth_ptp_addr_base = 22;
    end
    else if(length_type == 16'h8100 && vlan1_length_type == 16'h88f7) begin   //single vlan
      ptp_eth_flag      = 1;
      eth_ptp_addr_base = 26;
          
    end 
    else if((length_type == 16'h88a8 || length_type == 16'h9100 || length_type == 16'h9200 || length_type == 16'h9300 
      || length_type == 16'h8100) && vlan1_length_type == 16'h8100 && vlan2_length_type == 16'h88f7) begin //double vlan
      ptp_eth_flag      = 1;
      eth_ptp_addr_base = 30;       
    end

    //802.3 snap layer2 encapsulation
    if(length_type <= 1500 && snap_dsap == 8'haa && snap_ssap == 8'haa && snap_length_type == 16'h88f7) begin      //no vlan
      ptp_eth_flag      = 1;
      eth_ptp_addr_base = 30;
    end
    else if(length_type == 16'h8100 && vlan1_length_type <= 1500 && snap_dsap == 8'haa && snap_ssap == 8'haa 
      && snap_length_type == 16'h88f7) begin    //single vlan
      ptp_eth_flag      = 1;
      eth_ptp_addr_base = 34;   
    end 
    else if((length_type == 16'h88a8 || length_type == 16'h9100 || length_type == 16'h9200 || length_type == 16'h9300 
      || length_type == 16'h8100) && vlan1_length_type == 16'h8100 && vlan2_length_type <=1500 && snap_dsap == 8'haa 
      && snap_ssap == 8'haa && snap_length_type == 16'h88f7) begin //double vlan
      ptp_eth_flag      = 1;
      eth_ptp_addr_base = 38;   
    end        
  end

  //deal with ptp message over ipv4/udp
  reg          ipv4_flag;
  reg  [10:0]  ipv4_addr_base;
  
  always @(*) begin
    //default values
    ipv4_flag      = 0;
    ipv4_addr_base = 0;
    
    //normal situation
    if(length_type == 16'h0800) begin      //no vlan
      ipv4_flag      = 1;
      ipv4_addr_base = 22;
    end
    else if(length_type == 16'h8100 && vlan1_length_type == 16'h0800) begin   //single vlan
      ipv4_flag      = 1;
      ipv4_addr_base = 26;   
    end 
    else if((length_type == 16'h88a8 || length_type == 16'h9100 || length_type == 16'h9200 || length_type == 16'h9300 
      || length_type == 16'h8100) && vlan1_length_type == 16'h8100 && vlan2_length_type == 16'h0800) begin //double vlan
      ipv4_flag      = 1;
      ipv4_addr_base = 30;   
    end
    
    //pppoe
    if(length_type == 16'h8864 && ppp_pid == 16'h0021) begin      //no vlan
      ipv4_flag      = 1;
      ipv4_addr_base = 30;
    end
    else if(length_type == 16'h8100 && vlan1_length_type == 16'h8864 && ppp_pid == 16'h0021) begin    //single vlan
      ipv4_flag      = 1;
      ipv4_addr_base = 34;   
    end 
    else if((length_type == 16'h88a8 || length_type == 16'h9100 || length_type == 16'h9200 || length_type == 16'h9300 
     ||length_type == 16'h8100) && vlan1_length_type == 16'h8100 && vlan2_length_type == 16'h8864 && ppp_pid == 16'h0021) begin //double vlan
      ipv4_flag      = 1;
      ipv4_addr_base = 38;   
    end  
    
    //snap
    if(length_type <= 1500 && snap_dsap == 8'haa && snap_ssap == 8'haa && snap_length_type == 16'h0800) begin      //no vlan
      ipv4_flag      = 1;
      ipv4_addr_base = 30;
    end
    else if(length_type == 16'h8100 && vlan1_length_type <= 1500 && snap_dsap == 8'haa && snap_ssap == 8'haa 
      && snap_length_type == 16'h0800) begin    //single vlan
      ipv4_flag      = 1;
      ipv4_addr_base = 34;   
    end 
    else if((length_type == 16'h88a8 || length_type == 16'h9100 || length_type == 16'h9200 || length_type == 16'h9300 
      || length_type == 16'h8100) && vlan1_length_type == 16'h8100 && vlan2_length_type <=1500 && snap_dsap == 8'haa 
      && snap_ssap == 8'haa && snap_length_type == 16'h0800) begin //double vlan
      ipv4_flag      = 1;
      ipv4_addr_base = 38;   
    end        
  end

  //add 1 pipeline stage
  reg          ipv4_flag_z1;
  reg  [10:0]  ipv4_addr_base_z1;

  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n) begin
      ipv4_flag_z1      <= 0;
      ipv4_addr_base_z1 <= 11'h0;
    end
    else if(rx_clk_en_i) begin
      ipv4_flag_z1      <= ipv4_flag;
      ipv4_addr_base_z1 <= ipv4_addr_base;
    end
  end

  //parse ipv4/udp header, use data input delayed 4 cycles
  reg  [31:0]         ipv4_da;
  reg  [7:0]          ipv4_layer4_protocol;
  reg  [15:0]         ipv4_udp_port;
  
  reg  [31:0]         ipv4_da_lane[7:0];
  reg  [7:0]          ipv4_layer4_protocol_lane[7:0];
  reg  [15:0]         ipv4_udp_port_lane[7:0];

  generate
    for(i = 0; i < 8; i = i+1) begin : PARSE_IPV4_UDP
      reg [10:0]   eth_count;
      reg [7:0]    rxd_lane;

      reg [31:0]   ipv4_da_tmp;
      reg [7:0]    ipv4_layer4_protocol_tmp;
      reg [15:0]   ipv4_udp_port_tmp;

      always @(*) begin
        rxd_lane  = 8'h0;
        eth_count = 0;

        if(get_sfd_done_z3 == 1) begin
          eth_count = eth_count_base_z3 + i;
        end
        rxd_lane = rxd_z4[8*i+7: 8*i];
      end
      
      always @(*) begin
        ipv4_da_tmp = ipv4_da;
        ipv4_layer4_protocol_tmp = ipv4_layer4_protocol;
        ipv4_udp_port_tmp = ipv4_udp_port;

        if(ipv4_flag_z1 == 1'b1 && !rxc_z4[i]) begin
          if(eth_count == (ipv4_addr_base_z1+9))   ipv4_layer4_protocol_tmp = rxd_lane;
            
          if(eth_count == (ipv4_addr_base_z1+16))  ipv4_da_tmp[31:24]       = rxd_lane;
          if(eth_count == (ipv4_addr_base_z1+17))  ipv4_da_tmp[23:16]       = rxd_lane;
          if(eth_count == (ipv4_addr_base_z1+18))  ipv4_da_tmp[15:8]        = rxd_lane;
          if(eth_count == (ipv4_addr_base_z1+19))  ipv4_da_tmp[7:0]         = rxd_lane;   
          
          if(eth_count == (ipv4_addr_base_z1+22))  ipv4_udp_port_tmp[15:8]  = rxd_lane;
          if(eth_count == (ipv4_addr_base_z1+23))  ipv4_udp_port_tmp[7:0]   = rxd_lane;   
        end
        else if(get_efd_done_z4 == 1) begin
          ipv4_da_tmp              = 32'h0;
          ipv4_layer4_protocol_tmp = 8'h0;
          ipv4_udp_port_tmp        = 16'h0;   
        end
      end //always

      always @(*) begin
        ipv4_da_lane[i]               = ipv4_da_tmp;
        ipv4_layer4_protocol_lane[i]  = ipv4_layer4_protocol_tmp;
        ipv4_udp_port_lane[i]         = ipv4_udp_port_tmp;
      end
    end //for i
  endgenerate

  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n) begin
      ipv4_da              <= 32'h0;
      ipv4_layer4_protocol <= 8'h0;
      ipv4_udp_port        <= 16'h0;   
    end
    else if(rx_clk_en_i) begin
      ipv4_da              <= `OR_LANE(ipv4_da_lane);
      ipv4_layer4_protocol <= `OR_LANE(ipv4_layer4_protocol_lane);
      ipv4_udp_port        <= `OR_LANE(ipv4_udp_port_lane);   
    end
  end

  reg             ptp_ipv4_flag;
  reg  [10:0]     ipv4_ptp_addr_base;

  always @(*) begin
    ptp_ipv4_flag      = 0;
    ipv4_ptp_addr_base = 0;
    
    if(ipv4_flag == 1'b1 && ipv4_layer4_protocol == 8'd17 && (ipv4_udp_port == 16'd319 || ipv4_udp_port == 16'd320)) begin
      ptp_ipv4_flag      = 1;
      ipv4_ptp_addr_base = ipv4_addr_base + 28;
    end  
  end

  wire ptp_ipv4_addr_match = ((ipv4_da[31:0] == PTPIPV4PRIMAD) || (ipv4_da[31:0] == PTPIPV4PDELAD));

  //deal with ptp message over ipv6/udp
  reg          ipv6_flag;
  reg  [10:0]  ipv6_addr_base;
  
  always @(*) begin
    //default values
    ipv6_flag       = 0;
    ipv6_addr_base  = 0;
    
    //normal situation
    if(length_type == 16'h86dd) begin      //no vlan
      ipv6_flag      = 1;
      ipv6_addr_base = 22;
    end
    else if(length_type == 16'h8100 && vlan1_length_type == 16'h86dd) begin   //single vlan
      ipv6_flag      = 1;
      ipv6_addr_base = 26;   
    end 
    else if((length_type == 16'h88a8 || length_type == 16'h9100 || length_type == 16'h9200 || length_type == 16'h9300 
      || length_type == 16'h8100) && vlan1_length_type == 16'h8100 && vlan2_length_type == 16'h86dd) begin //double vlan
      ipv6_flag      = 1;
      ipv6_addr_base = 30;   
    end
    
    //pppoe
    if(length_type == 16'h8864 && ppp_pid == 16'h0057) begin      //no vlan
      ipv6_flag      = 1;
      ipv6_addr_base = 30;
    end
    else if(length_type == 16'h8100 && vlan1_length_type == 16'h8864 && ppp_pid == 16'h0057) begin    //single vlan
      ipv6_flag      = 1;
      ipv6_addr_base = 34;   
    end 
    else if((length_type == 16'h88a8 || length_type == 16'h9100 || length_type == 16'h9200 || length_type == 16'h9300 
     || length_type == 16'h8100) && vlan1_length_type == 16'h8100 && vlan2_length_type == 16'h8864 && ppp_pid == 16'h0057) begin //double vlan
      ipv6_flag      = 1;
      ipv6_addr_base = 38;   
    end  
    
    //snap
    if(length_type <= 1500 && snap_dsap == 8'haa && snap_ssap == 8'haa && snap_length_type == 16'h86dd) begin      //no vlan
      ipv6_flag      = 1;
      ipv6_addr_base = 30;
    end
    else if(length_type == 16'h8100 && vlan1_length_type <= 1500 && snap_dsap == 8'haa && snap_ssap == 8'haa 
      && snap_length_type == 16'h86dd) begin    //single vlan
      ipv6_flag      = 1;
      ipv6_addr_base = 34;   
    end 
    else if((length_type == 16'h88a8 || length_type == 16'h9100 || length_type == 16'h9200 || length_type == 16'h9300 
      || length_type == 16'h8100) && vlan1_length_type == 16'h8100 && vlan2_length_type <=1500 && snap_dsap == 8'haa && snap_ssap == 8'haa
       && snap_length_type == 16'h86dd) begin  //double vlan
      ipv6_flag      = 1;
      ipv6_addr_base = 38;   
    end       
  end    

  //add 1 pipeline stage
  reg          ipv6_flag_z1;
  reg  [10:0]  ipv6_addr_base_z1;

  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n) begin
      ipv6_flag_z1      <= 0;
      ipv6_addr_base_z1 <= 11'h0;
    end
    else if(rx_clk_en_i) begin
      ipv6_flag_z1      <= ipv6_flag;
      ipv6_addr_base_z1 <= ipv6_addr_base;
    end
  end

  //parse ipv6/udp header, use data input delayed 4 cycles
  reg  [127:0]    ipv6_da;  
  reg  [7:0]      ipv6_next_header;
  reg  [15:0]     ipv6_udp_port;

  reg  [127:0]    ipv6_da_lane[7:0];  
  reg  [7:0]      ipv6_next_header_lane[7:0];
  reg  [15:0]     ipv6_udp_port_lane[7:0];

  generate
    for(i = 0; i < 8; i = i+1) begin : PARSE_IPV6_UDP
      reg [10:0]   eth_count;
      reg [7:0]    rxd_lane;

      reg  [127:0] ipv6_da_tmp;  
      reg  [7:0]   ipv6_next_header_tmp;
      reg  [15:0]  ipv6_udp_port_tmp;

      always @(*) begin
        rxd_lane = 8'h0;
        eth_count = 0;

        if(get_sfd_done_z3 == 1) begin
          eth_count = eth_count_base_z3 + i;
        end
        rxd_lane = rxd_z4[8*i+7: 8*i];
      end

      always @(*) begin
        ipv6_da_tmp = ipv6_da;  
        ipv6_next_header_tmp = ipv6_next_header;
        ipv6_udp_port_tmp    = ipv6_udp_port;

        if(ipv6_flag_z1 == 1'b1 && !rxc_z4[i]) begin
          if(eth_count == (ipv6_addr_base_z1+6))   ipv6_next_header_tmp    = rxd_lane;

          if(eth_count == (ipv6_addr_base_z1+24))  ipv6_da_tmp[127:120]    = rxd_lane;                           
          if(eth_count == (ipv6_addr_base_z1+25))  ipv6_da_tmp[119:112]    = rxd_lane;                           
          if(eth_count == (ipv6_addr_base_z1+26))  ipv6_da_tmp[111:104]    = rxd_lane;                           
          if(eth_count == (ipv6_addr_base_z1+27))  ipv6_da_tmp[103:96]     = rxd_lane;                           
          if(eth_count == (ipv6_addr_base_z1+28))  ipv6_da_tmp[95:88]      = rxd_lane;                           
          if(eth_count == (ipv6_addr_base_z1+29))  ipv6_da_tmp[87:80]      = rxd_lane;                           
          if(eth_count == (ipv6_addr_base_z1+30))  ipv6_da_tmp[79:72]      = rxd_lane;                           
          if(eth_count == (ipv6_addr_base_z1+31))  ipv6_da_tmp[71:64]      = rxd_lane;          
          if(eth_count == (ipv6_addr_base_z1+32))  ipv6_da_tmp[63:56]      = rxd_lane;                           
          if(eth_count == (ipv6_addr_base_z1+33))  ipv6_da_tmp[55:48]      = rxd_lane;                           
          if(eth_count == (ipv6_addr_base_z1+34))  ipv6_da_tmp[47:40]      = rxd_lane;                           
          if(eth_count == (ipv6_addr_base_z1+35))  ipv6_da_tmp[39:32]      = rxd_lane;          
          if(eth_count == (ipv6_addr_base_z1+36))  ipv6_da_tmp[31:24]      = rxd_lane;                           
          if(eth_count == (ipv6_addr_base_z1+37))  ipv6_da_tmp[23:16]      = rxd_lane;                           
          if(eth_count == (ipv6_addr_base_z1+38))  ipv6_da_tmp[15:8]       = rxd_lane;                           
          if(eth_count == (ipv6_addr_base_z1+39))  ipv6_da_tmp[7:0]        = rxd_lane;          
                                                                                                                         
          if(eth_count == (ipv6_addr_base_z1+42))  ipv6_udp_port_tmp[15:8] = rxd_lane;                           
          if(eth_count == (ipv6_addr_base_z1+43))  ipv6_udp_port_tmp[7:0]  = rxd_lane;    
        end
        else if(get_efd_done_z4 == 1)  begin
          ipv6_da_tmp             = 128'h0;
          ipv6_next_header_tmp    = 8'h0;
          ipv6_udp_port_tmp       = 16'h0;            
        end
      end //always

      always @(*) begin
        ipv6_da_lane[i]          = ipv6_da_tmp;  
        ipv6_next_header_lane[i] = ipv6_next_header_tmp;
        ipv6_udp_port_lane[i]    = ipv6_udp_port_tmp;
      end
    end //for i
  endgenerate

  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n) begin
      ipv6_da             <= 128'h0;
      ipv6_next_header    <= 8'h0;
      ipv6_udp_port       <= 16'h0;      
    end
    else if(rx_clk_en_i) begin
      ipv6_da             <= `OR_LANE(ipv6_da_lane);
      ipv6_next_header    <= `OR_LANE(ipv6_next_header_lane);
      ipv6_udp_port       <= `OR_LANE(ipv6_udp_port_lane);      
    end
  end  

  reg            ptp_ipv6_flag; 
  reg  [10:0]    ipv6_ptp_addr_base; 

  always @(*) begin
    ptp_ipv6_flag       = 0;
    ipv6_ptp_addr_base  = 0;
    
    if(ipv6_flag == 1'b1 && ipv6_next_header == 8'd17 && (ipv6_udp_port == 16'd319 || ipv6_udp_port == 16'd320)) begin
      ptp_ipv6_flag      = 1;
      ipv6_ptp_addr_base = ipv6_addr_base + 48;
    end  
  end

  wire ptp_ipv6_addr_match = (((ipv6_da[127:116] == 12'hff0) && (ipv6_da[111:0] == 112'h0000000000000000000000000181)) ||
                                 (ipv6_da[127:0] == PTPIPV6PDELAD));

  //summarize all cases, ptp over 802.3/ethernet, ipv4/udp, ipv6/udp
  reg              is_ptp_message_p1, is_ptp_message, is_ptp_message_z1, is_ptp_message_z2;
  reg  [10:0]      ptp_addr_base_p1, ptp_addr_base;

  always @(*) begin
    is_ptp_message_p1 = is_ptp_message;
    ptp_addr_base_p1  = ptp_addr_base;   
    
    if(ptp_eth_flag == 1'b1) begin
      is_ptp_message_p1 = 1;
      ptp_addr_base_p1  = eth_ptp_addr_base;
    end
    else if(ptp_ipv4_flag == 1'b1) begin
      is_ptp_message_p1 = 1;
      ptp_addr_base_p1  = ipv4_ptp_addr_base; 
    end
    else if(ptp_ipv6_flag == 1'b1) begin
      is_ptp_message_p1 = 1;
      ptp_addr_base_p1  = ipv6_ptp_addr_base;
    end  

    if(get_efd_done_z6 == 0 && get_efd_done_z5 == 1) begin
      is_ptp_message_p1 = 0 ;
      ptp_addr_base_p1  = 11'h80  ; 
    end
  end
  
 //add 1 stage pipeline registers
  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n) begin
      is_ptp_message  <= 0 ;
      ptp_addr_base   <= 11'h80  ; //initial to a large value to avert error
    end
    else if(rx_clk_en_i) begin
      is_ptp_message  <= is_ptp_message_p1 ;
      ptp_addr_base   <= ptp_addr_base_p1  ;
    end
  end

  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n) 
      {is_ptp_message_z1, is_ptp_message_z2} <= 2'b0;
    else if(rx_clk_en_i) 
      {is_ptp_message_z1, is_ptp_message_z2} <= {is_ptp_message, is_ptp_message_z1};
  end

  //deal with ptp messages, according to ieee1588-2019
  reg  [3:0]      ptp_majorSdoId;
  reg  [3:0]      ptp_messageType;
  reg  [3:0]      ptp_minorVersionPTP;
  reg  [3:0]      ptp_versionPTP;
  reg  [15:0]     ptp_messageLength;
  reg  [7:0]      ptp_domainNumber;
  reg  [7:0]      ptp_minorSdoId;
  reg  [15:0]     ptp_flagField;
  reg  [63:0]     ptp_correctionField;
  reg  [31:0]     ptp_messageTypeSpecific;
  reg  [79:0]     ptp_sourcePortIdentity; 
  reg  [15:0]     ptp_seqId;

  reg  [3:0]      ptp_majorSdoId_lane[7:0];
  reg  [3:0]      ptp_messageType_lane[7:0];
  reg  [3:0]      ptp_minorVersionPTP_lane[7:0];
  reg  [3:0]      ptp_versionPTP_lane[7:0];
  reg  [15:0]     ptp_messageLength_lane[7:0];
  reg  [7:0]      ptp_domainNumber_lane[7:0];
  reg  [7:0]      ptp_minorSdoId_lane[7:0];
  reg  [15:0]     ptp_flagField_lane[7:0];
  reg  [63:0]     ptp_correctionField_lane[7:0];
  reg  [31:0]     ptp_messageTypeSpecific_lane[7:0];
  reg  [79:0]     ptp_sourcePortIdentity_lane[7:0]; 
  reg  [15:0]     ptp_seqId_lane[7:0];

  //use data input delayed 6 cycles
  generate
    for(i = 0; i < 8; i = i+1) begin : PARSE_PTP_MESSAGE
      reg [10:0]   eth_count;
      reg [7:0]    rxd_lane;

      reg [3:0]    ptp_majorSdoId_tmp;
      reg [3:0]    ptp_messageType_tmp;
      reg [3:0]    ptp_minorVersionPTP_tmp;
      reg [3:0]    ptp_versionPTP_tmp;
      reg [15:0]   ptp_messageLength_tmp;
      reg [7:0]    ptp_domainNumber_tmp;
      reg [7:0]    ptp_minorSdoId_tmp;
      reg [15:0]   ptp_flagField_tmp;
      reg [63:0]   ptp_correctionField_tmp;
      reg [31:0]   ptp_messageTypeSpecific_tmp;
      reg [79:0]   ptp_sourcePortIdentity_tmp; 
      reg [15:0]   ptp_seqId_tmp;

      always @(*) begin
        rxd_lane = 8'h0;
        eth_count = 0;

        if(get_sfd_done_z5 == 1) begin
          eth_count = eth_count_base_z5 + i;
        end
        rxd_lane = rxd_z6[8*i+7: 8*i];
      end

      always @(*) begin
        ptp_majorSdoId_tmp          = ptp_majorSdoId         ;
        ptp_messageType_tmp         = ptp_messageType        ;
        ptp_minorVersionPTP_tmp     = ptp_minorVersionPTP    ;
        ptp_versionPTP_tmp          = ptp_versionPTP         ;
        ptp_messageLength_tmp       = ptp_messageLength      ;
        ptp_domainNumber_tmp        = ptp_domainNumber       ;
        ptp_minorSdoId_tmp          = ptp_minorSdoId         ;
        ptp_flagField_tmp           = ptp_flagField          ;
        ptp_correctionField_tmp     = ptp_correctionField    ;
        ptp_messageTypeSpecific_tmp = ptp_messageTypeSpecific;
        ptp_sourcePortIdentity_tmp  = ptp_sourcePortIdentity ; 
        ptp_seqId_tmp               = ptp_seqId              ;

        if(is_ptp_message == 1'b1 && !rxc_z6[i]) begin
          if(eth_count == ptp_addr_base)       {ptp_majorSdoId_tmp, ptp_messageType_tmp}     = rxd_lane;
          if(eth_count == (ptp_addr_base+1))   {ptp_minorVersionPTP_tmp, ptp_versionPTP_tmp} = rxd_lane;
            
          if(eth_count == (ptp_addr_base+2))   ptp_messageLength_tmp[15:8]  = rxd_lane;
          if(eth_count == (ptp_addr_base+3))   ptp_messageLength_tmp[7:0]   = rxd_lane;
          if(eth_count == (ptp_addr_base+4))   ptp_domainNumber_tmp = rxd_lane;
          if(eth_count == (ptp_addr_base+5))   ptp_minorSdoId_tmp   = rxd_lane;
  
          if(eth_count == (ptp_addr_base+6))   ptp_flagField_tmp[15:8] = rxd_lane;
          if(eth_count == (ptp_addr_base+7))   ptp_flagField_tmp[7:0]  = rxd_lane;

          if(eth_count == (ptp_addr_base+8))   ptp_correctionField_tmp[63:56] = rxd_lane;
          if(eth_count == (ptp_addr_base+9))   ptp_correctionField_tmp[55:48] = rxd_lane;
          if(eth_count == (ptp_addr_base+10))  ptp_correctionField_tmp[47:40] = rxd_lane;
          if(eth_count == (ptp_addr_base+11))  ptp_correctionField_tmp[39:32] = rxd_lane;
          if(eth_count == (ptp_addr_base+12))  ptp_correctionField_tmp[31:24] = rxd_lane;
          if(eth_count == (ptp_addr_base+13))  ptp_correctionField_tmp[23:16] = rxd_lane;
          if(eth_count == (ptp_addr_base+14))  ptp_correctionField_tmp[15:8]  = rxd_lane;
          if(eth_count == (ptp_addr_base+15))  ptp_correctionField_tmp[7:0]   = rxd_lane;

          if(eth_count == (ptp_addr_base+16))  ptp_messageTypeSpecific_tmp[31:24] = rxd_lane;
          if(eth_count == (ptp_addr_base+17))  ptp_messageTypeSpecific_tmp[23:16] = rxd_lane;
          if(eth_count == (ptp_addr_base+18))  ptp_messageTypeSpecific_tmp[15:8]  = rxd_lane;
          if(eth_count == (ptp_addr_base+19))  ptp_messageTypeSpecific_tmp[7:0]   = rxd_lane;
       
          if(eth_count == (ptp_addr_base+20))  ptp_sourcePortIdentity_tmp[79:72] = rxd_lane;
          if(eth_count == (ptp_addr_base+21))  ptp_sourcePortIdentity_tmp[71:64] = rxd_lane;
          if(eth_count == (ptp_addr_base+22))  ptp_sourcePortIdentity_tmp[63:56] = rxd_lane;
          if(eth_count == (ptp_addr_base+23))  ptp_sourcePortIdentity_tmp[55:48] = rxd_lane;          
          if(eth_count == (ptp_addr_base+24))  ptp_sourcePortIdentity_tmp[47:40] = rxd_lane;
          if(eth_count == (ptp_addr_base+25))  ptp_sourcePortIdentity_tmp[39:32] = rxd_lane;
          if(eth_count == (ptp_addr_base+26))  ptp_sourcePortIdentity_tmp[31:24] = rxd_lane;
          if(eth_count == (ptp_addr_base+27))  ptp_sourcePortIdentity_tmp[23:16] = rxd_lane;      
          if(eth_count == (ptp_addr_base+28))  ptp_sourcePortIdentity_tmp[15:8]  = rxd_lane;
          if(eth_count == (ptp_addr_base+29))  ptp_sourcePortIdentity_tmp[7:0]   = rxd_lane;   
            
          if(eth_count == (ptp_addr_base+30))  ptp_seqId_tmp[15:8] = rxd_lane;
          if(eth_count == (ptp_addr_base+31))  ptp_seqId_tmp[7:0]  = rxd_lane; 
        end
        else if(get_efd_done_z6 == 1)  begin
          ptp_majorSdoId_tmp          = 0;
          ptp_messageType_tmp         = 0;
          ptp_minorVersionPTP_tmp     = 0;
          ptp_versionPTP_tmp          = 0;
          ptp_messageLength_tmp       = 0;
          ptp_domainNumber_tmp        = 0;
          ptp_minorSdoId_tmp          = 0;
          ptp_flagField_tmp           = 0;
          ptp_correctionField_tmp     = 0;
          ptp_messageTypeSpecific_tmp = 0;
          ptp_sourcePortIdentity_tmp  = 0; 
          ptp_seqId_tmp               = 0;
        end
      end //always

      always @(*) begin
        ptp_majorSdoId_lane[i]          = ptp_majorSdoId_tmp         ;
        ptp_messageType_lane[i]         = ptp_messageType_tmp        ;
        ptp_minorVersionPTP_lane[i]     = ptp_minorVersionPTP_tmp    ;
        ptp_versionPTP_lane[i]          = ptp_versionPTP_tmp         ;
        ptp_messageLength_lane[i]       = ptp_messageLength_tmp      ;
        ptp_domainNumber_lane[i]        = ptp_domainNumber_tmp       ;
        ptp_minorSdoId_lane[i]          = ptp_minorSdoId_tmp         ;
        ptp_flagField_lane[i]           = ptp_flagField_tmp          ;
        ptp_correctionField_lane[i]     = ptp_correctionField_tmp    ;
        ptp_messageTypeSpecific_lane[i] = ptp_messageTypeSpecific_tmp;
        ptp_sourcePortIdentity_lane[i]  = ptp_sourcePortIdentity_tmp ; 
        ptp_seqId_lane[i]               = ptp_seqId_tmp              ;
      end
    end //for i
  endgenerate

  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n) begin
      ptp_majorSdoId          <= 0;
      ptp_messageType         <= 0;
      ptp_minorVersionPTP     <= 0;
      ptp_versionPTP          <= 0;
      ptp_messageLength       <= 0;
      ptp_domainNumber        <= 0;
      ptp_minorSdoId          <= 0;
      ptp_flagField           <= 0;
      ptp_correctionField     <= 0;
      ptp_messageTypeSpecific <= 0;
      ptp_sourcePortIdentity  <= 0;
      ptp_seqId               <= 0;
    end
    else if(rx_clk_en_i) begin 
      ptp_majorSdoId          <= `OR_LANE(ptp_majorSdoId_lane         );
      ptp_messageType         <= `OR_LANE(ptp_messageType_lane        );
      ptp_minorVersionPTP     <= `OR_LANE(ptp_minorVersionPTP_lane    );
      ptp_versionPTP          <= `OR_LANE(ptp_versionPTP_lane         );
      ptp_messageLength       <= `OR_LANE(ptp_messageLength_lane      );
      ptp_domainNumber        <= `OR_LANE(ptp_domainNumber_lane       );
      ptp_minorSdoId          <= `OR_LANE(ptp_minorSdoId_lane         );
      ptp_flagField           <= `OR_LANE(ptp_flagField_lane          );
      ptp_correctionField     <= `OR_LANE(ptp_correctionField_lane    );
      ptp_messageTypeSpecific <= `OR_LANE(ptp_messageTypeSpecific_lane);
      ptp_sourcePortIdentity  <= `OR_LANE(ptp_sourcePortIdentity_lane );
      ptp_seqId               <= `OR_LANE(ptp_seqId_lane              );
    end
  end

  //check ptp version or address matched or not
  reg   ptp_version_match;
  wire  ptp_ver_chk_en   = tsu_cfg_i[21];
  wire [3:0] ptp_version_cfg = tsu_cfg_i[20:17]; 

  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n)
      ptp_version_match <= 0;
    else if(rx_clk_en_i) begin
      if(ptp_ver_chk_en == 1'b0)
        ptp_version_match <= 1;
      else if(get_sfd_done_z6 == 0 && get_sfd_done_z5 == 1)   //start of next frame.
        ptp_version_match <= 0;
      else if((ptp_versionPTP[3:0] == ptp_version_cfg[3:0]) && (eth_count_base_z5 > (ptp_addr_base+2)))
        ptp_version_match <= 1;
    end
  end

  reg   ptp_address_match;  
  wire  ptp_addr_chk_en = tsu_cfg_i[22];

  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n)
      ptp_address_match <= 0;
    else if(rx_clk_en_i) begin
      if(ptp_addr_chk_en == 1'b0)
        ptp_address_match <= 1;
      else if(get_sfd_done_z6 == 0 && get_sfd_done_z5 == 1)   //start of next frame.
        ptp_address_match <= 0;
      else if((ptp_eth_flag & ptp_mac_addr_match) || (ptp_ipv4_flag & ptp_ipv4_addr_match) || (ptp_ipv6_flag & ptp_ipv6_addr_match))
        ptp_address_match <= 1;
    end
  end

  //generate ptpv2 identification outputs 
  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n) begin
      rxts_valid_o <= 0;
  
      rx_sourcePortIdentity_o <= 0;  
      rx_flagField_o          <= 0;
      rx_seqId_o              <= 0;                 
      rx_versionPTP_o         <= 0;
      rx_minorVersionPTP_o    <= 0;
      rx_messageType_o        <= 4'hf;  
      rx_majorSdoId_o         <= 0;
    end
    else if(rx_clk_en_i) begin
      if(ptp_messageType[3] == 1'b0 && ptp_version_match == 1'b1 && ptp_address_match == 1'b1) begin //event message
        if(is_ptp_message == 1'b1 && eth_count_base_z5 >= (ptp_addr_base+32))  
          rxts_valid_o <= 1;
        else if(get_efd_done_z6 == 1)
          rxts_valid_o <= 0;

        rx_sourcePortIdentity_o <= ptp_sourcePortIdentity;  
        rx_flagField_o          <= ptp_flagField         ;
        rx_seqId_o              <= ptp_seqId             ;                 
        rx_versionPTP_o         <= ptp_versionPTP        ;
        rx_minorVersionPTP_o    <= ptp_minorVersionPTP   ;
        rx_messageType_o        <= ptp_messageType       ;  
        rx_majorSdoId_o         <= ptp_majorSdoId        ;
      end
      else begin
        rxts_valid_o <= 0;
 
        if(get_sfd_done_z6 == 0 && get_sfd_done_z5 == 1) begin
          rx_sourcePortIdentity_o <= 0;  
          rx_flagField_o          <= 0;
          rx_seqId_o              <= 0;                 
          rx_versionPTP_o         <= 0;
          rx_minorVersionPTP_o    <= 0;
          rx_messageType_o        <= 4'hf;  
          rx_majorSdoId_o         <= 0;
        end     
      end
    end
  end
  
  //generate rx interrupt signal
  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n)
      int_rx_ptp_o <= 0;
    else if(rx_clk_en_i) begin
      if(is_ptp_message == 1'b1 && eth_count_base_z5 >= (ptp_addr_base+32) && ptp_version_match == 1'b1 && ptp_address_match == 1'b1)  
        int_rx_ptp_o <= 1;
      else if(get_sfd_done_z6 == 0 && get_sfd_done_z5 == 1)
        int_rx_ptp_o <= 0;
    end  
  end
  
  //signals to rx_emb_ts
  assign rxd_emb_o = rxd_z6;
  assign rxc_emb_o = rxc_z6;

  assign eth_count_base_o      = eth_count_base_z5;      
  assign ptp_addr_base_o       = ptp_addr_base;
  assign ptp_messageType_o     = ptp_messageType;           
  assign ptp_correctionField_o = ptp_correctionField;
  assign is_ptp_message_o      = is_ptp_message;  
  assign get_sfd_done_o        = get_sfd_done_z6;

  //signals to rx_rcst
  assign rxd_crc_p3_o = rxd_z6;
  assign rxc_crc_p3_o = rxc_z6;

endmodule
