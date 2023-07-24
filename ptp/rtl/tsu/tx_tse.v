/*++
//  tx timestamp engine
//  including tx_parse, tx_emb_ts, tx_rcst 
--*/

`include "ptpv2_defines.v"

module tx_tse(
  //xgmii interface
  input               tx_clk,
  input               tx_rst_n,
  input               tx_clk_en_i,            //for adapting to gmii/mii
  input  [63:0]       txd_i,
  input  [7:0]        txc_i,
  output [63:0]       txd_o,
  output [7:0]        txc_o,

  //timestamp input
  input  [79:0]       sfd_timestamp_i,         //48 bits seconds + 32 bits nanoseconds
  input  [15:0]       sfd_timestamp_frac_ns_i, //16 bit fractional nanoseconds 

  //configuration register i/f
  input  [31:0]       tsu_cfg_i,
  input  [31:0]       egress_asymmetry_i,
  
  //timestamp i/f, sync to rtc_clk
  output              txts_trig_o,
  output              txts_valid_o,
  
  output [79:0]       tx_sourcePortIdentity_o,  
  output [15:0]       tx_flagField_o,
  output [15:0]       tx_seqId_o,                 
  output [3:0]        tx_versionPTP_o,
  output [3:0]        tx_minorVersionPTP_o,
  output [3:0]        tx_messageType_o,  
  output [3:0]        tx_majorSdoId_o,

  //ptpv2 tx interrupt signal 
  output              int_tx_ptp_o
);

  wire [63:0]       txd_emb;
  wire [7:0]        txc_emb;

  wire              par_get_sfd_done;
  wire  [10:0]      par_eth_count_base;      
  wire  [10:0]      ptp_addr_base;
  wire  [3:0]       ptp_messageType;          
  wire  [63:0]      ptp_correctionField;
  wire  [31:0]      ptp_messageTypeSpecific;
  wire              is_ptp_message;  
  wire  [15:0]      ptp_messageLength;
  wire  [15:0]      ptp_flagField; 
  
  wire              ipv6_flag;
  wire  [10:0]      ipv6_addr_base;
  wire              ipv4_flag;
  wire  [10:0]      ipv4_addr_base;

  tx_parse tx_parse(
    .tx_clk                    (tx_clk     ),
    .tx_rst_n                  (tx_rst_n   ),
    .tx_clk_en_i               (tx_clk_en_i),       
  
    .txd_i                     (txd_i),
    .txc_i                     (txc_i),
  
    //signals to tx_emb_ts
    .txd_emb_o                 (txd_emb),
    .txc_emb_o                 (txc_emb),
  
    .get_sfd_done_o            (par_get_sfd_done       ),
    .eth_count_base_o          (par_eth_count_base     ),      
    .ptp_addr_base_o           (ptp_addr_base          ),
    .ptp_messageType_o         (ptp_messageType        ),          
    .ptp_correctionField_o     (ptp_correctionField    ),
    .ptp_messageTypeSpecific_o (ptp_messageTypeSpecific),
    .is_ptp_message_o          (is_ptp_message         ),  
    .ptp_messageLength_o       (ptp_messageLength      ),
    .ptp_flagField_o           (ptp_flagField          ), 
                                                         
    .ipv6_flag_o               (ipv6_flag              ),
    .ipv6_addr_base_o          (ipv6_addr_base         ),
    .ipv4_flag_o               (ipv4_flag              ),
    .ipv4_addr_base_o          (ipv4_addr_base         ),
  
    //configuration register i/f
    .tsu_cfg_i                 (tsu_cfg_i),
    
    //timestamp i/f, sync to rtc_clk
    .txts_trig_o               (txts_trig_o ),
    .txts_valid_o              (txts_valid_o),
    
    .tx_sourcePortIdentity_o   (tx_sourcePortIdentity_o),  
    .tx_flagField_o            (tx_flagField_o         ),
    .tx_seqId_o                (tx_seqId_o             ),                 
    .tx_versionPTP_o           (tx_versionPTP_o        ),
    .tx_minorVersionPTP_o      (tx_minorVersionPTP_o   ),
    .tx_messageType_o          (tx_messageType_o       ),  
    .tx_majorSdoId_o           (tx_majorSdoId_o        ),
  
    //ptpv2 tx interrupt signal 
    .int_tx_ptp_o              (int_tx_ptp_o)
  );

  wire [63:0]   emb_txd;
  wire [7:0]    emb_txc;

  wire [63:0]   emb_correctionField;     //ns * 2^16                               
  wire [31:0]   emb_ingress_time;        //32 bits ns  
  
  wire [10:0]   emb_ptp_addr_base;
  wire [3:0]    emb_ptp_messageType;          
  wire          emb_is_ptp_message;  
  wire [15:0]   emb_ptp_messageLength; 
  wire [15:0]   emb_ptp_flagField; 
  
  wire          emb_ipv6_flag;
  wire [10:0]   emb_ipv6_addr_base;
  wire          emb_ipv4_flag;
  wire [10:0]   emb_ipv4_addr_base;

  wire          emb_get_sfd_done;
  wire [10:0]   emb_eth_count_base;

  tx_emb_ts tx_emb_ts(
    .tx_clk                    (tx_clk     ),
    .tx_rst_n                  (tx_rst_n   ),
    .tx_clk_en_i               (tx_clk_en_i),            
  
    .txd_i                     (txd_emb),
    .txc_i                     (txc_emb),
  
    .txd_o                     (emb_txd),
    .txc_o                     (emb_txc),
  
    //configuration register i/f
    .tsu_cfg_i                 (tsu_cfg_i         ),
    .egress_asymmetry_i        (egress_asymmetry_i),
  
    //ptpv2 message related information
    .eth_count_base_i          (par_eth_count_base     ),      
    .ptp_addr_base_i           (ptp_addr_base      ),
    .ptp_messageType_i         (ptp_messageType        ),          
    .ptp_correctionField_i     (ptp_correctionField    ),
    .ptp_messageTypeSpecific_i (ptp_messageTypeSpecific),
    .is_ptp_message_i          (is_ptp_message         ),  
    .ptp_messageLength_i       (ptp_messageLength      ),
    .ptp_flagField_i           (ptp_flagField          ), 
  
    .ipv6_flag_i               (ipv6_flag     ),
    .ipv6_addr_base_i          (ipv6_addr_base),
    .ipv4_flag_i               (ipv4_flag     ),
    .ipv4_addr_base_i          (ipv4_addr_base),
  
    //output information of currently sending packet
    .correctionField_o         (emb_correctionField  ),
    .ingress_time_o            (emb_ingress_time     ), 
                                                   
    .ptp_addr_base_o           (emb_ptp_addr_base    ),
    .ptp_messageType_o         (emb_ptp_messageType  ),          
    .is_ptp_message_o          (emb_is_ptp_message   ),  
    .ptp_messageLength_o       (emb_ptp_messageLength), 
    .ptp_flagField_o           (emb_ptp_flagField    ), 
                                                   
    .ipv6_flag_o               (emb_ipv6_flag        ),
    .ipv6_addr_base_o          (emb_ipv6_addr_base   ),
    .ipv4_flag_o               (emb_ipv4_flag        ),
    .ipv4_addr_base_o          (emb_ipv4_addr_base   ),
  
    .get_sfd_done_i            (par_get_sfd_done  ),
    .get_sfd_done_o            (emb_get_sfd_done  ),
                                                
    .eth_count_base_o          (emb_eth_count_base)
  );

  tx_rcst tx_rcst (
    .tx_clk                    (tx_clk     ),
    .tx_rst_n                  (tx_rst_n   ),
    .tx_clk_en_i               (tx_clk_en_i),   
  
    .txd_i                     (emb_txd),
    .txc_i                     (emb_txc),
  
    .txd_o                     (txd_o),
    .txc_o                     (txc_o),
  
    //configuration register i/f
    .tsu_cfg_i                 (tsu_cfg_i),
  
    //timestamp input
    .sfd_timestamp_i           (sfd_timestamp_i        ),         
    .sfd_timestamp_frac_ns_i   (sfd_timestamp_frac_ns_i),
  
    .correctionField_i         (emb_correctionField  ),     
    .ingress_time_i            (emb_ingress_time     ),       
                                                   
    .ptp_addr_base_i           (emb_ptp_addr_base    ),
    .is_ptp_message_i          (emb_is_ptp_message   ),  
    .ptp_messageLength_i       (emb_ptp_messageLength), 
    .ptp_messageType_i         (emb_ptp_messageType  ),
    .ptp_flagField_i           (emb_ptp_flagField    ),  
                                                   
    .ipv6_flag_i               (emb_ipv6_flag        ),
    .ipv6_addr_base_i          (emb_ipv6_addr_base   ),
    .ipv4_flag_i               (emb_ipv4_flag        ),  
    .ipv4_addr_base_i          (emb_ipv4_addr_base   ),
  
    .eth_count_base_i          (emb_eth_count_base),
    .get_sfd_done_i            (emb_get_sfd_done  )
  );

endmodule

