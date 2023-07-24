/*++
//  embed ingress timestamp (ns part) in messageTypeSpecific field
//  of received ptpv2 event messages 
--*/
`include "ptpv2_defines.v"

module rx_emb_ts(
  //xgmii interface
  input               rx_clk,
  input               rx_rst_n,
  input               rx_clk_en_i,            //for adapting to gmii/mii

  input  [63:0]       rxd_i,
  input  [7:0]        rxc_i,
  output reg [63:0]   rxd_o,
  output reg [7:0]    rxc_o,

  //timestamp input
  input  [79:0]       sfd_timestamp_i,       //48 bits seconds + 32 bits nanoseconds

  //configuration register i/f
  input  [31:0]       tsu_cfg_i,
  input  [31:0]       link_delay_i,
  input  [31:0]       ingress_asymmetry_i,

  //ptpv2 message related information
  input  [10:0]       eth_count_base_i,      //aligned with rxd_i now
  input  [10:0]       ptp_addr_base_i,
  input  [3:0]        ptp_messageType_i,          
  input  [63:0]       ptp_correctionField_i,
  input               is_ptp_message_i,  

  input               get_sfd_done_i,
  output reg          get_sfd_done_o,

  output reg [10:0]   eth_count_base_o
);
  genvar i;

  //correctionField calculation
  reg  [31:0] asym_plus_delay;

  always @(posedge rx_clk  or negedge rx_rst_n) begin
    if(!rx_rst_n)
      asym_plus_delay <= 32'h0;
    else if(rx_clk_en_i)
      asym_plus_delay <= link_delay_i + ingress_asymmetry_i;
  end

  //note: p2p tc offload take effect to sync message only
  //e2e tc offload happen to all event messages
  wire one_step    = tsu_cfg_i[0];
  wire peer_delay  = tsu_cfg_i[2];
  wire tc_offload  = tsu_cfg_i[3];
  wire ing_asym_en = tsu_cfg_i[7];
  wire p2p_tc_offload = peer_delay & tc_offload;
  
  reg  [63:0] correctionField;

  always @(*) begin
    if(p2p_tc_offload == 1'b1 && ing_asym_en == 1'b1 && ptp_messageType_i[3:0] == 4'h0) //p2p sync message
      correctionField = ptp_correctionField_i + {{16{asym_plus_delay[31]}}, asym_plus_delay[31:0], 16'b0};
    else if(p2p_tc_offload == 1'b1 && ptp_messageType_i[3:0] == 4'h0) //p2p sync message, no asymmetry correction
      correctionField = ptp_correctionField_i + {16'h0, link_delay_i[31:0], 16'b0};
    else if(tc_offload == 1'b1 && ing_asym_en == 1'b1 && ptp_messageType_i[3:0] == 4'h0) //e2e sync message, asymmetry correction
      correctionField = ptp_correctionField_i + {{16{ingress_asymmetry_i[31]}}, ingress_asymmetry_i[31:0], 16'b0};
    else if(ing_asym_en == 1'b1 && ptp_messageType_i[3:0] == 4'h3)    //pdelay_resp message
      correctionField = ptp_correctionField_i + {{16{ingress_asymmetry_i[31]}}, ingress_asymmetry_i[31:0], 16'b0};
    else   //no aysmmetry correction and link_delay add
      correctionField = ptp_correctionField_i;
  end

  
  //input delay
  reg  [63:0]    rxd_z1, rxd_z2;
  reg  [7:0]     rxc_z1, rxc_z2;
  reg            get_sfd_done_z1, get_sfd_done_z2;
  reg  [10:0]    eth_count_base_z1, eth_count_base_z2;
  
  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n) begin
       {rxd_z1, rxd_z2} <= {2{64'h0}};
       {rxc_z1, rxc_z2} <= {2{8'h0}};
       {eth_count_base_z1, eth_count_base_z2} <= {2{11'b0}};
       {get_sfd_done_z1, get_sfd_done_z2} = 2'b0;
    end
    else if(rx_clk_en_i) begin
       {rxd_z1, rxd_z2} <= {rxd_i, rxd_z1}; 
       {rxc_z1, rxc_z2} <= {rxc_i, rxc_z1}; 
       {eth_count_base_z1, eth_count_base_z2} <= {eth_count_base_i, eth_count_base_z1};
       {get_sfd_done_z1, get_sfd_done_z2} = {get_sfd_done_i, get_sfd_done_z1};
    end
  end

  //embed ns of ingress timestamp in messageTypeSpecific field 
  wire emb_ingressTime_en = tsu_cfg_i[5];
  wire embed_enable = (emb_ingressTime_en == 1'b1 && is_ptp_message_i == 1'b1 && ptp_messageType_i[3] == 1'b0) ? 1 : 0;

  reg  [7:0]      rxc_tmp;
  reg  [63:0]     rxd_tmp;
  generate
    for(i = 0; i < 8; i = i+1) begin : RX_EMB_TS 
      reg [10:0]   eth_count;
      reg [7:0]    rxd_lane;

      always @(*) begin
        eth_count = eth_count_base_z2 + i;
      end

      always @(*) begin
        rxd_lane = rxd_z2[8*i+7:8*i];

        if(embed_enable == 1'b1 && !rxc_z2[i]) begin
          if(eth_count == (ptp_addr_base_i+8))  rxd_lane = correctionField[63:56];
          if(eth_count == (ptp_addr_base_i+9))  rxd_lane = correctionField[55:48];
          if(eth_count == (ptp_addr_base_i+10)) rxd_lane = correctionField[47:40];
          if(eth_count == (ptp_addr_base_i+11)) rxd_lane = correctionField[39:32];
          if(eth_count == (ptp_addr_base_i+12)) rxd_lane = correctionField[31:24];
          if(eth_count == (ptp_addr_base_i+13)) rxd_lane = correctionField[23:16];
          if(eth_count == (ptp_addr_base_i+14)) rxd_lane = correctionField[15:8];  
          if(eth_count == (ptp_addr_base_i+15)) rxd_lane = correctionField[7:0];   

          if(eth_count == (ptp_addr_base_i+16)) rxd_lane = sfd_timestamp_i[31:24];   //messageTypeSpecific, 4 octets
          if(eth_count == (ptp_addr_base_i+17)) rxd_lane = sfd_timestamp_i[23:16];
          if(eth_count == (ptp_addr_base_i+18)) rxd_lane = sfd_timestamp_i[15:8];
          if(eth_count == (ptp_addr_base_i+19)) rxd_lane = sfd_timestamp_i[7:0];
        end

        rxc_tmp[i]         = rxc_z2[i];
        rxd_tmp[8*i+7:8*i] = rxd_lane;
      end  //always
    end //for i
  endgenerate

  always @(posedge rx_clk  or negedge rx_rst_n) begin
    if(!rx_rst_n) begin
      rxc_o            <= 8'h0;
      rxd_o            <= 64'h0  ;
      eth_count_base_o <= 11'b0;
      get_sfd_done_o   <= 1'b0;
    end
    else if(rx_clk_en_i) begin
      rxc_o            <= rxc_tmp;
      rxd_o            <= rxd_tmp;
      eth_count_base_o <= eth_count_base_z2;
      get_sfd_done_o   <= get_sfd_done_z2;
    end
  end

endmodule
