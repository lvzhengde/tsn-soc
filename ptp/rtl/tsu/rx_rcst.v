/*++
//  rx frame reconstruct, including crc recalculation
--*/
`include "ptpv2_defines.v"

module rx_rcst(
  input               rx_clk,
  input               rx_rst_n,
  input               rx_clk_en_i,        //adapting to gmii/mii

  //configuration register i/f
  input  [31:0]       tsu_cfg_i,

  //ptpv2 message related information
  input  [3:0]        ptp_messageType_i,          
  input               is_ptp_message_i,  
  input               get_sfd_pulse_i,

  //xgmii interface
  //3 samples before
  input  [63:0]       rxd_p3_i,
  input  [7:0]        rxc_p3_i,                  

  input  [63:0]       rxd_i,
  input  [7:0]        rxc_i,

  output [63:0]       rxd_o,
  output [7:0]        rxc_o
);

  wire emb_ingressTime_en = tsu_cfg_i[5];
  wire embed_enable = (emb_ingressTime_en == 1'b1 && is_ptp_message_i == 1'b1 && ptp_messageType_i[3] == 1'b0) ? 1 : 0;

  //re-calculate fcs, if frame modified, replace old crc.
  //indicator used to replace crc
  reg rpl_crc, rpl_crc_z1;
  always @(*) begin
    rpl_crc = rpl_crc_z1;

    if(get_sfd_pulse_i == 1'b1) //start of frame detected
      rpl_crc = 0;
    else if(embed_enable == 1'b1)   
      rpl_crc = 1;
  end

  always @(posedge rx_clk or negedge rx_rst_n) begin
    if(!rx_rst_n)
      rpl_crc_z1 <= 1'b0;
    else if(rx_clk_en_i)
      rpl_crc_z1 <= rpl_crc; 
  end

  //instantiate crc module
  xge_crc rx_xge_crc(
    .clk                (rx_clk),
    .rst_n              (rx_rst_n),              
    .clk_en_i           (rx_clk_en_i),
    
    .rpl_flag_i         (rpl_crc_z1),

    .xd_p3_i            (rxd_p3_i),
    .xc_p3_i            (rxc_p3_i),

    .xd_i               (rxd_i),
    .xc_i               (rxc_i),

    .xd_o               (rxd_o),
    .xc_o               (rxc_o)
  );  

endmodule
