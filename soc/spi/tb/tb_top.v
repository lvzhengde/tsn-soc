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

module tb_top;  
    parameter T_CLK   = 10 ; //100MHz clock
    parameter QDELAY  = 0.1;

    //--------------------------------------------------------------------
    // Clock / Reset Signals
    //--------------------------------------------------------------------
    reg clk   = 0;  
    reg rst_n = 0;

    always #(T_CLK/2) clk = ~clk;

    task reset;
    begin
        rst_n    = 0;
        #555 
        rst_n    = 1;
    end
    endtask     

    //--------------------------------------------------------------------
    // AXI Bus Master
    //--------------------------------------------------------------------
    wire           axi_awvalid_w ;  
    wire  [ 31:0]  axi_awaddr_w  ;   
    wire  [  3:0]  axi_awid_w    ;   
    wire  [  7:0]  axi_awlen_w   ;   
    wire  [  1:0]  axi_awburst_w ;  
    wire           axi_wvalid_w  ;   
    wire  [ 31:0]  axi_wdata_w   ;  
    wire  [  3:0]  axi_wstrb_w   ;  
    wire           axi_wlast_w   ;  
    wire           axi_bready_w  ;   
    wire           axi_arvalid_w ;    
    wire  [ 31:0]  axi_araddr_w  ;   
    wire  [  3:0]  axi_arid_w    ;   
    wire  [  7:0]  axi_arlen_w   ;  
    wire  [  1:0]  axi_arburst_w ;    
    wire           axi_rready_w  ;   
     
    wire           axi_awready_w ;   
    wire           axi_wready_w  ;  
    wire           axi_bvalid_w  ;  
    wire  [  1:0]  axi_bresp_w   ; 
    wire  [  3:0]  axi_bid_w     ;
    wire           axi_arready_w ;   
    wire           axi_rvalid_w  ;  
    wire  [ 31:0]  axi_rdata_w   ; 
    wire  [  1:0]  axi_rresp_w   ; 
    wire  [  3:0]  axi_rid_w     ; 
    wire           axi_rlast_w   ; 

    reg    test_busy = 1;

    axi4_master 
    #(
        .ID  (0)
    )
    u_axi4_master
    (
        .clk               (clk           ),
        .rst_n             (rst_n         ),
    
        .axi_awready_i     (axi_awready_w ),
        .axi_wready_i      (axi_wready_w  ),
        .axi_bvalid_i      (axi_bvalid_w  ),
        .axi_bresp_i       (axi_bresp_w   ),
        .axi_bid_i         (axi_bid_w     ),
        .axi_arready_i     (axi_arready_w ),
        .axi_rvalid_i      (axi_rvalid_w  ),
        .axi_rdata_i       (axi_rdata_w   ),
        .axi_rresp_i       (axi_rresp_w   ),
        .axi_rid_i         (axi_rid_w     ),
        .axi_rlast_i       (axi_rlast_w   ),
    
        .axi_awvalid_o     (axi_awvalid_w ),
        .axi_awaddr_o      (axi_awaddr_w  ),
        .axi_awid_o        (axi_awid_w    ),
        .axi_awlen_o       (axi_awlen_w   ),
        .axi_awburst_o     (axi_awburst_w ),
        .axi_wvalid_o      (axi_wvalid_w  ),
        .axi_wdata_o       (axi_wdata_w   ),
        .axi_wstrb_o       (axi_wstrb_w   ),
        .axi_wlast_o       (axi_wlast_w   ),
        .axi_bready_o      (axi_bready_w  ),
        .axi_arvalid_o     (axi_arvalid_w ),
        .axi_araddr_o      (axi_araddr_w  ),
        .axi_arid_o        (axi_arid_w    ),
        .axi_arlen_o       (axi_arlen_w   ),
        .axi_arburst_o     (axi_arburst_w ),
        .axi_rready_o      (axi_rready_w  ),
    
        .busy_i            (test_busy     )          
    );

    //--------------------------------------------------------------------
    // Device Under Test--SPI Top
    //--------------------------------------------------------------------
    wire    spi_clk_w  ;
    wire    spi_mosi_w ;
    wire    spi_miso_w ;
    wire    spi_cs_w   ;
    wire    intr_w     ; 

    spi_top u_spi_top
    (
        .clk               (clk           ),
        .rst_n             (rst_n         ),
    
        // AXI4 interface
        .axi_awvalid_i     (axi_awvalid_w ),
        .axi_awaddr_i      (axi_awaddr_w  ),
        .axi_awid_i        (axi_awid_w    ),
        .axi_awlen_i       (axi_awlen_w   ),
        .axi_awburst_i     (axi_awburst_w ),
        .axi_wvalid_i      (axi_wvalid_w  ),
        .axi_wdata_i       (axi_wdata_w   ),
        .axi_wstrb_i       (axi_wstrb_w   ),
        .axi_wlast_i       (axi_wlast_w   ),
        .axi_bready_i      (axi_bready_w  ),
        .axi_arvalid_i     (axi_arvalid_w ),
        .axi_araddr_i      (axi_araddr_w  ),
        .axi_arid_i        (axi_arid_w    ),
        .axi_arlen_i       (axi_arlen_w   ),
        .axi_arburst_i     (axi_arburst_w ),
        .axi_rready_i      (axi_rready_w  ),
    
        .axi_awready_o     (axi_awready_w ),
        .axi_wready_o      (axi_wready_w  ),
        .axi_bvalid_o      (axi_bvalid_w  ),
        .axi_bresp_o       (axi_bresp_w   ),
        .axi_bid_o         (axi_bid_w     ),
        .axi_arready_o     (axi_arready_w ),
        .axi_rvalid_o      (axi_rvalid_w  ),
        .axi_rdata_o       (axi_rdata_w   ),
        .axi_rresp_o       (axi_rresp_w   ),
        .axi_rid_o         (axi_rid_w     ),
        .axi_rlast_o       (axi_rlast_w   ),
    
        // SPI interface
        .spi_clk_o         (spi_clk_w     ),
        .spi_mosi_o        (spi_mosi_w    ),
        .spi_miso_i        (spi_miso_w    ),
        .spi_cs_o          (spi_cs_w      ),
                                 
        .intr_o            (intr_w        )  
    );


    //--------------------------------------------------------------------
    // SPI NOR Flash Model
    //--------------------------------------------------------------------
    flash_model u_flash_model  
    (
        .rst_n             (rst_n         ),
        .spi_clk_i         (spi_clk_w     ),
        .spi_cs_i          (spi_cs_w      ),    
        .spi_mosi_i        (spi_mosi_w    ),
        .spi_miso_o        (spi_miso_w    )
    );

endmodule
