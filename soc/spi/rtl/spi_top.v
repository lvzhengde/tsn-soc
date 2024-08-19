/*+
 * Copyright (c) 2022-2024 Zhengde
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

`include "spi_defines.v"

module spi_top
(
    input           clk             ,
    input           rst_n           ,

    // AXI4 interface
    input           axi_awvalid_i   ,
    input  [ 31:0]  axi_awaddr_i    ,
    input  [  3:0]  axi_awid_i      ,
    input  [  7:0]  axi_awlen_i     ,
    input  [  1:0]  axi_awburst_i   ,
    input           axi_wvalid_i    ,
    input  [ 31:0]  axi_wdata_i     ,
    input  [  3:0]  axi_wstrb_i     ,
    input           axi_wlast_i     ,
    input           axi_bready_i    ,
    input           axi_arvalid_i   ,
    input  [ 31:0]  axi_araddr_i    ,
    input  [  3:0]  axi_arid_i      ,
    input  [  7:0]  axi_arlen_i     ,
    input  [  1:0]  axi_arburst_i   ,
    input           axi_rready_i    ,

    output          axi_awready_o   ,
    output          axi_wready_o    ,
    output          axi_bvalid_o    ,
    output [  1:0]  axi_bresp_o     ,
    output [  3:0]  axi_bid_o       ,
    output          axi_arready_o   ,
    output          axi_rvalid_o    ,
    output [ 31:0]  axi_rdata_o     ,
    output [  1:0]  axi_rresp_o     ,
    output [  3:0]  axi_rid_o       ,
    output          axi_rlast_o     ,

    // SPI interface
    output          spi_clk_o  ,
    output          spi_mosi_o ,
    input           spi_miso_i ,
    output          spi_cs_o   ,

    output          intr_o       
);
    //-----------------------------------------------------------------
    // Wires / Registers
    //-----------------------------------------------------------------
    wire            bus2ip_clk      ;
    wire            bus2ip_rst_n    ;
    wire [31:0]     bus2ip_addr_w   ;
    wire [31:0]     bus2ip_data_w   ;
    wire [3:0]      bus2ip_wstrb_w  ;    
    wire            bus2ip_rd_ce_w  ;  
    wire            bus2ip_wr_ce_w  ;  
    wire [31:0]     ip2bus_data_w   ;    
    wire            ip2bus_ready_w  ; 

    wire [31:0]     cfg_ip2bus_data_w  ; 
    wire            cfg_ip2bus_ready_w ;

    wire [31:0]     xip_ip2bus_data_w  ; 
    wire            xip_ip2bus_ready_w ;

    wire  xip_sel_w  = ((bus2ip_addr_w & `SPI_ADDR_MASK) == `SPI_FLASH_BASEADDR);

    assign ip2bus_data_w  = (xip_sel_w) ? xip_ip2bus_data_w  : cfg_ip2bus_data_w ;
    assign ip2bus_ready_w = (xip_sel_w) ? xip_ip2bus_ready_w : cfg_ip2bus_ready_w;

    //-----------------------------------------------------------------
    // SPI AXI4 interface
    //-----------------------------------------------------------------
    spi_axi u_spi_axi
    (
        .clk             (clk           ),
        .rst_n           (rst_n         ),
    
        // AXI4 interface
        .axi_awvalid_i   (axi_awvalid_i ),
        .axi_awaddr_i    (axi_awaddr_i  ),
        .axi_awid_i      (axi_awid_i    ),
        .axi_awlen_i     (axi_awlen_i   ),
        .axi_awburst_i   (axi_awburst_i ),
        .axi_wvalid_i    (axi_wvalid_i  ),
        .axi_wdata_i     (axi_wdata_i   ),
        .axi_wstrb_i     (axi_wstrb_i   ),
        .axi_wlast_i     (axi_wlast_i   ),
        .axi_bready_i    (axi_bready_i  ),
        .axi_arvalid_i   (axi_arvalid_i ),
        .axi_araddr_i    (axi_araddr_i  ),
        .axi_arid_i      (axi_arid_i    ),
        .axi_arlen_i     (axi_arlen_i   ),
        .axi_arburst_i   (axi_arburst_i ),
        .axi_rready_i    (axi_rready_i  ),
    
        .axi_awready_o   (axi_awready_o ),
        .axi_wready_o    (axi_wready_o  ),
        .axi_bvalid_o    (axi_bvalid_o  ),
        .axi_bresp_o     (axi_bresp_o   ),
        .axi_bid_o       (axi_bid_o     ),
        .axi_arready_o   (axi_arready_o ),
        .axi_rvalid_o    (axi_rvalid_o  ),
        .axi_rdata_o     (axi_rdata_o   ),
        .axi_rresp_o     (axi_rresp_o   ),
        .axi_rid_o       (axi_rid_o     ),
        .axi_rlast_o     (axi_rlast_o   ),
    
        //standard ip access bus interface
        .bus2ip_clk      (bus2ip_clk    ),
        .bus2ip_rst_n    (bus2ip_rst_n  ),
        .bus2ip_addr_o   (bus2ip_addr_w ),
        .bus2ip_data_o   (bus2ip_data_w ),
        .bus2ip_wstrb_o  (bus2ip_wstrb_w),    
        .bus2ip_rd_ce_o  (bus2ip_rd_ce_w),  
        .bus2ip_wr_ce_o  (bus2ip_wr_ce_w),  
        .ip2bus_data_i   (ip2bus_data_w ),    
        .ip2bus_ready_i  (ip2bus_ready_w)  
    );

    //-----------------------------------------------------------------
    // SPI control/status registers
    //-----------------------------------------------------------------
    wire         sw_reset_w  ;         

    wire         spi_cr_loop_w          ;        
    wire         spi_cr_spe_w           ;       
    wire         spi_cr_master_w        ;      
    wire         spi_cr_cpol_w          ;      
    wire         spi_cr_cpha_w          ;      
    wire         spi_cr_txfifo_rst_w    ;  
    wire         spi_cr_rxfifo_rst_w    ;  
    wire         spi_cr_trans_inhibit_w ; 
    wire         spi_cr_lsb_first_w     ; 

    wire         cfg_ssr_value_w ;        
    wire         cfg_dtr_wr_w    ;       
    wire [ 7:0]  cfg_dtr_data_w  ;        
    wire         cfg_drr_rd_w    ;        
    wire [ 7:0]  cfg_drr_data_w  ;        

    wire [15:0]  spi_ecr_sck_ratio_w     ; 
    wire [ 7:0]  spi_ecr_xip_read_code_w ; 
    wire         spi_ecr_extadd_w        ; 
    wire         spi_ecr_dummy_cycles_w  ; 

    wire         tx_full_w          ;
    wire         tx_empty_w         ;
    wire         rx_full_w          ;
    wire         rx_empty_w         ;
    wire         txfifo_empty_int_w ;      
    wire         rxfifo_full_int_w  ;      

    spi_registers u_spi_registers 
    (
        //32 bits IPBus interface
        .bus2ip_clk                 (bus2ip_clk             ),         
        .bus2ip_rst_n               (bus2ip_rst_n           ),        
        .bus2ip_addr_i              (bus2ip_addr_w          ),
        .bus2ip_data_i              (bus2ip_data_w          ),
        .bus2ip_wstrb_i             (bus2ip_wstrb_w         ),     
        .bus2ip_rd_ce_i             (bus2ip_rd_ce_w         ),         
        .bus2ip_wr_ce_i             (bus2ip_wr_ce_w         ),         
        .ip2bus_data_o              (cfg_ip2bus_data_w      ), 
        .ip2bus_ready_o             (cfg_ip2bus_ready_w     ),
    
        //SPI control and status registers
        .sw_reset_o                 (sw_reset_w             ),       
                                                            
        .spi_cr_loop_o              (spi_cr_loop_w          ),         
        .spi_cr_spe_o               (spi_cr_spe_w           ),        
        .spi_cr_master_o            (spi_cr_master_w        ),       
        .spi_cr_cpol_o              (spi_cr_cpol_w          ),      
        .spi_cr_cpha_o              (spi_cr_cpha_w          ),     
        .spi_cr_txfifo_rst_o        (spi_cr_txfifo_rst_w    ),    
        .spi_cr_rxfifo_rst_o        (spi_cr_rxfifo_rst_w    ),   
        .spi_cr_trans_inhibit_o     (spi_cr_trans_inhibit_w ), 
        .spi_cr_lsb_first_o         (spi_cr_lsb_first_w     ),  
    
        .spi_ssr_value_o            (cfg_ssr_value_w        ),          
        .spi_dtr_wr_o               (cfg_dtr_wr_w           ),         
        .spi_dtr_data_o             (cfg_dtr_data_w         ),          
        .spi_drr_rd_o               (cfg_drr_rd_w           ),          
        .spi_drr_data_i             (cfg_drr_data_w         ),          
    
        .spi_ecr_sck_ratio_o        (spi_ecr_sck_ratio_w    ), 
        .spi_ecr_xip_read_code_o    (spi_ecr_xip_read_code_w), 
        .spi_ecr_extadd_o           (spi_ecr_extadd_w       ), 
        .spi_ecr_dummy_cycles_o     (spi_ecr_dummy_cycles_w ), 
    
        .tx_full_i                  (tx_full_w              ),
        .tx_empty_i                 (tx_empty_w             ),
        .rx_full_i                  (rx_full_w              ),
        .rx_empty_i                 (rx_empty_w             ),
        .txfifo_empty_int_i         (txfifo_empty_int_w     ),      
        .rxfifo_full_int_i          (rxfifo_full_int_w      ),      
    
        .intr_o                     (intr_o                 )                    
    );

    //-----------------------------------------------------------------
    // SPI XIP (eXecute In Place) Read
    //-----------------------------------------------------------------
    wire              xip_flush_spi_w  ;         
    wire              xip_tx_accept_w  ;
    wire              xip_rx_ready_w   ;
    wire              xip_dtr_wr_w     ;        
    wire [ 7:0]       xip_dtr_data_w   ;          
    wire              xip_drr_rd_w     ;         
    wire [ 7:0]       xip_drr_data_w   ;         

    wire              spi_xip_ss_w     ;

    spi_xip_read u_spi_xip_read 
    (
        //32 bits IPBus interface
        .bus2ip_clk               (bus2ip_clk             ),         
        .bus2ip_rst_n             (bus2ip_rst_n           ),        
        .bus2ip_addr_i            (bus2ip_addr_w          ),
        .bus2ip_data_i            (bus2ip_data_w          ),         
        .bus2ip_wstrb_i           (bus2ip_wstrb_w         ),         
        .bus2ip_rd_ce_i           (bus2ip_rd_ce_w         ),         
        .bus2ip_wr_ce_i           (bus2ip_wr_ce_w         ),         
        .ip2bus_data_o            (xip_ip2bus_data_w      ), 
        .ip2bus_ready_o           (xip_ip2bus_ready_w     ),
    
        //SPI control and FIFO interface
        .flush_spi_o              (xip_flush_spi_w        ),         
        .tx_accept_i              (xip_tx_accept_w        ),
        .rx_ready_i               (xip_rx_ready_w         ),
        .spi_dtr_wr_o             (xip_dtr_wr_w           ),        
        .spi_dtr_data_o           (xip_dtr_data_w         ),          
        .spi_drr_rd_o             (xip_drr_rd_w           ),         
        .spi_drr_data_i           (xip_drr_data_w         ),         
    
        .spi_cr_cpol_i            (spi_cr_cpol_w          ),          
        .spi_cr_cpha_i            (spi_cr_cpha_w          ),          
        .spi_ecr_xip_read_code_i  (spi_ecr_xip_read_code_w), 
        .spi_ecr_extadd_i         (spi_ecr_extadd_w       ), 
        .spi_ecr_dummy_cycles_i   (spi_ecr_dummy_cycles_w ), 
    
        .spi_xip_ss_o             (spi_xip_ss_w)
    );

    //-----------------------------------------------------------------
    // TX FIFO
    //-----------------------------------------------------------------
    wire          tx_fifo_flush_w;
    
    wire          tx_push_w    ;
    wire [ 7:0]   tx_data_in_w ;
    wire          tx_pop_w     ;
    wire [ 7:0]   tx_data_out_w;

    wire          tx_accept_w  ;
    wire          tx_ready_w   ;

    assign tx_fifo_flush_w = sw_reset_w | spi_cr_txfifo_rst_w | xip_flush_spi_w;
    assign tx_push_w       = (xip_sel_w) ? xip_dtr_wr_w   : cfg_dtr_wr_w  ;
    assign tx_data_in_w    = (xip_sel_w) ? xip_dtr_data_w : cfg_dtr_data_w; 
    assign xip_tx_accept_w = tx_accept_w;
    
    spi_fifo
    #(
        .WIDTH     (8 ),
        .DEPTH     (16),
        .ADDR_W    (4 )
    )
    u_tx_fifo
    (
        .clk          (clk            ),
        .rst_n        (rst_n          ),
    
        .flush_i      (tx_fifo_flush_w),
    
        .data_in_i    (tx_data_in_w   ),
        .push_i       (tx_push_w      ),
        .accept_o     (tx_accept_w    ),
    
        .pop_i        (tx_pop_w       ),
        .data_out_o   (tx_data_out_w  ),
        .valid_o      (tx_ready_w     )
    );

    assign tx_full_w  = ~tx_accept_w;
    assign tx_empty_w = ~tx_ready_w ;

    reg    tx_empty_d1;
    always @(posedge clk) tx_empty_d1 <= tx_empty_w;

    assign txfifo_empty_int_w = tx_empty_w & (~tx_empty_d1);

    //-----------------------------------------------------------------
    // RX FIFO
    //-----------------------------------------------------------------
    wire          rx_fifo_flush_w;

    wire          rx_push_w    ;
    wire [ 7:0]   rx_data_in_w ;
    wire          rx_pop_w     ;
    wire [ 7:0]   rx_data_out_w;

    wire          rx_accept_w  ;
    wire          rx_ready_w   ;
    
    assign rx_fifo_flush_w = sw_reset_w | spi_cr_rxfifo_rst_w | xip_flush_spi_w;
    assign rx_pop_w        = (xip_sel_w) ? xip_drr_rd_w : cfg_drr_rd_w;
    assign cfg_drr_data_w  = rx_data_out_w;
    assign xip_drr_data_w  = rx_data_out_w;
    assign xip_rx_ready_w  = rx_ready_w   ;

    spi_fifo
    #(
        .WIDTH     (8 ),
        .DEPTH     (16),
        .ADDR_W    (4 )
    )
    u_rx_fifo
    (
        .clk          (clk            ),
        .rst_n        (rst_n          ),
    
        .flush_i      (rx_fifo_flush_w),
    
        .data_in_i    (rx_data_in_w   ),
        .push_i       (rx_push_w      ),
        .accept_o     (rx_accept_w    ),
    
        .pop_i        (rx_pop_w       ),
        .data_out_o   (rx_data_out_w  ),
        .valid_o      (rx_ready_w     )
    );

    assign rx_full_w  = ~rx_accept_w;
    assign rx_empty_w = ~rx_ready_w ;

    reg    rx_full_d1;
    always @(posedge clk) rx_full_d1 <= rx_full_w;

    assign rxfifo_full_int_w = rx_full_w & (~rx_full_d1);

    //-----------------------------------------------------------------
    // SPI master interface
    //-----------------------------------------------------------------
    wire          spi_sw_reset_w;
    wire          spi_req_w     ;
    wire          spi_start_w   ;
    wire          spi_done_w    ;
    wire          spi_busy_w    ;
    wire [ 7:0]   spi_data_in_w ;
    wire [ 7:0]   spi_data_out_w;

    wire   enable_w     = spi_cr_spe_w & spi_cr_master_w & ~spi_cr_trans_inhibit_w;
    assign spi_start_w  = enable_w & ~spi_busy_w & ~spi_done_w & tx_ready_w;

    assign spi_sw_reset_w = sw_reset_w | xip_flush_spi_w;
    assign spi_req_w      = (xip_sel_w) ? ~spi_xip_ss_w : ~cfg_ssr_value_w;

    spi_master u_spi_master
    (
        .clk            (clk                ),
        .rst_n          (rst_n              ),
        .sw_reset_i     (spi_sw_reset_w     ),
    
        .cpol_i         (spi_cr_cpol_w      ),
        .cpha_i         (spi_cr_cpha_w      ),
        .spi_loop_i     (spi_cr_loop_w      ),
        .sck_ratio_i    (spi_ecr_sck_ratio_w),
    
        .req_i          (spi_req_w          ),
        .start_i        (spi_start_w        ),
        .done_o         (spi_done_w         ),
        .busy_o         (spi_busy_w         ),
        .data_i         (spi_data_in_w      ),
        .data_o         (spi_data_out_w     ),
    
        .spi_clk_o      (spi_clk_o          ),
        .spi_mosi_o     (spi_mosi_o         ),
        .spi_miso_i     (spi_miso_i         ),
        .spi_cs_o       (spi_cs_o           )
    );

    // Reverse order if LSB first
    assign spi_data_in_w = spi_cr_lsb_first_w ? 
        {
          tx_data_out_w[0]
        , tx_data_out_w[1]
        , tx_data_out_w[2]
        , tx_data_out_w[3]
        , tx_data_out_w[4]
        , tx_data_out_w[5]
        , tx_data_out_w[6]
        , tx_data_out_w[7]
        } : tx_data_out_w;
    assign tx_pop_w = spi_done_w;

    assign rx_data_in_w = spi_cr_lsb_first_w ? 
        {
          spi_data_out_w[0]
        , spi_data_out_w[1]
        , spi_data_out_w[2]
        , spi_data_out_w[3]
        , spi_data_out_w[4]
        , spi_data_out_w[5]
        , spi_data_out_w[6]
        , spi_data_out_w[7]
        } : spi_data_out_w;
    assign rx_push_w = spi_done_w;
    
endmodule


