/*+
 * Copyright (c) 2022-2023 Zhengde
 *
 * Copyright (c) 2001 Jon Gao (gaojon@yahoo.com) 
 *
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1 Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 * 
 * 2 Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * 
 * 3 Neither the name of the copyright holder nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-*/

/*+
 * EMAC RX top level
-*/

module emac_rx (
    input               rst_n              ,
    input               clk_user           ,
    input               clk                ,
    //GMII/MII interface
    input               MRxDv_i            ,       
    input  [7:0]        MRxD_i             ,       
    input               MRxErr_i           ,       
    //flow control signals to TX MAC 
    output [15:0]       pause_quanta_o     ,   
    output              pause_quanta_val_o ,   
    //user interface 
    output              rx_mac_ra_o        ,
    input               rx_mac_rd_i        ,
    output [31:0]       rx_mac_data_o      ,
    output [1:0]        rx_mac_be_o        ,
    output              rx_mac_pa_o        ,
    output              rx_mac_sop_o       ,
    output              rx_mac_eop_o       ,
    //Host interface registers
    input               r_RxEn_i                    , //receive enable
    input               r_rxAddrChkEn_i             , //check RX MAC address enable    
    input  [47:0]       r_rxMacAddr_i               , //MAC address used for check
    input  [31:0]       r_Hash0_i                   , //HASH table for address check, lower 4 bytes
    input  [31:0]       r_Hash1_i                   , //HASH table for address check, upper 4 bytes 
    input               r_BroadcastFilterEn_i       , //Broadcast packet filter enable
    input  [15:0]       r_BroadcastBucketDepth_i    , //Bucket depeth of broadcast packet filter    
    input  [15:0]       r_BroadcastBucketInterval_i , //time interval of refilling of broadcast bucket
    input               r_RxAppendCrc_i             , //retain FCS of received ethernet frame when hand up
    input  [4:0]        r_rxHwMark_i                , //RX FIFO high water mark
    input  [4:0]        r_rxLwMark_i                , //RX FIFO low water mark
    input               r_CrcChkEn_i                , //enable CRC check of received ethernet frame              
    input  [5:0]        r_RxIFGSet_i                , //minimum gap between consecutive received frames
    input  [15:0]       r_RxMaxLength_i             , //maximum frame length to be received (1518)
    input  [15:0]       r_RxMinLength_i             , //minimum frame length to be received (64)
    //RMON interface
    output [15:0]       rx_pkt_length_rmon_o        ,
    output              rx_apply_rmon_o             ,
    output [2:0]        rx_pkt_err_type_rmon_o      ,
    output [2:0]        rx_pkt_type_rmon_o          
);
    //++
    //internal signals                                                              
    //--
    
    //CRC check interface
    wire            crc_en  ;       
    wire            crc_init;       
    wire            crc_err ;
    //received MAC address check interface
    wire            mac_add_en          ;
    wire            mac_rx_add_chk_err  ;
    //broadcast filter interface
    wire            broadcast_ptr       ;
    wire            broadcast_drop      ;
    //MAC receive control interface 
    wire    [7:0]   fifo_data       ;
    wire            fifo_data_en    ;
    wire            fifo_full       ;
    wire            fifo_data_err   ;
    wire            fifo_data_end   ;

//******************************************************************************
//instantiation                                                            
//******************************************************************************


MAC_rx_ctrl U_MAC_rx_ctrl(
.rst_n                       (rst_n                     ),                                              
.clk                         (clk                       ),                                                 
  //RMII interface           ( //RMII interface         ),                                                    
.MRxDv_i                     (MRxDv_i                   ),                             
.MRxD_i                        (MRxD_i                      ),                         
.MRxErr_i                      (MRxErr_i                    ),                             
 //CRC_chk interface         (//CRC_chk interface       ),                                                   
.crc_en                      (crc_en                    ),                                          
.crc_init                    (crc_init                  ),                           
.crc_err                     (crc_err                   ),                              
 //MAC_rx_add_chk interface  (//MAC_rx_add_chk interface),                                                   
.mac_add_en                  (mac_add_en                ),                                             
.mac_rx_add_chk_err          (mac_rx_add_chk_err        ),                             
 //broadcast_filter          (//broadcast_filter        ),                           
.broadcast_ptr               (broadcast_ptr             ),                         
.broadcast_drop              (broadcast_drop            ),                             
 //flow_control signals      (//flow_control signals    ),                           
.pause_quanta_o                (pause_quanta_o              ),                         
.pause_quanta_val_o            (pause_quanta_val_o          ),                         
 //MAC_rx_FF interface       (//MAC_rx_FF interface     ),                                                   
.fifo_data                   (fifo_data                 ),                                         
.fifo_data_en                (fifo_data_en              ),                                         
.fifo_data_err               (fifo_data_err             ),                         
.fifo_data_end               (fifo_data_end             ),                         
.fifo_full                   (fifo_full                 ),                                      
 //RMON interface            (//RMON interface          ),                               
.rx_pkt_type_rmon_o            (rx_pkt_type_rmon_o          ),                                        
.rx_pkt_length_rmon_o          (rx_pkt_length_rmon_o        ),                                             
.rx_apply_rmon_o               (rx_apply_rmon_o             ),                                         
.rx_pkt_err_type_rmon_o        (rx_pkt_err_type_rmon_o      ),                                         
 //CPU                       (//CPU                     ),   
.r_RxEn_i                      (r_RxEn_i                    ),
.r_RxIFGSet_i                  (r_RxIFGSet_i                ),                             
.r_RxMaxLength_i               (r_RxMaxLength_i             ),                           
.r_RxMinLength_i               (r_RxMinLength_i             )                           
);

MAC_rx_FF  U_MAC_rx_FF (
.rst_n                       (rst_n                     ),
.clk_mac                     (clk                       ), 
.clk_sys                     (clk_user                  ), 
 //MAC_rx_ctrl interface     (//MAC_rx_ctrl interface   ),
.fifo_data                   (fifo_data                 ),
.fifo_data_en                (fifo_data_en              ),
.fifo_full                   (fifo_full                 ),
.fifo_data_err               (fifo_data_err             ),
.fifo_data_end               (fifo_data_end             ),
 //CPU                       (//CPU                     ),
.r_rxHwMark_i                   (r_rxHwMark_i                 ),
.r_rxLwMark_i                   (r_rxLwMark_i                 ),
.RX_APPEND_CRC               (RX_APPEND_CRC             ),
 //user interface            (//user interface          ),
.rx_mac_ra_o                   (rx_mac_ra_o                 ),
.rx_mac_rd_i                   (rx_mac_rd_i                 ),
.rx_mac_data_o                 (rx_mac_data_o               ), 
.rx_mac_be_o                   (rx_mac_be_o                 ),
.rx_mac_sop_o                  (rx_mac_sop_o                ), 
.rx_mac_pa_o                   (rx_mac_pa_o                 ),
.rx_mac_eop_o                  (rx_mac_eop_o                ) 
); 

`ifdef MAC_BROADCAST_FILTER_EN
Broadcast_filter U_Broadcast_filter(
.rst_n                      (rst_n                      ),
.clk                        (clk                        ),
 //MAC_rx_ctrl              (//MAC_rx_ctrl              ),
.broadcast_ptr              (broadcast_ptr              ),
.broadcast_drop             (broadcast_drop             ),
 //FromCPU                  (//FromCPU                  ),
.r_BroadcastFilterEn_i        (r_BroadcastFilterEn_i        ),
.r_BroadcastBucketDepth_i     (r_BroadcastBucketDepth_i     ),           
.broadcast_bucket_interval  (broadcast_bucket_interval  )
); 
`else
assign broadcast_drop=0;
`endif

CRC_chk U_CRC_chk(
.rst_n                      (rst_n                      ),
.clk                        (clk                        ),
.crc_data                   (fifo_data                  ),
.crc_init                   (crc_init                   ),
.crc_en                     (crc_en                     ),
 //From CPU                 (//From CPU                 ),
.r_CrcChkEn_i                 (r_CrcChkEn_i                 ),
.crc_err                    (crc_err                    )
);   

`ifdef MAC_TARGET_CHECK_EN
MAC_rx_add_chk U_MAC_rx_add_chk(
.rst_n                      (rst_n                      ),
.clk                        (clk                        ),
.Init                       (crc_init                   ),
.data                       (fifo_data                  ),
.mac_add_en                 (mac_add_en                 ),
.mac_rx_add_chk_err         (mac_rx_add_chk_err         ),
 //From CPU                 (//From CPU                 ),
.r_rxAddrChkEn_i          (r_rxAddrChkEn_i          ),
.r_rxMacAddr_i            (r_rxMacAddr_i            )
);
`else
assign mac_rx_add_chk_err=0;
`endif



endmodule

