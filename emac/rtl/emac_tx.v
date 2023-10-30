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
 * EMAC TX top level
-*/

module emac_tx (
    input           rst_n                  ,
    input           clk                    ,
    input           clk_user               ,
    // PHY interface
    output  [7:0]   TxD_o                  ,
    output          TxEn_o                 ,   
    output          TxErr_o                ,
    input           CRS_i                  ,
    // RMON
    output  [2:0]   tx_pkt_type_rmon_o     ,
    output  [15:0]  tx_pkt_length_rmon_o   ,
    output          tx_apply_rmon_o        ,
    output  [2:0]   tx_pkt_err_type_rmon_o ,
    // user interface 
    output          tx_mac_wa_o            ,
    input           tx_mac_wr_i            ,
    input   [31:0]  tx_mac_data_i          ,
    input   [1:0]   tx_mac_be_i            ,
    input           tx_mac_sop_i           ,
    input           tx_mac_eop_i           ,
    // host interface 
    input   [4:0]   r_txHwMark_i           , //TX FIFO high water mark
    input   [4:0]   r_txLwMark_i           , //TX FIFO low water mark 
    input           r_pause_frame_send_en_i, //enable transmit logic to send pause frame               
    input   [15:0]  r_pause_quanta_set_i   , //quanta value in sending pause frame
    input           r_FullDuplex_i         , //full duplex mode
    input   [3:0]   r_MaxRetry_i           , //Maximum retry times when collision occurred
    input   [5:0]   r_IFGSet_i             , //Minimum IFG value
    input           r_txMacAddr_en_i       , //enable to replace destination MAC address of transmitting packet            
    input   [47:0]  r_txMacAddr_i          , //mac address which will replace the target mac address of transmit packet.
    input           r_tx_pause_en_i        , //respond to received pause frame enable
    input           r_xmtPause_off_i       , //transmit pause frame with zero quanta
    input           r_xmtPause_on_i        , //transmit pause frame with setting quanta value
    // from MAC rx flow control       
    input   [15:0]  pause_quanta_i         ,   
    input           pause_quanta_val_i       
);

    //++
    //internal signals                                                              
    //--
    //CRC generator Interface 
    wire            crc_init            ;
    wire[7:0]       frame_data          ;
    wire            data_en             ;
    wire            crc_rd              ;
    wire            crc_end             ;
    wire[7:0]       crc_out             ;

    //random generator interface
    wire            random_init         ;
    wire[3:0]       retry_cnt            ;
    wire            random_time_meet    ;//levle hight indicate random time passed away

    //flow control
    wire            pause_apply         ;
    wire            pause_quanta_sub    ;
    wire            xoff_gen            ;
    wire            xoff_gen_complete   ;
    wire            xon_gen             ;
    wire            xon_gen_complete    ;               

    //MAC TX FIFO 
    wire[7:0]       fifo_data           ;
    wire            fifo_rd             ;
    wire            fifo_eop            ;
    wire            fifo_da             ;
    wire            fifo_rd_finish      ;
    wire            fifo_rd_retry       ;
    wire            fifo_ra             ;
    wire            fifo_data_err_empty ;
    wire            fifo_data_err_full  ;

//******************************************************************************        
//instantiation                                                              
//****************************************************************************** 
MAC_tx_ctrl U_MAC_tx_ctrl(
.rst_n                    (rst_n                  ),                    
.clk                      (clk                    ),            
 //CRC_gen Interface      (//CRC_gen Interface    ),           
.crc_init                 (crc_init               ),        
.frame_data               (frame_data             ),            
.data_en                  (data_en                ),            
.crc_rd                   (crc_rd                 ),            
.crc_end                  (crc_end                ),            
.crc_out                  (crc_out                ),            
 //random_gen interfac    (//random_gen interfac  ),           
.random_init              (random_init            ),            
.retry_cnt                 (retry_cnt               ),        
.random_time_meet         (random_time_meet       ),        
 //flow control           (//flow control         ),           
.pause_apply              (pause_apply            ),            
.pause_quanta_sub         (pause_quanta_sub       ),        
.xoff_gen                 (xoff_gen               ),        
.xoff_gen_complete        (xoff_gen_complete      ),            
.xon_gen                  (xon_gen                ),            
.xon_gen_complete         (xon_gen_complete       ),        
 //MAC_tx_FF              (//MAC_tx_FF            ),           
.fifo_data                (fifo_data              ),            
.fifo_rd                  (fifo_rd                ),            
.fifo_eop                 (fifo_eop               ),        
.fifo_da                  (fifo_da                ),            
.fifo_rd_finish           (fifo_rd_finish         ),            
.fifo_rd_retry            (fifo_rd_retry          ),            
.fifo_ra                  (fifo_ra                ),            
.fifo_data_err_empty      (fifo_data_err_empty    ),            
.fifo_data_err_full       (fifo_data_err_full     ),            
 //RMII                   (//RMII                 ),           
.TxD_o                      (TxD_o                    ),            
.TxEn_o                     (TxEn_o                   ),        
.TxErr_o                    (TxErr_o                  ),
.CRS_i                      (CRS_i                    ),            
 //RMON                   (//RMON                 ),           
.tx_pkt_type_rmon_o         (tx_pkt_type_rmon_o       ),        
.tx_pkt_length_rmon_o       (tx_pkt_length_rmon_o     ),            
.tx_apply_rmon_o            (tx_apply_rmon_o          ),            
.tx_pkt_err_type_rmon_o     (tx_pkt_err_type_rmon_o   ),           
 //CPU                    (//CPU                  ),           
.r_pause_frame_send_en_i      (r_pause_frame_send_en_i    ),            
.r_pause_quanta_set_i         (r_pause_quanta_set_i       ),                
.r_txMacAddr_en_i            (r_txMacAddr_en_i          ),            
.r_txMacAddr_i               (r_txMacAddr_i ),
.r_FullDuplex_i               (r_FullDuplex_i             ),            
.r_MaxRetry_i                 (r_MaxRetry_i               ),        
.r_IFGSet_i                   (r_IFGSet_i                 )            
);

crc_gen U_crc_gen(
.rst_n                    (rst_n                  ),
.clk                      (clk                    ),
.Init                     (crc_init               ),
.frame_data               (frame_data             ),
.data_en                  (data_en                ),
.crc_rd                   (crc_rd                 ),
.crc_out                  (crc_out                ),
.crc_end                  (crc_end                )
);

flow_ctrl U_flow_ctrl(
.rst_n                    (rst_n                  ),
.clk                      (clk                    ),
 //host processor         (//host processor       ),
.r_tx_pause_en_i              (r_tx_pause_en_i            ),
.r_xmtPause_off_i                 (r_xmtPause_off_i               ),
.r_xmtPause_on_i                  (r_xmtPause_on_i                ),
 //MAC_rx_flow            (//MAC_rx_flow          ),
.pause_quanta_i             (pause_quanta_i           ),
.pause_quanta_val_i         (pause_quanta_val_i       ),
 //MAC_tx_ctrl            (//MAC_tx_ctrl          ),
.pause_apply              (pause_apply            ),
.pause_quanta_sub         (pause_quanta_sub       ),
.xoff_gen                 (xoff_gen               ),
.xoff_gen_complete        (xoff_gen_complete      ),
.xon_gen                  (xon_gen                ),
.xon_gen_complete         (xon_gen_complete       )
);

MAC_tx_FF U_MAC_tx_FF(
.rst_n                    (rst_n                  ),
.clk_MAC                  (clk                    ),
.clk_SYS                  (clk_user               ),
 //MAC_rx_ctrl interf     (//MAC_rx_ctrl interf   ),
.fifo_data                (fifo_data              ),
.fifo_rd                  (fifo_rd                ),
.fifo_rd_finish           (fifo_rd_finish         ),
.fifo_rd_retry            (fifo_rd_retry          ),
.fifo_eop                 (fifo_eop               ),
.fifo_da                  (fifo_da                ),
.fifo_ra                  (fifo_ra                ),
.fifo_data_err_empty      (fifo_data_err_empty    ),
.fifo_data_err_full       (fifo_data_err_full     ),
 //user interface         (//user interface       ),
.tx_mac_wa_o                (tx_mac_wa_o              ),
.tx_mac_wr_i                (tx_mac_wr_i              ),
.tx_mac_data_i              (tx_mac_data_i            ),
.tx_mac_be_i                (tx_mac_be_i              ),
.tx_mac_sop_i               (tx_mac_sop_i             ),
.tx_mac_eop_i               (tx_mac_eop_i             ),
 //host interface         (//host interface       ),
.r_FullDuplex_i               (r_FullDuplex_i             ),
.r_txHwMark_i                (r_txHwMark_i              ),
.r_txLwMark_i                (r_txLwMark_i              )
);

random_gen U_random_gen(
.rst_n                    (rst_n                  ),
.clk                      (clk                    ),
.Init                     (random_init            ),
.retry_cnt                 (retry_cnt               ),
.random_time_meet         (random_time_meet       ) 
);

endmodule

