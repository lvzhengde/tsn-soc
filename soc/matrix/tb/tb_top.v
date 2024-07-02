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
 * Testbench top level for AXI4 bus matrix (4 master ports / 6 slave ports)
-*/

module tb_top;

    parameter NUM_MST = 4;
    parameter NUM_SLV = 6;

    wire          mst_awvalid_w   [0:NUM_MST-1] ;
    wire [ 31:0]  mst_awaddr_w    [0:NUM_MST-1] ;
    wire [  3:0]  mst_awid_w      [0:NUM_MST-1] ;
    wire [  7:0]  mst_awlen_w     [0:NUM_MST-1] ;
    wire [  1:0]  mst_awburst_w   [0:NUM_MST-1] ;
    wire          mst_wvalid_w    [0:NUM_MST-1] ;
    wire [ 31:0]  mst_wdata_w     [0:NUM_MST-1] ;
    wire [  3:0]  mst_wstrb_w     [0:NUM_MST-1] ;
    wire          mst_wlast_w     [0:NUM_MST-1] ;
    wire          mst_bready_w    [0:NUM_MST-1] ;
    wire          mst_arvalid_w   [0:NUM_MST-1] ;
    wire [ 31:0]  mst_araddr_w    [0:NUM_MST-1] ;
    wire [  3:0]  mst_arid_w      [0:NUM_MST-1] ;
    wire [  7:0]  mst_arlen_w     [0:NUM_MST-1] ;
    wire [  1:0]  mst_arburst_w   [0:NUM_MST-1] ;
    wire          mst_rready_w    [0:NUM_MST-1] ;

    wire          mst_awready_w   [0:NUM_MST-1] ;
    wire          mst_wready_w    [0:NUM_MST-1] ;
    wire          mst_bvalid_w    [0:NUM_MST-1] ;
    wire [  1:0]  mst_bresp_w     [0:NUM_MST-1] ;
    wire [  3:0]  mst_bid_w       [0:NUM_MST-1] ;
    wire          mst_arready_w   [0:NUM_MST-1] ;
    wire          mst_rvalid_w    [0:NUM_MST-1] ;
    wire [ 31:0]  mst_rdata_w     [0:NUM_MST-1] ;
    wire [  1:0]  mst_rresp_w     [0:NUM_MST-1] ;
    wire [  3:0]  mst_rid_w       [0:NUM_MST-1] ;
    wire          mst_rlast_w     [0:NUM_MST-1] ;

    wire          slv_awvalid_w   [0:NUM_SLV-1] ;
    wire [ 31:0]  slv_awaddr_w    [0:NUM_SLV-1] ;
    wire [  3:0]  slv_awid_w      [0:NUM_SLV-1] ;
    wire [  7:0]  slv_awlen_w     [0:NUM_SLV-1] ;
    wire [  1:0]  slv_awburst_w   [0:NUM_SLV-1] ;
    wire          slv_wvalid_w    [0:NUM_SLV-1] ;
    wire [ 31:0]  slv_wdata_w     [0:NUM_SLV-1] ;
    wire [  3:0]  slv_wstrb_w     [0:NUM_SLV-1] ;
    wire          slv_wlast_w     [0:NUM_SLV-1] ;
    wire          slv_bready_w    [0:NUM_SLV-1] ;
    wire          slv_arvalid_w   [0:NUM_SLV-1] ;
    wire [ 31:0]  slv_araddr_w    [0:NUM_SLV-1] ;
    wire [  3:0]  slv_arid_w      [0:NUM_SLV-1] ;
    wire [  7:0]  slv_arlen_w     [0:NUM_SLV-1] ;
    wire [  1:0]  slv_arburst_w   [0:NUM_SLV-1] ;
    wire          slv_rready_w    [0:NUM_SLV-1] ;

    wire          slv_awready_w   [0:NUM_SLV-1] ;
    wire          slv_wready_w    [0:NUM_SLV-1] ;
    wire          slv_bvalid_w    [0:NUM_SLV-1] ;
    wire [  1:0]  slv_bresp_w     [0:NUM_SLV-1] ;
    wire [  3:0]  slv_bid_w       [0:NUM_SLV-1] ;
    wire          slv_arready_w   [0:NUM_SLV-1] ;
    wire          slv_rvalid_w    [0:NUM_SLV-1] ;
    wire [ 31:0]  slv_rdata_w     [0:NUM_SLV-1] ;
    wire [  1:0]  slv_rresp_w     [0:NUM_SLV-1] ;
    wire [  3:0]  slv_rid_w       [0:NUM_SLV-1] ;
    wire          slv_rlast_w     [0:NUM_SLV-1] ;

    // generate clock and reset
    localparam CLK_PERIOD_HALF = 5;  //100MHz clock
    reg     clk   = 1'b0;   always #(CLK_PERIOD_HALF) clk = ~clk;
    reg     rst_n = 1'b0;   //initial #155 rst_n = 1'b1;

    task reset;
    begin
        rst_n    = 0;
        #555 
        rst_n    = 1;
    end
    endtask 

    //-----------------------------------------------------------------
    // AXI bus matrix
    //-----------------------------------------------------------------
    axi4_m4s6 u_axi4_m4s6
    (
        // Inputs
        .clk               (clk  ),
        .rst_n             (rst_n),
    
        .mst0_awvalid_i    (mst_awvalid_w [0]),
        .mst0_awaddr_i     (mst_awaddr_w  [0]),
        .mst0_awid_i       (mst_awid_w    [0]),
        .mst0_awlen_i      (mst_awlen_w   [0]),
        .mst0_awburst_i    (mst_awburst_w [0]),
        .mst0_wvalid_i     (mst_wvalid_w  [0]),
        .mst0_wdata_i      (mst_wdata_w   [0]),
        .mst0_wstrb_i      (mst_wstrb_w   [0]),
        .mst0_wlast_i      (mst_wlast_w   [0]),
        .mst0_bready_i     (mst_bready_w  [0]),
        .mst0_arvalid_i    (mst_arvalid_w [0]),
        .mst0_araddr_i     (mst_araddr_w  [0]),
        .mst0_arid_i       (mst_arid_w    [0]),
        .mst0_arlen_i      (mst_arlen_w   [0]),
        .mst0_arburst_i    (mst_arburst_w [0]),
        .mst0_rready_i     (mst_rready_w  [0]),
    
        .mst1_awvalid_i    (mst_awvalid_w [1]),
        .mst1_awaddr_i     (mst_awaddr_w  [1]),
        .mst1_awid_i       (mst_awid_w    [1]),
        .mst1_awlen_i      (mst_awlen_w   [1]),
        .mst1_awburst_i    (mst_awburst_w [1]),
        .mst1_wvalid_i     (mst_wvalid_w  [1]),
        .mst1_wdata_i      (mst_wdata_w   [1]),
        .mst1_wstrb_i      (mst_wstrb_w   [1]),
        .mst1_wlast_i      (mst_wlast_w   [1]),
        .mst1_bready_i     (mst_bready_w  [1]),
        .mst1_arvalid_i    (mst_arvalid_w [1]),
        .mst1_araddr_i     (mst_araddr_w  [1]),
        .mst1_arid_i       (mst_arid_w    [1]),
        .mst1_arlen_i      (mst_arlen_w   [1]),
        .mst1_arburst_i    (mst_arburst_w [1]),
        .mst1_rready_i     (mst_rready_w  [1]),
    
        .mst2_awvalid_i    (mst_awvalid_w [2]),
        .mst2_awaddr_i     (mst_awaddr_w  [2]),
        .mst2_awid_i       (mst_awid_w    [2]),
        .mst2_awlen_i      (mst_awlen_w   [2]),
        .mst2_awburst_i    (mst_awburst_w [2]),
        .mst2_wvalid_i     (mst_wvalid_w  [2]),
        .mst2_wdata_i      (mst_wdata_w   [2]),
        .mst2_wstrb_i      (mst_wstrb_w   [2]),
        .mst2_wlast_i      (mst_wlast_w   [2]),
        .mst2_bready_i     (mst_bready_w  [2]),
        .mst2_arvalid_i    (mst_arvalid_w [2]),
        .mst2_araddr_i     (mst_araddr_w  [2]),
        .mst2_arid_i       (mst_arid_w    [2]),
        .mst2_arlen_i      (mst_arlen_w   [2]),
        .mst2_arburst_i    (mst_arburst_w [2]),
        .mst2_rready_i     (mst_rready_w  [2]),
    
        .mst3_awvalid_i    (mst_awvalid_w [3]),
        .mst3_awaddr_i     (mst_awaddr_w  [3]),
        .mst3_awid_i       (mst_awid_w    [3]),
        .mst3_awlen_i      (mst_awlen_w   [3]),
        .mst3_awburst_i    (mst_awburst_w [3]),
        .mst3_wvalid_i     (mst_wvalid_w  [3]),
        .mst3_wdata_i      (mst_wdata_w   [3]),
        .mst3_wstrb_i      (mst_wstrb_w   [3]),
        .mst3_wlast_i      (mst_wlast_w   [3]),
        .mst3_bready_i     (mst_bready_w  [3]),
        .mst3_arvalid_i    (mst_arvalid_w [3]),
        .mst3_araddr_i     (mst_araddr_w  [3]),
        .mst3_arid_i       (mst_arid_w    [3]),
        .mst3_arlen_i      (mst_arlen_w   [3]),
        .mst3_arburst_i    (mst_arburst_w [3]),
        .mst3_rready_i     (mst_rready_w  [3]),
    
        .slv0_awready_i    (slv_awready_w [0]),
        .slv0_wready_i     (slv_wready_w  [0]),
        .slv0_bvalid_i     (slv_bvalid_w  [0]),
        .slv0_bresp_i      (slv_bresp_w   [0]),
        .slv0_bid_i        (slv_bid_w     [0]),
        .slv0_arready_i    (slv_arready_w [0]),
        .slv0_rvalid_i     (slv_rvalid_w  [0]),
        .slv0_rdata_i      (slv_rdata_w   [0]),
        .slv0_rresp_i      (slv_rresp_w   [0]),
        .slv0_rid_i        (slv_rid_w     [0]),
        .slv0_rlast_i      (slv_rlast_w   [0]),
    
        .slv1_awready_i    (slv_awready_w [1]),
        .slv1_wready_i     (slv_wready_w  [1]),
        .slv1_bvalid_i     (slv_bvalid_w  [1]),
        .slv1_bresp_i      (slv_bresp_w   [1]),
        .slv1_bid_i        (slv_bid_w     [1]),
        .slv1_arready_i    (slv_arready_w [1]),
        .slv1_rvalid_i     (slv_rvalid_w  [1]),
        .slv1_rdata_i      (slv_rdata_w   [1]),
        .slv1_rresp_i      (slv_rresp_w   [1]),
        .slv1_rid_i        (slv_rid_w     [1]),
        .slv1_rlast_i      (slv_rlast_w   [1]),
    
        .slv2_awready_i    (slv_awready_w [2]),
        .slv2_wready_i     (slv_wready_w  [2]),
        .slv2_bvalid_i     (slv_bvalid_w  [2]),
        .slv2_bresp_i      (slv_bresp_w   [2]),
        .slv2_bid_i        (slv_bid_w     [2]),
        .slv2_arready_i    (slv_arready_w [2]),
        .slv2_rvalid_i     (slv_rvalid_w  [2]),
        .slv2_rdata_i      (slv_rdata_w   [2]),
        .slv2_rresp_i      (slv_rresp_w   [2]),
        .slv2_rid_i        (slv_rid_w     [2]),
        .slv2_rlast_i      (slv_rlast_w   [2]),
    
        .slv3_awready_i    (slv_awready_w [3]),
        .slv3_wready_i     (slv_wready_w  [3]),
        .slv3_bvalid_i     (slv_bvalid_w  [3]),
        .slv3_bresp_i      (slv_bresp_w   [3]),
        .slv3_bid_i        (slv_bid_w     [3]),
        .slv3_arready_i    (slv_arready_w [3]),
        .slv3_rvalid_i     (slv_rvalid_w  [3]),
        .slv3_rdata_i      (slv_rdata_w   [3]),
        .slv3_rresp_i      (slv_rresp_w   [3]),
        .slv3_rid_i        (slv_rid_w     [3]),
        .slv3_rlast_i      (slv_rlast_w   [3]),
    
        .slv4_awready_i    (slv_awready_w [4]),
        .slv4_wready_i     (slv_wready_w  [4]),
        .slv4_bvalid_i     (slv_bvalid_w  [4]),
        .slv4_bresp_i      (slv_bresp_w   [4]),
        .slv4_bid_i        (slv_bid_w     [4]),
        .slv4_arready_i    (slv_arready_w [4]),
        .slv4_rvalid_i     (slv_rvalid_w  [4]),
        .slv4_rdata_i      (slv_rdata_w   [4]),
        .slv4_rresp_i      (slv_rresp_w   [4]),
        .slv4_rid_i        (slv_rid_w     [4]),
        .slv4_rlast_i      (slv_rlast_w   [4]),
    
        .slv5_awready_i    (slv_awready_w [5]),
        .slv5_wready_i     (slv_wready_w  [5]),
        .slv5_bvalid_i     (slv_bvalid_w  [5]),
        .slv5_bresp_i      (slv_bresp_w   [5]),
        .slv5_bid_i        (slv_bid_w     [5]),
        .slv5_arready_i    (slv_arready_w [5]),
        .slv5_rvalid_i     (slv_rvalid_w  [5]),
        .slv5_rdata_i      (slv_rdata_w   [5]),
        .slv5_rresp_i      (slv_rresp_w   [5]),
        .slv5_rid_i        (slv_rid_w     [5]),
        .slv5_rlast_i      (slv_rlast_w   [5]),
    
        // Outputs
        .mst0_awready_o    (mst_awready_w [0]),
        .mst0_wready_o     (mst_wready_w  [0]),
        .mst0_bvalid_o     (mst_bvalid_w  [0]),
        .mst0_bresp_o      (mst_bresp_w   [0]),
        .mst0_bid_o        (mst_bid_w     [0]),
        .mst0_arready_o    (mst_arready_w [0]),
        .mst0_rvalid_o     (mst_rvalid_w  [0]),
        .mst0_rdata_o      (mst_rdata_w   [0]),
        .mst0_rresp_o      (mst_rresp_w   [0]),
        .mst0_rid_o        (mst_rid_w     [0]),
        .mst0_rlast_o      (mst_rlast_w   [0]),
    
        .mst1_awready_o    (mst_awready_w [1]),
        .mst1_wready_o     (mst_wready_w  [1]),
        .mst1_bvalid_o     (mst_bvalid_w  [1]),
        .mst1_bresp_o      (mst_bresp_w   [1]),
        .mst1_bid_o        (mst_bid_w     [1]),
        .mst1_arready_o    (mst_arready_w [1]),
        .mst1_rvalid_o     (mst_rvalid_w  [1]),
        .mst1_rdata_o      (mst_rdata_w   [1]),
        .mst1_rresp_o      (mst_rresp_w   [1]),
        .mst1_rid_o        (mst_rid_w     [1]),
        .mst1_rlast_o      (mst_rlast_w   [1]),
    
        .mst2_awready_o    (mst_awready_w [2]),
        .mst2_wready_o     (mst_wready_w  [2]),
        .mst2_bvalid_o     (mst_bvalid_w  [2]),
        .mst2_bresp_o      (mst_bresp_w   [2]),
        .mst2_bid_o        (mst_bid_w     [2]),
        .mst2_arready_o    (mst_arready_w [2]),
        .mst2_rvalid_o     (mst_rvalid_w  [2]),
        .mst2_rdata_o      (mst_rdata_w   [2]),
        .mst2_rresp_o      (mst_rresp_w   [2]),
        .mst2_rid_o        (mst_rid_w     [2]),
        .mst2_rlast_o      (mst_rlast_w   [2]),
    
        .mst3_awready_o    (mst_awready_w [3]),
        .mst3_wready_o     (mst_wready_w  [3]),
        .mst3_bvalid_o     (mst_bvalid_w  [3]),
        .mst3_bresp_o      (mst_bresp_w   [3]),
        .mst3_bid_o        (mst_bid_w     [3]),
        .mst3_arready_o    (mst_arready_w [3]),
        .mst3_rvalid_o     (mst_rvalid_w  [3]),
        .mst3_rdata_o      (mst_rdata_w   [3]),
        .mst3_rresp_o      (mst_rresp_w   [3]),
        .mst3_rid_o        (mst_rid_w     [3]),
        .mst3_rlast_o      (mst_rlast_w   [3]),
    
        .slv0_awvalid_o    (slv_awvalid_w [0]),
        .slv0_awaddr_o     (slv_awaddr_w  [0]),
        .slv0_awid_o       (slv_awid_w    [0]),
        .slv0_awlen_o      (slv_awlen_w   [0]),
        .slv0_awburst_o    (slv_awburst_w [0]),
        .slv0_wvalid_o     (slv_wvalid_w  [0]),
        .slv0_wdata_o      (slv_wdata_w   [0]),
        .slv0_wstrb_o      (slv_wstrb_w   [0]),
        .slv0_wlast_o      (slv_wlast_w   [0]),
        .slv0_bready_o     (slv_bready_w  [0]),
        .slv0_arvalid_o    (slv_arvalid_w [0]),
        .slv0_araddr_o     (slv_araddr_w  [0]),
        .slv0_arid_o       (slv_arid_w    [0]),
        .slv0_arlen_o      (slv_arlen_w   [0]),
        .slv0_arburst_o    (slv_arburst_w [0]),
        .slv0_rready_o     (slv_rready_w  [0]),
    
        .slv1_awvalid_o    (slv_awvalid_w [1]),
        .slv1_awaddr_o     (slv_awaddr_w  [1]),
        .slv1_awid_o       (slv_awid_w    [1]),
        .slv1_awlen_o      (slv_awlen_w   [1]),
        .slv1_awburst_o    (slv_awburst_w [1]),
        .slv1_wvalid_o     (slv_wvalid_w  [1]),
        .slv1_wdata_o      (slv_wdata_w   [1]),
        .slv1_wstrb_o      (slv_wstrb_w   [1]),
        .slv1_wlast_o      (slv_wlast_w   [1]),
        .slv1_bready_o     (slv_bready_w  [1]),
        .slv1_arvalid_o    (slv_arvalid_w [1]),
        .slv1_araddr_o     (slv_araddr_w  [1]),
        .slv1_arid_o       (slv_arid_w    [1]),
        .slv1_arlen_o      (slv_arlen_w   [1]),
        .slv1_arburst_o    (slv_arburst_w [1]),
        .slv1_rready_o     (slv_rready_w  [1]),
    
        .slv2_awvalid_o    (slv_awvalid_w [2]),
        .slv2_awaddr_o     (slv_awaddr_w  [2]),
        .slv2_awid_o       (slv_awid_w    [2]),
        .slv2_awlen_o      (slv_awlen_w   [2]),
        .slv2_awburst_o    (slv_awburst_w [2]),
        .slv2_wvalid_o     (slv_wvalid_w  [2]),
        .slv2_wdata_o      (slv_wdata_w   [2]),
        .slv2_wstrb_o      (slv_wstrb_w   [2]),
        .slv2_wlast_o      (slv_wlast_w   [2]),
        .slv2_bready_o     (slv_bready_w  [2]),
        .slv2_arvalid_o    (slv_arvalid_w [2]),
        .slv2_araddr_o     (slv_araddr_w  [2]),
        .slv2_arid_o       (slv_arid_w    [2]),
        .slv2_arlen_o      (slv_arlen_w   [2]),
        .slv2_arburst_o    (slv_arburst_w [2]),
        .slv2_rready_o     (slv_rready_w  [2]),
    
        .slv3_awvalid_o    (slv_awvalid_w [3]),
        .slv3_awaddr_o     (slv_awaddr_w  [3]),
        .slv3_awid_o       (slv_awid_w    [3]),
        .slv3_awlen_o      (slv_awlen_w   [3]),
        .slv3_awburst_o    (slv_awburst_w [3]),
        .slv3_wvalid_o     (slv_wvalid_w  [3]),
        .slv3_wdata_o      (slv_wdata_w   [3]),
        .slv3_wstrb_o      (slv_wstrb_w   [3]),
        .slv3_wlast_o      (slv_wlast_w   [3]),
        .slv3_bready_o     (slv_bready_w  [3]),
        .slv3_arvalid_o    (slv_arvalid_w [3]),
        .slv3_araddr_o     (slv_araddr_w  [3]),
        .slv3_arid_o       (slv_arid_w    [3]),
        .slv3_arlen_o      (slv_arlen_w   [3]),
        .slv3_arburst_o    (slv_arburst_w [3]),
        .slv3_rready_o     (slv_rready_w  [3]),
    
        .slv4_awvalid_o    (slv_awvalid_w [4]),
        .slv4_awaddr_o     (slv_awaddr_w  [4]),
        .slv4_awid_o       (slv_awid_w    [4]),
        .slv4_awlen_o      (slv_awlen_w   [4]),
        .slv4_awburst_o    (slv_awburst_w [4]),
        .slv4_wvalid_o     (slv_wvalid_w  [4]),
        .slv4_wdata_o      (slv_wdata_w   [4]),
        .slv4_wstrb_o      (slv_wstrb_w   [4]),
        .slv4_wlast_o      (slv_wlast_w   [4]),
        .slv4_bready_o     (slv_bready_w  [4]),
        .slv4_arvalid_o    (slv_arvalid_w [4]),
        .slv4_araddr_o     (slv_araddr_w  [4]),
        .slv4_arid_o       (slv_arid_w    [4]),
        .slv4_arlen_o      (slv_arlen_w   [4]),
        .slv4_arburst_o    (slv_arburst_w [4]),
        .slv4_rready_o     (slv_rready_w  [4]),
    
        .slv5_awvalid_o    (slv_awvalid_w [5]),
        .slv5_awaddr_o     (slv_awaddr_w  [5]),
        .slv5_awid_o       (slv_awid_w    [5]),
        .slv5_awlen_o      (slv_awlen_w   [5]),
        .slv5_awburst_o    (slv_awburst_w [5]),
        .slv5_wvalid_o     (slv_wvalid_w  [5]),
        .slv5_wdata_o      (slv_wdata_w   [5]),
        .slv5_wstrb_o      (slv_wstrb_w   [5]),
        .slv5_wlast_o      (slv_wlast_w   [5]),
        .slv5_bready_o     (slv_bready_w  [5]),
        .slv5_arvalid_o    (slv_arvalid_w [5]),
        .slv5_araddr_o     (slv_araddr_w  [5]),
        .slv5_arid_o       (slv_arid_w    [5]),
        .slv5_arlen_o      (slv_arlen_w   [5]),
        .slv5_arburst_o    (slv_arburst_w [5]),
        .slv5_rready_o     (slv_rready_w  [5])
    );


    //-----------------------------------------------------------------
    // AXI4 bus masters
    //-----------------------------------------------------------------
    wire [NUM_MST-1:0]      done;
    wire [NUM_MST-1:0]      busy_out;
    wire                    busy_in = |busy_out;

    generate
    genvar idx;

    for (idx = 0; idx < NUM_MST; idx = idx + 1) begin : BLK_MST
        axi4_master 
        #(
            .ID    (idx) 
        )
        u_axi4_master
        (
            .clk             (clk    ),
            .rst_n           (rst_n  ),
        
            .axi_awready_i   (mst_awready_w [idx]),
            .axi_wready_i    (mst_wready_w  [idx]),
            .axi_bvalid_i    (mst_bvalid_w  [idx]),
            .axi_bresp_i     (mst_bresp_w   [idx]),
            .axi_bid_i       (mst_bid_w     [idx]),
            .axi_arready_i   (mst_arready_w [idx]),
            .axi_rvalid_i    (mst_rvalid_w  [idx]),
            .axi_rdata_i     (mst_rdata_w   [idx]),
            .axi_rresp_i     (mst_rresp_w   [idx]),
            .axi_rid_i       (mst_rid_w     [idx]),
            .axi_rlast_i     (mst_rlast_w   [idx]),
        
            .axi_awvalid_o   (mst_awvalid_w [idx]),
            .axi_awaddr_o    (mst_awaddr_w  [idx]),
            .axi_awid_o      (mst_awid_w    [idx]),
            .axi_awlen_o     (mst_awlen_w   [idx]),
            .axi_awburst_o   (mst_awburst_w [idx]),
            .axi_wvalid_o    (mst_wvalid_w  [idx]),
            .axi_wdata_o     (mst_wdata_w   [idx]),
            .axi_wstrb_o     (mst_wstrb_w   [idx]),
            .axi_wlast_o     (mst_wlast_w   [idx]),
            .axi_bready_o    (mst_bready_w  [idx]),
            .axi_arvalid_o   (mst_arvalid_w [idx]),
            .axi_araddr_o    (mst_araddr_w  [idx]),
            .axi_arid_o      (mst_arid_w    [idx]),
            .axi_arlen_o     (mst_arlen_w   [idx]),
            .axi_arburst_o   (mst_arburst_w [idx]),
            .axi_rready_o    (mst_rready_w  [idx]),
        
            .busy_i          (busy_in      ),
            .busy_o          (busy_out[idx])  
        );
        
        assign done[idx] = BLK_MST[idx].u_axi4_master.done;
    end // for
    endgenerate


    //-----------------------------------------------------------------
    // re-timing slave port 0 then connect to mem_axi4_0
    //-----------------------------------------------------------------
    wire          slv0_awvalid_w ;
    wire [ 31:0]  slv0_awaddr_w  ;
    wire [  3:0]  slv0_awid_w    ;
    wire [  7:0]  slv0_awlen_w   ;
    wire [  1:0]  slv0_awburst_w ;
    wire          slv0_wvalid_w  ;
    wire [ 31:0]  slv0_wdata_w   ;
    wire [  3:0]  slv0_wstrb_w   ;
    wire          slv0_wlast_w   ;
    wire          slv0_bready_w  ;
    wire          slv0_arvalid_w ;
    wire [ 31:0]  slv0_araddr_w  ;
    wire [  3:0]  slv0_arid_w    ;
    wire [  7:0]  slv0_arlen_w   ;
    wire [  1:0]  slv0_arburst_w ;
    wire          slv0_rready_w  ;

    wire          slv0_awready_w ;
    wire          slv0_wready_w  ;
    wire          slv0_bvalid_w  ;
    wire [  1:0]  slv0_bresp_w   ;
    wire [  3:0]  slv0_bid_w     ;
    wire          slv0_arready_w ;
    wire          slv0_rvalid_w  ;
    wire [ 31:0]  slv0_rdata_w   ;
    wire [  1:0]  slv0_rresp_w   ;
    wire [  3:0]  slv0_rid_w     ;
    wire          slv0_rlast_w   ;

    axi4_retime u_axi4_retime
    (
        // Inputs
        .clk               (clk    ),
        .rst_n             (rst_n  ),
        .inport_awvalid_i  (slv_awvalid_w [0]),
        .inport_awaddr_i   (slv_awaddr_w  [0]),
        .inport_awid_i     (slv_awid_w    [0]),
        .inport_awlen_i    (slv_awlen_w   [0]),
        .inport_awburst_i  (slv_awburst_w [0]),
        .inport_wvalid_i   (slv_wvalid_w  [0]),
        .inport_wdata_i    (slv_wdata_w   [0]),
        .inport_wstrb_i    (slv_wstrb_w   [0]),
        .inport_wlast_i    (slv_wlast_w   [0]),
        .inport_bready_i   (slv_bready_w  [0]),
        .inport_arvalid_i  (slv_arvalid_w [0]),
        .inport_araddr_i   (slv_araddr_w  [0]),
        .inport_arid_i     (slv_arid_w    [0]),
        .inport_arlen_i    (slv_arlen_w   [0]),
        .inport_arburst_i  (slv_arburst_w [0]),
        .inport_rready_i   (slv_rready_w  [0]),
        .outport_awready_i (slv0_awready_w),
        .outport_wready_i  (slv0_wready_w ),
        .outport_bvalid_i  (slv0_bvalid_w ),
        .outport_bresp_i   (slv0_bresp_w  ),
        .outport_bid_i     (slv0_bid_w    ),
        .outport_arready_i (slv0_arready_w),
        .outport_rvalid_i  (slv0_rvalid_w ),
        .outport_rdata_i   (slv0_rdata_w  ),
        .outport_rresp_i   (slv0_rresp_w  ),
        .outport_rid_i     (slv0_rid_w    ),
        .outport_rlast_i   (slv0_rlast_w  ),
    
        // Outputs
        .inport_awready_o  (slv_awready_w [0]),
        .inport_wready_o   (slv_wready_w  [0]),
        .inport_bvalid_o   (slv_bvalid_w  [0]),
        .inport_bresp_o    (slv_bresp_w   [0]),
        .inport_bid_o      (slv_bid_w     [0]),
        .inport_arready_o  (slv_arready_w [0]),
        .inport_rvalid_o   (slv_rvalid_w  [0]),
        .inport_rdata_o    (slv_rdata_w   [0]),
        .inport_rresp_o    (slv_rresp_w   [0]),
        .inport_rid_o      (slv_rid_w     [0]),
        .inport_rlast_o    (slv_rlast_w   [0]),
        .outport_awvalid_o (slv0_awvalid_w),
        .outport_awaddr_o  (slv0_awaddr_w ),
        .outport_awid_o    (slv0_awid_w   ),
        .outport_awlen_o   (slv0_awlen_w  ),
        .outport_awburst_o (slv0_awburst_w),
        .outport_wvalid_o  (slv0_wvalid_w ),
        .outport_wdata_o   (slv0_wdata_w  ),
        .outport_wstrb_o   (slv0_wstrb_w  ),
        .outport_wlast_o   (slv0_wlast_w  ),
        .outport_bready_o  (slv0_bready_w ),
        .outport_arvalid_o (slv0_arvalid_w),
        .outport_araddr_o  (slv0_araddr_w ),
        .outport_arid_o    (slv0_arid_w   ),
        .outport_arlen_o   (slv0_arlen_w  ),
        .outport_arburst_o (slv0_arburst_w),
        .outport_rready_o  (slv0_rready_w )
    );

    mem_axi4
    #(
        .SIZE_IN_BYTES      (1024), 
        .ID                 (0   ) 
    )
    u_mem_axi4_0
    (
        .clk             (clk    ),
        .rst_n           (rst_n  ),
    
        // AXI4 interface
        .axi_awvalid_i   (slv0_awvalid_w),
        .axi_awaddr_i    (slv0_awaddr_w ),
        .axi_awid_i      (slv0_awid_w   ),
        .axi_awlen_i     (slv0_awlen_w  ),
        .axi_awburst_i   (slv0_awburst_w),
        .axi_wvalid_i    (slv0_wvalid_w ),
        .axi_wdata_i     (slv0_wdata_w  ),
        .axi_wstrb_i     (slv0_wstrb_w  ),
        .axi_wlast_i     (slv0_wlast_w  ),
        .axi_bready_i    (slv0_bready_w ),
        .axi_arvalid_i   (slv0_arvalid_w),
        .axi_araddr_i    (slv0_araddr_w ),
        .axi_arid_i      (slv0_arid_w   ),
        .axi_arlen_i     (slv0_arlen_w  ),
        .axi_arburst_i   (slv0_arburst_w),
        .axi_rready_i    (slv0_rready_w ),
    
        .axi_awready_o   (slv0_awready_w),
        .axi_wready_o    (slv0_wready_w ),
        .axi_bvalid_o    (slv0_bvalid_w ),
        .axi_bresp_o     (slv0_bresp_w  ),
        .axi_bid_o       (slv0_bid_w    ),
        .axi_arready_o   (slv0_arready_w),
        .axi_rvalid_o    (slv0_rvalid_w ),
        .axi_rdata_o     (slv0_rdata_w  ),
        .axi_rresp_o     (slv0_rresp_w  ),
        .axi_rid_o       (slv0_rid_w    ),
        .axi_rlast_o     (slv0_rlast_w  ),
    
        .csysreq_i       (&done),
        .csysack_o       (     ),
        .cactive_o       (     )
    );


    //-----------------------------------------------------------------
    // slave port 1-4 connected to ordinary mem_axi4 (1-4)
    //-----------------------------------------------------------------
    generate
    genvar idy;

    for (idy = 1; idy < NUM_SLV-1; idy = idy+1) begin : BLK_SLV
        mem_axi4
        #(
            .SIZE_IN_BYTES      (1024), 
            .ID                 (idy ) 
        )
        u_mem_axi4
        (
            .clk             (clk    ),
            .rst_n           (rst_n  ),
        
            // AXI4 interface
            .axi_awvalid_i   (slv_awvalid_w [idy]),
            .axi_awaddr_i    (slv_awaddr_w  [idy]),
            .axi_awid_i      (slv_awid_w    [idy]),
            .axi_awlen_i     (slv_awlen_w   [idy]),
            .axi_awburst_i   (slv_awburst_w [idy]),
            .axi_wvalid_i    (slv_wvalid_w  [idy]),
            .axi_wdata_i     (slv_wdata_w   [idy]),
            .axi_wstrb_i     (slv_wstrb_w   [idy]),
            .axi_wlast_i     (slv_wlast_w   [idy]),
            .axi_bready_i    (slv_bready_w  [idy]),
            .axi_arvalid_i   (slv_arvalid_w [idy]),
            .axi_araddr_i    (slv_araddr_w  [idy]),
            .axi_arid_i      (slv_arid_w    [idy]),
            .axi_arlen_i     (slv_arlen_w   [idy]),
            .axi_arburst_i   (slv_arburst_w [idy]),
            .axi_rready_i    (slv_rready_w  [idy]),
        
            .axi_awready_o   (slv_awready_w [idy]),
            .axi_wready_o    (slv_wready_w  [idy]),
            .axi_bvalid_o    (slv_bvalid_w  [idy]),
            .axi_bresp_o     (slv_bresp_w   [idy]),
            .axi_bid_o       (slv_bid_w     [idy]),
            .axi_arready_o   (slv_arready_w [idy]),
            .axi_rvalid_o    (slv_rvalid_w  [idy]),
            .axi_rdata_o     (slv_rdata_w   [idy]),
            .axi_rresp_o     (slv_rresp_w   [idy]),
            .axi_rid_o       (slv_rid_w     [idy]),
            .axi_rlast_o     (slv_rlast_w   [idy]),
        
            .csysreq_i       (&done),
            .csysack_o       (     ),
            .cactive_o       (     )
        );
    end // for
    endgenerate


    //-----------------------------------------------------------------
    // slave port 5 connected to IPBus bridge/ipbus_slave_mem
    //-----------------------------------------------------------------
    wire          bus2ip_clk      ;
    wire          bus2ip_rst_n    ;
    wire [ 31:0]  bus2ip_addr_w   ;
    wire [ 31:0]  bus2ip_data_w   ;
    wire          bus2ip_rd_ce_w  ;  
    wire          bus2ip_wr_ce_w  ;  
    wire [ 31:0]  ip2bus_data_w   ;   

    axi4_ipbus_bridge u_ipbus_bridge
    (
        .clk             (clk   ),
        .rst_n           (rst_n ),
    
        // AXI4 interface
        .axi_awvalid_i   (slv_awvalid_w [5]),
        .axi_awaddr_i    (slv_awaddr_w  [5]),
        .axi_awid_i      (slv_awid_w    [5]),
        .axi_awlen_i     (slv_awlen_w   [5]),
        .axi_awburst_i   (slv_awburst_w [5]),
        .axi_wvalid_i    (slv_wvalid_w  [5]),
        .axi_wdata_i     (slv_wdata_w   [5]),
        .axi_wstrb_i     (slv_wstrb_w   [5]),
        .axi_wlast_i     (slv_wlast_w   [5]),
        .axi_bready_i    (slv_bready_w  [5]),
        .axi_arvalid_i   (slv_arvalid_w [5]),
        .axi_araddr_i    (slv_araddr_w  [5]),
        .axi_arid_i      (slv_arid_w    [5]),
        .axi_arlen_i     (slv_arlen_w   [5]),
        .axi_arburst_i   (slv_arburst_w [5]),
        .axi_rready_i    (slv_rready_w  [5]),
    
        .axi_awready_o   (slv_awready_w [5]),
        .axi_wready_o    (slv_wready_w  [5]),
        .axi_bvalid_o    (slv_bvalid_w  [5]),
        .axi_bresp_o     (slv_bresp_w   [5]),
        .axi_bid_o       (slv_bid_w     [5]),
        .axi_arready_o   (slv_arready_w [5]),
        .axi_rvalid_o    (slv_rvalid_w  [5]),
        .axi_rdata_o     (slv_rdata_w   [5]),
        .axi_rresp_o     (slv_rresp_w   [5]),
        .axi_rid_o       (slv_rid_w     [5]),
        .axi_rlast_o     (slv_rlast_w   [5]),
    
        //standard ip access bus interface
        .bus2ip_clk      (bus2ip_clk     ),
        .bus2ip_rst_n    (bus2ip_rst_n   ),
        .bus2ip_addr_o   (bus2ip_addr_w  ),
        .bus2ip_data_o   (bus2ip_data_w  ),
        .bus2ip_rd_ce_o  (bus2ip_rd_ce_w ),  
        .bus2ip_wr_ce_o  (bus2ip_wr_ce_w ),  
        .ip2bus_data_i   (ip2bus_data_w  )    
    );

    ipbus_mem_slave 
    #(
        .SIZE_IN_BYTES   (1024 ), 
        .BLOCK_ID        (8'h94)
    )
    u_ipbus_mem_slave
    (
        .bus2ip_clk      (bus2ip_clk     ),         
        .bus2ip_rst_n    (bus2ip_rst_n   ),        
        .bus2ip_addr_i   (bus2ip_addr_w  ),
        .bus2ip_data_i   (bus2ip_data_w  ),
        .bus2ip_rd_ce_i  (bus2ip_rd_ce_w ),       
        .bus2ip_wr_ce_i  (bus2ip_wr_ce_w ),      
        .ip2bus_data_o   (ip2bus_data_w  ) 
    );

endmodule
