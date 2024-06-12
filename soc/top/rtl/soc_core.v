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

module soc_core
(
    input           clk              ,
    input           rst_n            ,
    input  [ 31:0]  reset_vector_i   ,

    // Ethernet PHY GMII/MII rx interface
    input           rx_clk_i   ,
    input           rx_dv_i    , 
    input           rx_er_i    , 
    input  [7:0]    rxd_i      , 
    input           crs_i      ,    //carrier sense from PHY
    input           col_i      ,    //collision from PHY
      
    // Ethernet PHY GMII/MII tx interface
    output          gtx_clk_o  ,    //used only in GMII mode, from MAC to PHY
    input           tx_clk_i   ,    //used only in MII mode, from PHY to MAc
    output          tx_en_o    ,
    output          tx_er_o    ,
    output [7:0]    txd_o      ,

    // Ethernet PHY mdio interface
    output          mdc_o      ,    //mdio clock
    output          mdo_en_o   ,    //mdio output enable
    output          mdo_o      ,    //mdio serial data output
    input           mdi_i      ,    //mdio serial data input

    // AXI4 interface to external memory (SDRAM or DDR3 SDRAM)
    input           mem_awready_i ,
    input           mem_wready_i  ,
    input           mem_bvalid_i  ,
    input  [  1:0]  mem_bresp_i   ,
    input  [  3:0]  mem_bid_i     ,
    input           mem_arready_i ,
    input           mem_rvalid_i  ,
    input  [ 31:0]  mem_rdata_i   ,
    input  [  1:0]  mem_rresp_i   ,
    input  [  3:0]  mem_rid_i     ,
    input           mem_rlast_i   ,

    output          mem_awvalid_o ,
    output [ 31:0]  mem_awaddr_o  ,
    output [  3:0]  mem_awid_o    ,
    output [  7:0]  mem_awlen_o   ,
    output [  1:0]  mem_awburst_o ,
    output          mem_wvalid_o  ,
    output [ 31:0]  mem_wdata_o   ,
    output [  3:0]  mem_wstrb_o   ,
    output          mem_wlast_o   ,
    output          mem_bready_o  ,
    output          mem_arvalid_o ,
    output [ 31:0]  mem_araddr_o  ,
    output [  3:0]  mem_arid_o    ,
    output [  7:0]  mem_arlen_o   ,
    output [  1:0]  mem_arburst_o ,
    output          mem_rready_o  ,

    // UART interface
    input           uart_mst_i ,    //0: Normal slave operation, 1: UART as AXI4 bus master 
    input           uart_rxd_i ,
    output          uart_txd_o ,    

    // SPI interface
    output          spi_clk_o  ,
    output          spi_cs_o   ,
    input           spi_miso_i ,
    output          spi_mosi_o ,

    // JTAG
    input           tck_i    , 
    input           tms_i    , 
    input           tdi_i    , 
    output          tdo_o     
);

    wire            axi_i_awready_w  ;
    wire            axi_i_wready_w   ;
    wire            axi_i_bvalid_w   ;
    wire  [  1:0]   axi_i_bresp_w    ;
    wire  [  3:0]   axi_i_bid_w      ;
    wire            axi_i_arready_w  ;
    wire            axi_i_rvalid_w   ;
    wire  [ 31:0]   axi_i_rdata_w    ;
    wire  [  1:0]   axi_i_rresp_w    ;
    wire  [  3:0]   axi_i_rid_w      ;
    wire            axi_i_rlast_w    ;
    wire            axi_d_awready_w  ;
    wire            axi_d_wready_w   ;
    wire            axi_d_bvalid_w   ;
    wire  [  1:0]   axi_d_bresp_w    ;
    wire  [  3:0]   axi_d_bid_w      ;
    wire            axi_d_arready_w  ;
    wire            axi_d_rvalid_w   ;
    wire  [ 31:0]   axi_d_rdata_w    ;
    wire  [  1:0]   axi_d_rresp_w    ;
    wire  [  3:0]   axi_d_rid_w      ;
    wire            axi_d_rlast_w    ;

    wire            intr_w           ;

    wire            axi_i_awvalid_o  ;
    wire  [ 31:0]   axi_i_awaddr_o   ;
    wire  [  3:0]   axi_i_awid_o     ;
    wire  [  7:0]   axi_i_awlen_o    ;
    wire  [  1:0]   axi_i_awburst_o  ;
    wire            axi_i_wvalid_o   ;
    wire  [ 31:0]   axi_i_wdata_o    ;
    wire  [  3:0]   axi_i_wstrb_o    ;
    wire            axi_i_wlast_o    ;
    wire            axi_i_bready_o   ;
    wire            axi_i_arvalid_o  ;
    wire  [ 31:0]   axi_i_araddr_o   ;
    wire  [  3:0]   axi_i_arid_o     ;
    wire  [  7:0]   axi_i_arlen_o    ;
    wire  [  1:0]   axi_i_arburst_o  ;
    wire            axi_i_rready_o   ;
    wire            axi_d_awvalid_o  ;
    wire  [ 31:0]   axi_d_awaddr_o   ;
    wire  [  3:0]   axi_d_awid_o     ;
    wire  [  7:0]   axi_d_awlen_o    ;
    wire  [  1:0]   axi_d_awburst_o  ;
    wire            axi_d_wvalid_o   ;
    wire  [ 31:0]   axi_d_wdata_o    ;
    wire  [  3:0]   axi_d_wstrb_o    ;
    wire            axi_d_wlast_o    ;
    wire            axi_d_bready_o   ;
    wire            axi_d_arvalid_o  ;
    wire  [ 31:0]   axi_d_araddr_o   ;
    wire  [  3:0]   axi_d_arid_o     ;
    wire  [  7:0]   axi_d_arlen_o    ;
    wire  [  1:0]   axi_d_arburst_o  ;
    wire            axi_d_rready_o   ;

    riscv_top
    #(
        .CORE_ID                   ( 0           ) ,
        .ICACHE_AXI_ID             ( 4'h8        ) ,
        .DCACHE_AXI_ID             ( 4'h4        ) ,
        .SUPPORT_BRANCH_PREDICTION ( 1           ) ,
        .SUPPORT_MULDIV            ( 1           ) ,
        .SUPPORT_SUPER             ( 1           ) ,
        .SUPPORT_MMU               ( 1           ) ,
        .SUPPORT_DUAL_ISSUE        ( 1           ) ,
        .SUPPORT_LOAD_BYPASS       ( 1           ) ,
        .SUPPORT_MUL_BYPASS        ( 1           ) ,
        .EXTRA_DECODE_STAGE        ( 0           ) ,
        .MEM_CACHE_ADDR_MIN        ( 32'h80000000) ,
        .MEM_CACHE_ADDR_MAX        ( 32'h8fffffff) ,
        .NUM_BTB_ENTRIES           ( 32          ) ,
        .NUM_BTB_ENTRIES_W         ( 5           ) ,
        .NUM_BHT_ENTRIES           ( 512         ) ,
        .NUM_BHT_ENTRIES_W         ( 9           ) ,
        .RAS_ENABLE                ( 1           ) ,
        .GSHARE_ENABLE             ( 0           ) ,
        .BHT_ENABLE                ( 1           ) ,
        .NUM_RAS_ENTRIES           ( 8           ) ,
        .NUM_RAS_ENTRIES_W         ( 3           )   
    )
    u_riscv_top
    (
        // Inputs
        .clk                  (clk            ),
        .rst_n                (rst_n          ),
        .axi_i_awready_i      (axi_i_awready_w),
        .axi_i_wready_i       (axi_i_wready_w ),
        .axi_i_bvalid_i       (axi_i_bvalid_w ),
        .axi_i_bresp_i        (axi_i_bresp_w  ),
        .axi_i_bid_i          (axi_i_bid_w    ),
        .axi_i_arready_i      (axi_i_arready_w),
        .axi_i_rvalid_i       (axi_i_rvalid_w ),
        .axi_i_rdata_i        (axi_i_rdata_w  ),
        .axi_i_rresp_i        (axi_i_rresp_w  ),
        .axi_i_rid_i          (axi_i_rid_w    ),
        .axi_i_rlast_i        (axi_i_rlast_w  ),
        .axi_d_awready_i      (axi_d_awready_w),
        .axi_d_wready_i       (axi_d_wready_w ),
        .axi_d_bvalid_i       (axi_d_bvalid_w ),
        .axi_d_bresp_i        (axi_d_bresp_w  ),
        .axi_d_bid_i          (axi_d_bid_w    ),
        .axi_d_arready_i      (axi_d_arready_w),
        .axi_d_rvalid_i       (axi_d_rvalid_w ),
        .axi_d_rdata_i        (axi_d_rdata_w  ),
        .axi_d_rresp_i        (axi_d_rresp_w  ),
        .axi_d_rid_i          (axi_d_rid_w    ),
        .axi_d_rlast_i        (axi_d_rlast_w  ),
        .intr_i               (intr_w         ),
        .reset_vector_i       (reset_vector_i ),
    
        // Outputs
        .axi_i_awvalid_o      (axi_i_awvalid_w),
        .axi_i_awaddr_o       (axi_i_awaddr_w ),
        .axi_i_awid_o         (axi_i_awid_w   ),
        .axi_i_awlen_o        (axi_i_awlen_w  ),
        .axi_i_awburst_o      (axi_i_awburst_w),
        .axi_i_wvalid_o       (axi_i_wvalid_w ),
        .axi_i_wdata_o        (axi_i_wdata_w  ),
        .axi_i_wstrb_o        (axi_i_wstrb_w  ),
        .axi_i_wlast_o        (axi_i_wlast_w  ),
        .axi_i_bready_o       (axi_i_bready_w ),
        .axi_i_arvalid_o      (axi_i_arvalid_w),
        .axi_i_araddr_o       (axi_i_araddr_w ),
        .axi_i_arid_o         (axi_i_arid_w   ),
        .axi_i_arlen_o        (axi_i_arlen_w  ),
        .axi_i_arburst_o      (axi_i_arburst_w),
        .axi_i_rready_o       (axi_i_rready_w ),
        .axi_d_awvalid_o      (axi_d_awvalid_w),
        .axi_d_awaddr_o       (axi_d_awaddr_w ),
        .axi_d_awid_o         (axi_d_awid_w   ),
        .axi_d_awlen_o        (axi_d_awlen_w  ),
        .axi_d_awburst_o      (axi_d_awburst_w),
        .axi_d_wvalid_o       (axi_d_wvalid_w ),
        .axi_d_wdata_o        (axi_d_wdata_w  ),
        .axi_d_wstrb_o        (axi_d_wstrb_w  ),
        .axi_d_wlast_o        (axi_d_wlast_w  ),
        .axi_d_bready_o       (axi_d_bready_w ),
        .axi_d_arvalid_o      (axi_d_arvalid_w),
        .axi_d_araddr_o       (axi_d_araddr_w ),
        .axi_d_arid_o         (axi_d_arid_w   ),
        .axi_d_arlen_o        (axi_d_arlen_w  ),
        .axi_d_arburst_o      (axi_d_arburst_w),
        .axi_d_rready_o       (axi_d_rready_w ),
    
        // JTAG
        .tck_i                (tck_i), 
        .tms_i                (tms_i), 
        .tdi_i                (tdi_i), 
        .tdo_o                (tdo_o) 
    );


    dev_matrix u_dev_matrix
    (
        .clk                  (clk  ),
        .rst_n                (rst_n),
    
        // AXI4 interface to risc-v CPU core
        .cpu_i_awvalid_i      (axi_i_awvalid_w),
        .cpu_i_awaddr_i       (axi_i_awaddr_w ),
        .cpu_i_awid_i         (axi_i_awid_w   ),
        .cpu_i_awlen_i        (axi_i_awlen_w  ),
        .cpu_i_awburst_i      (axi_i_awburst_w),
        .cpu_i_wvalid_i       (axi_i_wvalid_w ),
        .cpu_i_wdata_i        (axi_i_wdata_w  ),
        .cpu_i_wstrb_i        (axi_i_wstrb_w  ),
        .cpu_i_wlast_i        (axi_i_wlast_w  ),
        .cpu_i_bready_i       (axi_i_bready_w ),
        .cpu_i_arvalid_i      (axi_i_arvalid_w),
        .cpu_i_araddr_i       (axi_i_araddr_w ),
        .cpu_i_arid_i         (axi_i_arid_w   ),
        .cpu_i_arlen_i        (axi_i_arlen_w  ),
        .cpu_i_arburst_i      (axi_i_arburst_w),
        .cpu_i_rready_i       (axi_i_rready_w ),
                                              
        .cpu_d_awvalid_i      (axi_d_awvalid_w),
        .cpu_d_awaddr_i       (axi_d_awaddr_w ),
        .cpu_d_awid_i         (axi_d_awid_w   ),
        .cpu_d_awlen_i        (axi_d_awlen_w  ),
        .cpu_d_awburst_i      (axi_d_awburst_w),
        .cpu_d_wvalid_i       (axi_d_wvalid_w ),
        .cpu_d_wdata_i        (axi_d_wdata_w  ),
        .cpu_d_wstrb_i        (axi_d_wstrb_w  ),
        .cpu_d_wlast_i        (axi_d_wlast_w  ),
        .cpu_d_bready_i       (axi_d_bready_w ),
        .cpu_d_arvalid_i      (axi_d_arvalid_w),
        .cpu_d_araddr_i       (axi_d_araddr_w ),
        .cpu_d_arid_i         (axi_d_arid_w   ),
        .cpu_d_arlen_i        (axi_d_arlen_w  ),
        .cpu_d_arburst_i      (axi_d_arburst_w),
        .cpu_d_rready_i       (axi_d_rready_w ),
    
        .cpu_i_awready_o      (axi_i_awready_w),
        .cpu_i_wready_o       (axi_i_wready_w ),
        .cpu_i_bvalid_o       (axi_i_bvalid_w ),
        .cpu_i_bresp_o        (axi_i_bresp_w  ),
        .cpu_i_bid_o          (axi_i_bid_w    ),
        .cpu_i_arready_o      (axi_i_arready_w),
        .cpu_i_rvalid_o       (axi_i_rvalid_w ),
        .cpu_i_rdata_o        (axi_i_rdata_w  ),
        .cpu_i_rresp_o        (axi_i_rresp_w  ),
        .cpu_i_rid_o          (axi_i_rid_w    ),
        .cpu_i_rlast_o        (axi_i_rlast_w  ),
                                              
        .cpu_d_awready_o      (axi_d_awready_w),
        .cpu_d_wready_o       (axi_d_wready_w ),
        .cpu_d_bvalid_o       (axi_d_bvalid_w ),
        .cpu_d_bresp_o        (axi_d_bresp_w  ),
        .cpu_d_bid_o          (axi_d_bid_w    ),
        .cpu_d_arready_o      (axi_d_arready_w),
        .cpu_d_rvalid_o       (axi_d_rvalid_w ),
        .cpu_d_rdata_o        (axi_d_rdata_w  ),
        .cpu_d_rresp_o        (axi_d_rresp_w  ),
        .cpu_d_rid_o          (axi_d_rid_w    ),
        .cpu_d_rlast_o        (axi_d_rlast_w  ),
    
        // Ethernet PHY GMII/MII rx interface
        .rx_clk_i             (rx_clk_i),
        .rx_dv_i              (rx_dv_i ), 
        .rx_er_i              (rx_er_i ), 
        .rxd_i                (rxd_i   ), 
        .crs_i                (crs_i   ),    //carrier sense from PHY
        .col_i                (col_i   ),    //collision from PHY
          
        // Ethernet PHY GMII/MII tx interface
        .gtx_clk_o            (gtx_clk_o),   //used only in GMII mode, from MAC to PHY
        .tx_clk_i             (tx_clk_i ),   //used only in MII mode, from PHY to MAc
        .tx_en_o              (tx_en_o  ),
        .tx_er_o              (tx_er_o  ),
        .txd_o                (txd_o    ),
    
        // Ethernet PHY mdio interface
        .mdc_o                (mdc_o   ),    //mdio clock
        .mdo_en_o             (mdo_en_o),    //mdio output enable
        .mdo_o                (mdo_o   ),    //mdio serial data output
        .mdi_i                (mdi_i   ),    //mdio serial data input
    
        // AXI4 interface to external memory (SDRAM or DDR3 SDRAM)
        .mem_awready_i        (mem_awready_i),
        .mem_wready_i         (mem_wready_i ),
        .mem_bvalid_i         (mem_bvalid_i ),
        .mem_bresp_i          (mem_bresp_i  ),
        .mem_bid_i            (mem_bid_i    ),
        .mem_arready_i        (mem_arready_i),
        .mem_rvalid_i         (mem_rvalid_i ),
        .mem_rdata_i          (mem_rdata_i  ),
        .mem_rresp_i          (mem_rresp_i  ),
        .mem_rid_i            (mem_rid_i    ),
        .mem_rlast_i          (mem_rlast_i  ),
                                            
        .mem_awvalid_o        (mem_awvalid_o),
        .mem_awaddr_o         (mem_awaddr_o ),
        .mem_awid_o           (mem_awid_o   ),
        .mem_awlen_o          (mem_awlen_o  ),
        .mem_awburst_o        (mem_awburst_o),
        .mem_wvalid_o         (mem_wvalid_o ),
        .mem_wdata_o          (mem_wdata_o  ),
        .mem_wstrb_o          (mem_wstrb_o  ),
        .mem_wlast_o          (mem_wlast_o  ),
        .mem_bready_o         (mem_bready_o ),
        .mem_arvalid_o        (mem_arvalid_o),
        .mem_araddr_o         (mem_araddr_o ),
        .mem_arid_o           (mem_arid_o   ),
        .mem_arlen_o          (mem_arlen_o  ),
        .mem_arburst_o        (mem_arburst_o),
        .mem_rready_o         (mem_rready_o ),
    
        // UART interface
        .uart_mst_i           (uart_mst_i),    //0: Normal slave operation, 1: UART as AXI4 bus master 
        .uart_rxd_i           (uart_rxd_i),
        .uart_txd_o           (uart_txd_o),    
    
        // SPI interface
        .spi_clk_o            (spi_clk_o ),
        .spi_cs_o             (spi_cs_o  ),
        .spi_miso_i           (spi_miso_i),
        .spi_mosi_o           (spi_mosi_o),
    
        // Interrupt 
        .intr_o               (intr_w)
    );

endmodule
