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

/*+
 * interconnection of bus matrix and devices
-*/

module dev_matrix
(
    input           clk        ,
    input           rst_n      ,

    // AXI4 interface to risc-v CPU core
    input           cpu_i_awvalid_i    ,
    input  [ 31:0]  cpu_i_awaddr_i     ,
    input  [  3:0]  cpu_i_awid_i       ,
    input  [  7:0]  cpu_i_awlen_i      ,
    input  [  1:0]  cpu_i_awburst_i    ,
    input           cpu_i_wvalid_i     ,
    input  [ 31:0]  cpu_i_wdata_i      ,
    input  [  3:0]  cpu_i_wstrb_i      ,
    input           cpu_i_wlast_i      ,
    input           cpu_i_bready_i     ,
    input           cpu_i_arvalid_i    ,
    input  [ 31:0]  cpu_i_araddr_i     ,
    input  [  3:0]  cpu_i_arid_i       ,
    input  [  7:0]  cpu_i_arlen_i      ,
    input  [  1:0]  cpu_i_arburst_i    ,
    input           cpu_i_rready_i     ,
                                        
    input           cpu_d_awvalid_i    ,
    input  [ 31:0]  cpu_d_awaddr_i     ,
    input  [  3:0]  cpu_d_awid_i       ,
    input  [  7:0]  cpu_d_awlen_i      ,
    input  [  1:0]  cpu_d_awburst_i    ,
    input           cpu_d_wvalid_i     ,
    input  [ 31:0]  cpu_d_wdata_i      ,
    input  [  3:0]  cpu_d_wstrb_i      ,
    input           cpu_d_wlast_i      ,
    input           cpu_d_bready_i     ,
    input           cpu_d_arvalid_i    ,
    input  [ 31:0]  cpu_d_araddr_i     ,
    input  [  3:0]  cpu_d_arid_i       ,
    input  [  7:0]  cpu_d_arlen_i      ,
    input  [  1:0]  cpu_d_arburst_i    ,
    input           cpu_d_rready_i     ,

    output          cpu_i_awready_o    ,
    output          cpu_i_wready_o     ,
    output          cpu_i_bvalid_o     ,
    output [  1:0]  cpu_i_bresp_o      ,
    output [  3:0]  cpu_i_bid_o        ,
    output          cpu_i_arready_o    ,
    output          cpu_i_rvalid_o     ,
    output [ 31:0]  cpu_i_rdata_o      ,
    output [  1:0]  cpu_i_rresp_o      ,
    output [  3:0]  cpu_i_rid_o        ,
    output          cpu_i_rlast_o      ,
                                        
    output          cpu_d_awready_o    ,
    output          cpu_d_wready_o     ,
    output          cpu_d_bvalid_o     ,
    output [  1:0]  cpu_d_bresp_o      ,
    output [  3:0]  cpu_d_bid_o        ,
    output          cpu_d_arready_o    ,
    output          cpu_d_rvalid_o     ,
    output [ 31:0]  cpu_d_rdata_o      ,
    output [  1:0]  cpu_d_rresp_o      ,
    output [  3:0]  cpu_d_rid_o        ,
    output          cpu_d_rlast_o      ,

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

    // Interrupt 
    output          intr_o
);


endmodule

