/*++
//  tx frame reconstruction including one-step clock processing for ptpv2, etc.
--*/

`include "ptpv2_defines.v"

module tx_rcst (
  input               tx_clk,
  input               tx_rst_n,
  input               tx_clk_en_i,            //for adapting to gmii/mii

  input  [63:0]       txd_i,
  input  [7:0]        txc_i,

  output [63:0]       txd_o,
  output [7:0]        txc_o,

  //configuration register i/f
  input  [31:0]       tsu_cfg_i,

  //timestamp input
  input  [79:0]       sfd_timestamp_i,         //48 bits seconds + 32 bits nanoseconds
  input  [15:0]       sfd_timestamp_frac_ns_i, //16 bit fractional nanoseconds 

  input  [63:0]       correctionField_i,       //ns * 2^16                               
  input  [31:0]       ingress_time_i,          //32 bits ns  
  
  input  [10:0]       ptp_addr_base_i,
  input               is_ptp_message_i,  
  input  [15:0]       ptp_messageLength_i, 
  input  [3:0]        ptp_messageType_i,
  input  [15:0]       ptp_flagField_i,  
  
  input               ipv6_flag_i,
  input  [10:0]       ipv6_addr_base_i,
  input               ipv4_flag_i,  
  input  [10:0]       ipv4_addr_base_i,

  input  [10:0]       eth_count_base_i,
  input               get_sfd_done_i
);
  genvar i;

  //register settings
  wire one_step    = tsu_cfg_i[0];
  wire is_tc       = tsu_cfg_i[1];  
  wire peer_delay  = tsu_cfg_i[2];
  wire tc_offload  = tsu_cfg_i[3];
  wire emb_ingressTime_en = tsu_cfg_i[5];
  wire eg_asym_en  = tsu_cfg_i[6];
  wire ipv6_udp_chk_en = tsu_cfg_i[16];
  wire one_step_from_pkt = tsu_cfg_i[24];


  //++
  //calculate correctionField
  //--
  reg  signed [63:0] correctionField;

  //do not take fractional ns into account
  wire signed [31:0] ingress_time, egress_time;
  wire signed [31:0] diff_time_p1;
  reg  signed [31:0] diff_time;

  assign ingress_time = $signed(ingress_time_i);
  assign egress_time  = $signed(sfd_timestamp_i[31:0]);
  assign diff_time_p1 = (egress_time > ingress_time) ? (egress_time - ingress_time) : (egress_time + $signed(`SC2NS) - ingress_time);

  //add 1 stage pipeline
  always @ (posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n) 
      diff_time <= 32'b0;
    else if(tx_clk_en_i)
      diff_time <= diff_time_p1;
  end

  always @ (posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n) begin
      correctionField <= 0; 
    end
    else if(tx_clk_en_i) begin
      if(is_tc == 1'b0 && ptp_messageType_i[3:0] == 4'h0)    //ordinary or boundary clock, sync message
        correctionField <= $signed(correctionField_i) + $signed({48'h0, sfd_timestamp_frac_ns_i[15:0]});
      else if(emb_ingressTime_en)                  
        correctionField <= $signed(correctionField_i) + $signed({{16{diff_time[31]}}, diff_time[31:0], 16'b0});
      else
        correctionField <= correctionField_i;
    end 
  end

  //++
  //modify ptp frame for one-step clock processing
  //--
  wire  step_flag_msg = ((ptp_messageType_i[3:0] == 4'h0) || (ptp_messageType_i[3:0] == 4'h3)) ? 1 : 0; //sync or pdelay_resp
  wire  one_step_flag = (one_step_from_pkt & (~ptp_flagField_i[9]) & step_flag_msg) | one_step;

  //insert tx timestamp and modify correctionField
  //use data input delayed 6(parse)+4 cycles, from tx_emb_ts 
  reg  [63:0] txd_tmp1;
  reg  [7:0]  txc_tmp1;

  generate
    for(i = 0; i < 8; i = i+1) begin : INSERT_TS_CF 
      reg [10:0]   eth_count;
      reg [7:0]    txd_lane;

      always @(*) begin
        eth_count = eth_count_base_i + i;
      end

      always @(*) begin
        txd_lane = txd_i[8*i+7:8*i];

        //deal with sync message timestamp, 
        if(ptp_messageType_i[3:0] == 4'h0 && one_step_flag == 1'b1 && is_ptp_message_i == 1'b1 && !txc_i[i]) begin  
          //origin_timestamp
          if(is_tc == 1'b0)  begin  //ordinary or boundary clock
            if(eth_count == (ptp_addr_base_i+34))  txd_lane = sfd_timestamp_i[79:72];    
            if(eth_count == (ptp_addr_base_i+35))  txd_lane = sfd_timestamp_i[71:64];          
            if(eth_count == (ptp_addr_base_i+36))  txd_lane = sfd_timestamp_i[63:56];    
            if(eth_count == (ptp_addr_base_i+37))  txd_lane = sfd_timestamp_i[55:48];    
            if(eth_count == (ptp_addr_base_i+38))  txd_lane = sfd_timestamp_i[47:40];    
            if(eth_count == (ptp_addr_base_i+39))  txd_lane = sfd_timestamp_i[39:32];    
            if(eth_count == (ptp_addr_base_i+40))  txd_lane = sfd_timestamp_i[31:24];    
            if(eth_count == (ptp_addr_base_i+41))  txd_lane = sfd_timestamp_i[23:16];    
            if(eth_count == (ptp_addr_base_i+42))  txd_lane = sfd_timestamp_i[15:8];     
            if(eth_count == (ptp_addr_base_i+43))  txd_lane = sfd_timestamp_i[7:0];  
          end  
        end

        //deal with correctionField 
        if((ptp_messageType_i[3:0] == 4'h0 || (ptp_messageType_i[3:0] == 4'h1 && is_tc == 1'b1) || 
           (ptp_messageType_i[3:0] == 4'h2 && is_tc == 1'b1) || ptp_messageType_i[3:0] == 4'h3) 
            && one_step_flag == 1'b1 && is_ptp_message_i == 1'b1 && !txc_i[i]) begin  
          //correction_field
          if(eth_count == (ptp_addr_base_i+8))   txd_lane = correctionField[63:56];
          if(eth_count == (ptp_addr_base_i+9))   txd_lane = correctionField[55:48];
          if(eth_count == (ptp_addr_base_i+10))  txd_lane = correctionField[47:40];
          if(eth_count == (ptp_addr_base_i+11))  txd_lane = correctionField[39:32];
          if(eth_count == (ptp_addr_base_i+12))  txd_lane = correctionField[31:24];
          if(eth_count == (ptp_addr_base_i+13))  txd_lane = correctionField[23:16];
          if(eth_count == (ptp_addr_base_i+14))  txd_lane = correctionField[15:8];
          if(eth_count == (ptp_addr_base_i+15))  txd_lane = correctionField[7:0];
        end

        txd_tmp1[8*i+7:8*i] = txd_lane;
        txc_tmp1[i]         = txc_i[i];
      end  //always
    end //for i
  endgenerate

  reg  [63:0] txd_m1, txd_m2, txd_m3, txd_m4;
  reg  [7:0]  txc_m1, txc_m2, txc_m3, txc_m4;

  always @(posedge tx_clk or negedge tx_rst_n) begin  
    if(!tx_rst_n) begin
      {txd_m1, txd_m2, txd_m3} <= {3{64'h0}};
      {txc_m1, txc_m2, txc_m3} <= {3{8'h0}};
    end
    else if(tx_clk_en_i) begin  
      {txd_m1, txd_m2, txd_m3} <= {txd_tmp1, txd_m1, txd_m2};
      {txc_m1, txc_m2, txc_m3} <= {txc_tmp1, txc_m1, txc_m2};
    end
  end

  //++
  //calculate udp padding octets for one-step ptp event messages encapsulated in ipv6/udp  
  //--
  wire ptp_pkt_chg = (ptp_messageType_i[3:0] == 4'h0 || (ptp_messageType_i[3:0] == 4'h1 && is_tc) || 
       (ptp_messageType_i[3:0] == 4'h2 && is_tc) || ptp_messageType_i[3:0] == 4'h3) && one_step_flag  && is_ptp_message_i;

  reg  [10:0] eth_count_base_z1, eth_count_base_z2, eth_count_base_z3;  
  wire        ipv6_padchg_flag;
  wire [10:0] chkpad_addr_base ;
  wire [15:0] chksum_pad       ;

  //eth_count_base delay line
  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n) begin
       {eth_count_base_z1, eth_count_base_z2, eth_count_base_z3} <= {3{11'h0}};
    end
    else if(tx_clk_en_i) begin
       {eth_count_base_z1, eth_count_base_z2, eth_count_base_z3} <= {eth_count_base_i, eth_count_base_z1, eth_count_base_z2};
    end
  end

  //we need two samples latency to calculate ipv6 udp checksum
  ipv6_udp_chksum ipv6_udp_chksum (
    .tx_clk              (tx_clk),
    .tx_rst_n            (tx_rst_n),              
    .tx_clk_en_i         (tx_clk_en_i),      

    .ipv6_udp_chk_en_i   (ipv6_udp_chk_en & one_step_flag),      
    .eth_count_base_i    (eth_count_base_z1),
    .ipv6_flag_i         (ipv6_flag_i),
    .ipv6_addr_base_i    (ipv6_addr_base_i),
    .ptp_addr_base_i     (ptp_addr_base_i),
    .is_ptp_message_i    (is_ptp_message_i),

    .txd_i               (txd_m1),
    .txc_i               (txc_m1),

    .ptp_messageLength_i (ptp_messageLength_i),
    .ptp_messageType_i   (ptp_messageType_i),

    .ipv6_padchg_flag_o  (ipv6_padchg_flag), 
    .chkpad_addr_base_o  (chkpad_addr_base),
    .chksum_pad_o        (chksum_pad)
  );

  //change udp checksum (ptp over udp/ipv6 or udp/ipv4)
  reg  [63:0] txd_tmp3;
  reg  [7:0]  txc_tmp3;

  generate
    for(i = 0; i < 8; i = i+1) begin : CHG_UDP_CHKSUM 
      reg [10:0]   eth_count;
      reg [7:0]    txd_lane;

      always @(*) begin
        eth_count = eth_count_base_z3 + i;
      end

      always @(*) begin
        txd_lane = txd_m3[8*i+7:8*i];

        if(ipv6_padchg_flag == 1'b1 && ptp_pkt_chg == 1'b1) begin  //calculate udp checksum need 2 samples
          if(eth_count == chkpad_addr_base)   txd_lane = chksum_pad[15:8];
          if(eth_count == chkpad_addr_base+1) txd_lane = chksum_pad[7:0] ;
        end
        
        //force ipv4 udp checksum to 0 for changed ptp event message
        if(ipv4_flag_i == 1'b1 && ptp_pkt_chg == 1'b1) begin        
          if(eth_count == (ipv4_addr_base_i+26)) txd_lane = 0;        
          if(eth_count == (ipv4_addr_base_i+27)) txd_lane = 0;        
        end 

        txd_tmp3[8*i+7:8*i] = txd_lane;
        txc_tmp3[i]         = txc_m3[i];
      end  //always
    end //for i
  endgenerate

  always @(posedge tx_clk or negedge tx_rst_n) begin  
    if(!tx_rst_n) begin
      txd_m4 <= 64'h0;
      txc_m4 <= 8'h0;
    end
    else if(tx_clk_en_i) begin  
      txd_m4 <= txd_tmp3;
      txc_m4 <= txc_tmp3;
    end
  end

  //re-calculate fcs. if frame modified, replace old crc.
  //indicator used to replace crc
  reg   get_sfd_done_z1;

  always @ (posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n) 
      get_sfd_done_z1 <= 0;
    else if(tx_clk_en_i) 
      get_sfd_done_z1 <= get_sfd_done_i;
  end

  reg rpl_crc, rpl_crc_m1, rpl_crc_m2, rpl_crc_m3, rpl_crc_m4;
  always @(*) begin
    rpl_crc = rpl_crc_m1;

    if(get_sfd_done_i == 1 && get_sfd_done_z1 == 0) //start of frame detected
      rpl_crc = 0;
    else if(ptp_pkt_chg == 1'b1)   
      rpl_crc = 1;
  end

  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n)
      {rpl_crc_m1, rpl_crc_m2, rpl_crc_m3, rpl_crc_m4} <= 4'b0;
    else if(tx_clk_en_i)
      {rpl_crc_m1, rpl_crc_m2, rpl_crc_m3, rpl_crc_m4} <= {rpl_crc, rpl_crc_m1, rpl_crc_m2, rpl_crc_m3}; 
  end

  xge_crc tx_xge_crc(
    .clk              (tx_clk),
    .rst_n            (tx_rst_n),              
    .clk_en_i         (tx_clk_en_i),
    
    .rpl_flag_i       (rpl_crc_m4),

    .xd_p3_i          (txd_m1),
    .xc_p3_i          (txc_m1),

    .xd_i             (txd_m4),
    .xc_i             (txc_m4),

    .xd_o             (txd_o),
    .xc_o             (txc_o)
  );

endmodule

