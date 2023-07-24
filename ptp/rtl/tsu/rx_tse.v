/*++
//  rx timestamp engine
//  including rx_parse, rx_emb_ts, rx_rcst
--*/

`include "ptpv2_defines.v"

module rx_tse(
  //xgmii interface
  input               rx_clk,
  input               rx_rst_n,
  input               rx_clk_en_i,            //for adapting to gmii/mii
  input  [63:0]       rxd_i,
  input  [7:0]        rxc_i,
  output [63:0]       rxd_o,
  output [7:0]        rxc_o,

  //timestamp input
  input  [79:0]       sfd_timestamp_i,         //48 bits seconds + 32 bits nanoseconds
  input  [15:0]       sfd_timestamp_frac_ns_i, //16 bit fractional nanoseconds 

  //configuration register i/f
  input  [31:0]       tsu_cfg_i,
  input  [31:0]       link_delay_i,
  input  [31:0]       ingress_asymmetry_i,
  
  //timestamp i/f, sync to rtc_clk
  output              rxts_trig_o,
  output              rxts_valid_o,
  
  output [79:0]       rx_sourcePortIdentity_o,  
  output [15:0]       rx_flagField_o,
  output [15:0]       rx_seqId_o,                 
  output [3:0]        rx_versionPTP_o,
  output [3:0]        rx_minorVersionPTP_o,
  output [3:0]        rx_messageType_o,  
  output [3:0]        rx_majorSdoId_o,

  //ptpv2 rx interrupt signal 
  output              int_rx_ptp_o
);
  wire [63:0]       rxd_emb;
  wire [7:0]        rxc_emb;
  
  wire  [10:0]      par_eth_count_base;      
  wire  [10:0]      ptp_addr_base;
  wire  [3:0]       ptp_messageType;          
  wire  [63:0]      ptp_correctionField;
  wire              is_ptp_message;  
  wire              par_get_sfd_done;

  wire [63:0]       rxd_crc_p3;
  wire [7:0]        rxc_crc_p3;

  rx_parse rx_parse(
    .rx_clk                  (rx_clk     ),
    .rx_rst_n                (rx_rst_n   ),
    .rx_clk_en_i             (rx_clk_en_i), 
  
    .rxd_i                   (rxd_i),
    .rxc_i                   (rxc_i),
  
    //signals to rx_emb_ts
    .rxd_emb_o               (rxd_emb            ), 
    .rxc_emb_o               (rxc_emb            ), 
                                                   
    .eth_count_base_o        (par_eth_count_base     ),       
    .ptp_addr_base_o         (ptp_addr_base      ), 
    .ptp_messageType_o       (ptp_messageType    ),           
    .ptp_correctionField_o   (ptp_correctionField), 
    .is_ptp_message_o        (is_ptp_message     ),  
    .get_sfd_done_o          (par_get_sfd_done       ),
  
    //signals to rx_rcst
    .rxd_crc_p3_o            (rxd_crc_p3),
    .rxc_crc_p3_o            (rxc_crc_p3),
  
    //configuration register i/f
    .tsu_cfg_i               (tsu_cfg_i),
    
    //timestamp i/f, sync to rtc_clk
    .rxts_trig_o             (rxts_trig_o            ),
    .rxts_valid_o            (rxts_valid_o           ),
                             
    .rx_sourcePortIdentity_o (rx_sourcePortIdentity_o),  
    .rx_flagField_o          (rx_flagField_o         ),
    .rx_seqId_o              (rx_seqId_o             ),                 
    .rx_versionPTP_o         (rx_versionPTP_o        ),
    .rx_minorVersionPTP_o    (rx_minorVersionPTP_o   ),
    .rx_messageType_o        (rx_messageType_o       ),  
    .rx_majorSdoId_o         (rx_majorSdoId_o        ),
  
    //ptpv2 rx interrupt signal 
    .int_rx_ptp_o            (int_rx_ptp_o)
  );

  wire [63:0]   emb_rxd;
  wire [7:0]    emb_rxc;
  wire          emb_get_sfd_done;

  rx_emb_ts rx_emb_ts(
    .rx_clk                  (rx_clk     ),
    .rx_rst_n                (rx_rst_n   ),
    .rx_clk_en_i             (rx_clk_en_i),            
  
    .rxd_i                   (rxd_emb),
    .rxc_i                   (rxc_emb),
    .rxd_o                   (emb_rxd),
    .rxc_o                   (emb_rxc),
  
    //timestamp input
    .sfd_timestamp_i         (sfd_timestamp_i), 
  
    //configuration register i/f
    .tsu_cfg_i               (tsu_cfg_i          ),
    .link_delay_i            (link_delay_i       ),
    .ingress_asymmetry_i     (ingress_asymmetry_i),
  
    //ptpv2 message related information
    .eth_count_base_i        (par_eth_count_base     ),      
    .ptp_addr_base_i         (ptp_addr_base      ),
    .ptp_messageType_i       (ptp_messageType    ),          
    .ptp_correctionField_i   (ptp_correctionField),
    .is_ptp_message_i        (is_ptp_message     ),  
  
    .get_sfd_done_i          (par_get_sfd_done),
    .get_sfd_done_o          (emb_get_sfd_done),
  
    .eth_count_base_o        ()
  );

  wire   get_sfd_pulse = par_get_sfd_done & (~emb_get_sfd_done);

  rx_rcst rx_rcst(
    .rx_clk                  (rx_clk     ),
    .rx_rst_n                (rx_rst_n   ),
    .rx_clk_en_i             (rx_clk_en_i),            
  
    //configuration register i/f
    .tsu_cfg_i               (tsu_cfg_i),
  
    //ptpv2 message related information
    .ptp_messageType_i       (ptp_messageType),          
    .is_ptp_message_i        (is_ptp_message ),  
    .get_sfd_pulse_i         (get_sfd_pulse  ),
  
    //xgmii interface
    .rxd_p3_i                (rxd_crc_p3),
    .rxc_p3_i                (rxc_crc_p3),                  
  
    .rxd_i                   (emb_rxd),
    .rxc_i                   (emb_rxc),
  
    .rxd_o                   (rxd_o),
    .rxc_o                   (rxc_o)
  );

endmodule
