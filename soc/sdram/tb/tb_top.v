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
    //-----------------------------------------------------------------
    // Key Params
    //-----------------------------------------------------------------
    parameter SDRAM_MHZ             = 50;
    parameter SDRAM_ADDR_W          = 24;
    parameter SDRAM_COL_W           = 9;
    parameter SDRAM_READ_LATENCY    = 2;

    //--------------------------------------------------------------------
    // Clock / Reset Signals
    //--------------------------------------------------------------------
    localparam T_CLK   = 1000 / SDRAM_MHZ; //100MHz clock
    localparam QDELAY  = 0.1;

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
    wire           mst_awvalid_w ;  
    wire  [ 31:0]  mst_awaddr_w  ;   
    wire  [  3:0]  mst_awid_w    ;   
    wire  [  7:0]  mst_awlen_w   ;   
    wire  [  1:0]  mst_awburst_w ;  
    wire           mst_wvalid_w  ;   
    wire  [ 31:0]  mst_wdata_w   ;  
    wire  [  3:0]  mst_wstrb_w   ;  
    wire           mst_wlast_w   ;  
    wire           mst_bready_w  ;   
    wire           mst_arvalid_w ;    
    wire  [ 31:0]  mst_araddr_w  ;   
    wire  [  3:0]  mst_arid_w    ;   
    wire  [  7:0]  mst_arlen_w   ;  
    wire  [  1:0]  mst_arburst_w ;    
    wire           mst_rready_w  ;   
     
    wire           mst_awready_w ;   
    wire           mst_wready_w  ;  
    wire           mst_bvalid_w  ;  
    wire  [  1:0]  mst_bresp_w   ; 
    wire  [  3:0]  mst_bid_w     ;
    wire           mst_arready_w ;   
    wire           mst_rvalid_w  ;  
    wire  [ 31:0]  mst_rdata_w   ; 
    wire  [  1:0]  mst_rresp_w   ; 
    wire  [  3:0]  mst_rid_w     ; 
    wire           mst_rlast_w   ; 

    reg    test_busy = 1;

    axi4_master 
    #(
        .ID  (0)
    )
    u_axi4_master
    (
        .clk               (clk           ),
        .rst_n             (rst_n         ),
    
        .axi_awready_i     (mst_awready_w ),
        .axi_wready_i      (mst_wready_w  ),
        .axi_bvalid_i      (mst_bvalid_w  ),
        .axi_bresp_i       (mst_bresp_w   ),
        .axi_bid_i         (mst_bid_w     ),
        .axi_arready_i     (mst_arready_w ),
        .axi_rvalid_i      (mst_rvalid_w  ),
        .axi_rdata_i       (mst_rdata_w   ),
        .axi_rresp_i       (mst_rresp_w   ),
        .axi_rid_i         (mst_rid_w     ),
        .axi_rlast_i       (mst_rlast_w   ),
    
        .axi_awvalid_o     (mst_awvalid_w ),
        .axi_awaddr_o      (mst_awaddr_w  ),
        .axi_awid_o        (mst_awid_w    ),
        .axi_awlen_o       (mst_awlen_w   ),
        .axi_awburst_o     (mst_awburst_w ),
        .axi_wvalid_o      (mst_wvalid_w  ),
        .axi_wdata_o       (mst_wdata_w   ),
        .axi_wstrb_o       (mst_wstrb_w   ),
        .axi_wlast_o       (mst_wlast_w   ),
        .axi_bready_o      (mst_bready_w  ),
        .axi_arvalid_o     (mst_arvalid_w ),
        .axi_araddr_o      (mst_araddr_w  ),
        .axi_arid_o        (mst_arid_w    ),
        .axi_arlen_o       (mst_arlen_w   ),
        .axi_arburst_o     (mst_arburst_w ),
        .axi_rready_o      (mst_rready_w  ),
    
        .busy_i            (test_busy     )          
    );

    //-----------------------------------------------------------------
    // re-timing AXI busy signals then connect to sdram_axi
    //-----------------------------------------------------------------
    wire          slv_awvalid_w ;
    wire [ 31:0]  slv_awaddr_w  ;
    wire [  3:0]  slv_awid_w    ;
    wire [  7:0]  slv_awlen_w   ;
    wire [  1:0]  slv_awburst_w ;
    wire          slv_wvalid_w  ;
    wire [ 31:0]  slv_wdata_w   ;
    wire [  3:0]  slv_wstrb_w   ;
    wire          slv_wlast_w   ;
    wire          slv_bready_w  ;
    wire          slv_arvalid_w ;
    wire [ 31:0]  slv_araddr_w  ;
    wire [  3:0]  slv_arid_w    ;
    wire [  7:0]  slv_arlen_w   ;
    wire [  1:0]  slv_arburst_w ;
    wire          slv_rready_w  ;

    wire          slv_awready_w ;
    wire          slv_wready_w  ;
    wire          slv_bvalid_w  ;
    wire [  1:0]  slv_bresp_w   ;
    wire [  3:0]  slv_bid_w     ;
    wire          slv_arready_w ;
    wire          slv_rvalid_w  ;
    wire [ 31:0]  slv_rdata_w   ;
    wire [  1:0]  slv_rresp_w   ;
    wire [  3:0]  slv_rid_w     ;
    wire          slv_rlast_w   ;

    axi4_retime u_axi4_retime
    (
        // Inputs
        .clk               (clk           ),
        .rst_n             (rst_n         ),
        .inport_awvalid_i  (mst_awvalid_w ),
        .inport_awaddr_i   (mst_awaddr_w  ),
        .inport_awid_i     (mst_awid_w    ),
        .inport_awlen_i    (mst_awlen_w   ),
        .inport_awburst_i  (mst_awburst_w ),
        .inport_wvalid_i   (mst_wvalid_w  ),
        .inport_wdata_i    (mst_wdata_w   ),
        .inport_wstrb_i    (mst_wstrb_w   ),
        .inport_wlast_i    (mst_wlast_w   ),
        .inport_bready_i   (mst_bready_w  ),
        .inport_arvalid_i  (mst_arvalid_w ),
        .inport_araddr_i   (mst_araddr_w  ),
        .inport_arid_i     (mst_arid_w    ),
        .inport_arlen_i    (mst_arlen_w   ),
        .inport_arburst_i  (mst_arburst_w ),
        .inport_rready_i   (mst_rready_w  ),
        .outport_awready_i (slv_awready_w ),
        .outport_wready_i  (slv_wready_w  ),
        .outport_bvalid_i  (slv_bvalid_w  ),
        .outport_bresp_i   (slv_bresp_w   ),
        .outport_bid_i     (slv_bid_w     ),
        .outport_arready_i (slv_arready_w ),
        .outport_rvalid_i  (slv_rvalid_w  ),
        .outport_rdata_i   (slv_rdata_w   ),
        .outport_rresp_i   (slv_rresp_w   ),
        .outport_rid_i     (slv_rid_w     ),
        .outport_rlast_i   (slv_rlast_w   ),
    
        // Outputs
        .inport_awready_o  (mst_awready_w ),
        .inport_wready_o   (mst_wready_w  ),
        .inport_bvalid_o   (mst_bvalid_w  ),
        .inport_bresp_o    (mst_bresp_w   ),
        .inport_bid_o      (mst_bid_w     ),
        .inport_arready_o  (mst_arready_w ),
        .inport_rvalid_o   (mst_rvalid_w  ),
        .inport_rdata_o    (mst_rdata_w   ),
        .inport_rresp_o    (mst_rresp_w   ),
        .inport_rid_o      (mst_rid_w     ),
        .inport_rlast_o    (mst_rlast_w   ),
        .outport_awvalid_o (slv_awvalid_w ),
        .outport_awaddr_o  (slv_awaddr_w  ),
        .outport_awid_o    (slv_awid_w    ),
        .outport_awlen_o   (slv_awlen_w   ),
        .outport_awburst_o (slv_awburst_w ),
        .outport_wvalid_o  (slv_wvalid_w  ),
        .outport_wdata_o   (slv_wdata_w   ),
        .outport_wstrb_o   (slv_wstrb_w   ),
        .outport_wlast_o   (slv_wlast_w   ),
        .outport_bready_o  (slv_bready_w  ),
        .outport_arvalid_o (slv_arvalid_w ),
        .outport_araddr_o  (slv_araddr_w  ),
        .outport_arid_o    (slv_arid_w    ),
        .outport_arlen_o   (slv_arlen_w   ),
        .outport_arburst_o (slv_arburst_w ),
        .outport_rready_o  (slv_rready_w  )
    );

    //--------------------------------------------------------------------
    // Device Under Test--SDRAM AXI Top
    //--------------------------------------------------------------------
    wire [ 15:0]  sdram_data_input_w  ;
    wire          sdram_clk_w         ;
    wire          sdram_cke_w         ;
    wire          sdram_cs_w          ;
    wire          sdram_ras_w         ;
    wire          sdram_cas_w         ;
    wire          sdram_we_w          ;
    wire [  1:0]  sdram_dqm_w         ;
    wire [ 12:0]  sdram_addr_w        ;
    wire [  1:0]  sdram_ba_w          ;
    wire [ 15:0]  sdram_data_output_w ;
    wire          sdram_data_out_en_w ;

    sdram_axi u_sdram_axi
    (
        // Inputs
        .clk                 (clk                ),
        .rst_n               (rst_n              ),
        .inport_awvalid_i    (slv_awvalid_w      ),
        .inport_awaddr_i     (slv_awaddr_w       ),
        .inport_awid_i       (slv_awid_w         ),
        .inport_awlen_i      (slv_awlen_w        ),
        .inport_awburst_i    (slv_awburst_w      ),
        .inport_wvalid_i     (slv_wvalid_w       ),
        .inport_wdata_i      (slv_wdata_w        ),
        .inport_wstrb_i      (slv_wstrb_w        ),
        .inport_wlast_i      (slv_wlast_w        ),
        .inport_bready_i     (slv_bready_w       ),
        .inport_arvalid_i    (slv_arvalid_w      ),
        .inport_araddr_i     (slv_araddr_w       ),
        .inport_arid_i       (slv_arid_w         ),
        .inport_arlen_i      (slv_arlen_w        ),
        .inport_arburst_i    (slv_arburst_w      ),
        .inport_rready_i     (slv_rready_w       ),
        .sdram_data_input_i  (sdram_data_input_w ),
    
        // Outputs
        .inport_awready_o    (slv_awready_w      ), 
        .inport_wready_o     (slv_wready_w       ),
        .inport_bvalid_o     (slv_bvalid_w       ),
        .inport_bresp_o      (slv_bresp_w        ),
        .inport_bid_o        (slv_bid_w          ),
        .inport_arready_o    (slv_arready_w      ),
        .inport_rvalid_o     (slv_rvalid_w       ),
        .inport_rdata_o      (slv_rdata_w        ),
        .inport_rresp_o      (slv_rresp_w        ),
        .inport_rid_o        (slv_rid_w          ),
        .inport_rlast_o      (slv_rlast_w        ),
        .sdram_clk_o         (sdram_clk_w        ),
        .sdram_cke_o         (sdram_cke_w        ),
        .sdram_cs_o          (sdram_cs_w         ),
        .sdram_ras_o         (sdram_ras_w        ),
        .sdram_cas_o         (sdram_cas_w        ),
        .sdram_we_o          (sdram_we_w         ),
        .sdram_dqm_o         (sdram_dqm_w        ),
        .sdram_addr_o        (sdram_addr_w       ),
        .sdram_ba_o          (sdram_ba_w         ),
        .sdram_data_output_o (sdram_data_output_w),
        .sdram_data_out_en_o (sdram_data_out_en_w)
    );

    wire [ 15:0]  sdram_data_io_w = (sdram_data_out_en_w == 1'b1) ? sdram_data_output_w : 16'bz;
    assign        sdram_data_input_w = sdram_data_io_w;

    //--------------------------------------------------------------------
    // SDRAM Model
    //--------------------------------------------------------------------
    sdram_model u_sdram_model
    (
        .clk                (clk            ),
        .cke_i              (sdram_cke_w    ),
        .csb_i              (sdram_cs_w     ),
        .rasb_i             (sdram_ras_w    ),
        .casb_i             (sdram_cas_w    ),
        .web_i              (sdram_we_w     ),
        .dqm_i              (sdram_dqm_w    ),
        .addr_i             (sdram_addr_w   ),
        .ba_i               (sdram_ba_w     ),
        .dq_io              (sdram_data_io_w)
    );

endmodule
