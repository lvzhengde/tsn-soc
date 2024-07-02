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

module axi4_tap
(
    // Inputs
    input           clk                        ,
    input           rst_n                      ,

    input           mst_awvalid_i              ,
    input  [ 31:0]  mst_awaddr_i               ,
    input  [  3:0]  mst_awid_i                 ,
    input  [  7:0]  mst_awlen_i                ,
    input  [  1:0]  mst_awburst_i              ,
    input           mst_wvalid_i               ,
    input  [ 31:0]  mst_wdata_i                ,
    input  [  3:0]  mst_wstrb_i                ,
    input           mst_wlast_i                ,
    input           mst_bready_i               ,
    input           mst_arvalid_i              ,
    input  [ 31:0]  mst_araddr_i               ,
    input  [  3:0]  mst_arid_i                 ,
    input  [  7:0]  mst_arlen_i                ,
    input  [  1:0]  mst_arburst_i              ,
    input           mst_rready_i               ,

    input           slv0_awready_i             ,
    input           slv0_wready_i              ,
    input           slv0_bvalid_i              ,
    input  [  1:0]  slv0_bresp_i               ,
    input  [  3:0]  slv0_bid_i                 ,
    input           slv0_arready_i             ,
    input           slv0_rvalid_i              ,
    input  [ 31:0]  slv0_rdata_i               ,
    input  [  1:0]  slv0_rresp_i               ,
    input  [  3:0]  slv0_rid_i                 ,
    input           slv0_rlast_i               ,

    input           slv1_awready_i             ,
    input           slv1_wready_i              ,
    input           slv1_bvalid_i              ,
    input  [  1:0]  slv1_bresp_i               ,
    input  [  3:0]  slv1_bid_i                 ,
    input           slv1_arready_i             ,
    input           slv1_rvalid_i              ,
    input  [ 31:0]  slv1_rdata_i               ,
    input  [  1:0]  slv1_rresp_i               ,
    input  [  3:0]  slv1_rid_i                 ,
    input           slv1_rlast_i               ,

    input           slv2_awready_i             ,
    input           slv2_wready_i              ,
    input           slv2_bvalid_i              ,
    input  [  1:0]  slv2_bresp_i               ,
    input  [  3:0]  slv2_bid_i                 ,
    input           slv2_arready_i             ,
    input           slv2_rvalid_i              ,
    input  [ 31:0]  slv2_rdata_i               ,
    input  [  1:0]  slv2_rresp_i               ,
    input  [  3:0]  slv2_rid_i                 ,
    input           slv2_rlast_i               ,

    input           slv3_awready_i             ,
    input           slv3_wready_i              ,
    input           slv3_bvalid_i              ,
    input  [  1:0]  slv3_bresp_i               ,
    input  [  3:0]  slv3_bid_i                 ,
    input           slv3_arready_i             ,
    input           slv3_rvalid_i              ,
    input  [ 31:0]  slv3_rdata_i               ,
    input  [  1:0]  slv3_rresp_i               ,
    input  [  3:0]  slv3_rid_i                 ,
    input           slv3_rlast_i               ,

    input           slv4_awready_i             ,
    input           slv4_wready_i              ,
    input           slv4_bvalid_i              ,
    input  [  1:0]  slv4_bresp_i               ,
    input  [  3:0]  slv4_bid_i                 ,
    input           slv4_arready_i             ,
    input           slv4_rvalid_i              ,
    input  [ 31:0]  slv4_rdata_i               ,
    input  [  1:0]  slv4_rresp_i               ,
    input  [  3:0]  slv4_rid_i                 ,
    input           slv4_rlast_i               ,

    input           slv5_awready_i             ,
    input           slv5_wready_i              ,
    input           slv5_bvalid_i              ,
    input  [  1:0]  slv5_bresp_i               ,
    input  [  3:0]  slv5_bid_i                 ,
    input           slv5_arready_i             ,
    input           slv5_rvalid_i              ,
    input  [ 31:0]  slv5_rdata_i               ,
    input  [  1:0]  slv5_rresp_i               ,
    input  [  3:0]  slv5_rid_i                 ,
    input           slv5_rlast_i               ,

    // Outputs
    output          mst_awready_o              ,
    output          mst_wready_o               ,
    output          mst_bvalid_o               ,
    output [  1:0]  mst_bresp_o                ,
    output [  3:0]  mst_bid_o                  ,
    output          mst_arready_o              ,
    output          mst_rvalid_o               ,
    output [ 31:0]  mst_rdata_o                ,
    output [  1:0]  mst_rresp_o                ,
    output [  3:0]  mst_rid_o                  ,
    output          mst_rlast_o                ,

    output          slv0_awvalid_o             ,
    output [ 31:0]  slv0_awaddr_o              ,
    output [  3:0]  slv0_awid_o                ,
    output [  7:0]  slv0_awlen_o               ,
    output [  1:0]  slv0_awburst_o             ,
    output          slv0_wvalid_o              ,
    output [ 31:0]  slv0_wdata_o               ,
    output [  3:0]  slv0_wstrb_o               ,
    output          slv0_wlast_o               ,
    output          slv0_bready_o              ,
    output          slv0_arvalid_o             ,
    output [ 31:0]  slv0_araddr_o              ,
    output [  3:0]  slv0_arid_o                ,
    output [  7:0]  slv0_arlen_o               ,
    output [  1:0]  slv0_arburst_o             ,
    output          slv0_rready_o              ,

    output          slv1_awvalid_o             ,
    output [ 31:0]  slv1_awaddr_o              ,
    output [  3:0]  slv1_awid_o                ,
    output [  7:0]  slv1_awlen_o               ,
    output [  1:0]  slv1_awburst_o             ,
    output          slv1_wvalid_o              ,
    output [ 31:0]  slv1_wdata_o               ,
    output [  3:0]  slv1_wstrb_o               ,
    output          slv1_wlast_o               ,
    output          slv1_bready_o              ,
    output          slv1_arvalid_o             ,
    output [ 31:0]  slv1_araddr_o              ,
    output [  3:0]  slv1_arid_o                ,
    output [  7:0]  slv1_arlen_o               ,
    output [  1:0]  slv1_arburst_o             ,
    output          slv1_rready_o              ,

    output          slv2_awvalid_o             ,
    output [ 31:0]  slv2_awaddr_o              ,
    output [  3:0]  slv2_awid_o                ,
    output [  7:0]  slv2_awlen_o               ,
    output [  1:0]  slv2_awburst_o             ,
    output          slv2_wvalid_o              ,
    output [ 31:0]  slv2_wdata_o               ,
    output [  3:0]  slv2_wstrb_o               ,
    output          slv2_wlast_o               ,
    output          slv2_bready_o              ,
    output          slv2_arvalid_o             ,
    output [ 31:0]  slv2_araddr_o              ,
    output [  3:0]  slv2_arid_o                ,
    output [  7:0]  slv2_arlen_o               ,
    output [  1:0]  slv2_arburst_o             ,
    output          slv2_rready_o              ,

    output          slv3_awvalid_o             ,
    output [ 31:0]  slv3_awaddr_o              ,
    output [  3:0]  slv3_awid_o                ,
    output [  7:0]  slv3_awlen_o               ,
    output [  1:0]  slv3_awburst_o             ,
    output          slv3_wvalid_o              ,
    output [ 31:0]  slv3_wdata_o               ,
    output [  3:0]  slv3_wstrb_o               ,
    output          slv3_wlast_o               ,
    output          slv3_bready_o              ,
    output          slv3_arvalid_o             ,
    output [ 31:0]  slv3_araddr_o              ,
    output [  3:0]  slv3_arid_o                ,
    output [  7:0]  slv3_arlen_o               ,
    output [  1:0]  slv3_arburst_o             ,
    output          slv3_rready_o              ,

    output          slv4_awvalid_o             ,
    output [ 31:0]  slv4_awaddr_o              ,
    output [  3:0]  slv4_awid_o                ,
    output [  7:0]  slv4_awlen_o               ,
    output [  1:0]  slv4_awburst_o             ,
    output          slv4_wvalid_o              ,
    output [ 31:0]  slv4_wdata_o               ,
    output [  3:0]  slv4_wstrb_o               ,
    output          slv4_wlast_o               ,
    output          slv4_bready_o              ,
    output          slv4_arvalid_o             ,
    output [ 31:0]  slv4_araddr_o              ,
    output [  3:0]  slv4_arid_o                ,
    output [  7:0]  slv4_arlen_o               ,
    output [  1:0]  slv4_arburst_o             ,
    output          slv4_rready_o              ,

    output          slv5_awvalid_o             ,
    output [ 31:0]  slv5_awaddr_o              ,
    output [  3:0]  slv5_awid_o                ,
    output [  7:0]  slv5_awlen_o               ,
    output [  1:0]  slv5_awburst_o             ,
    output          slv5_wvalid_o              ,
    output [ 31:0]  slv5_wdata_o               ,
    output [  3:0]  slv5_wstrb_o               ,
    output          slv5_wlast_o               ,
    output          slv5_bready_o              ,
    output          slv5_arvalid_o             ,
    output [ 31:0]  slv5_araddr_o              ,
    output [  3:0]  slv5_arid_o                ,
    output [  7:0]  slv5_arlen_o               ,
    output [  1:0]  slv5_arburst_o             ,
    output          slv5_rready_o              
);

    // Default to slv0
    `define ADDR_SEL_W  3            

    parameter SLV1_ADDR  = 32'h90000000;
    parameter SLV1_MASK  = 32'hff000000;
    parameter SLV2_ADDR  = 32'h91000000;
    parameter SLV2_MASK  = 32'hff000000;
    parameter SLV3_ADDR  = 32'h92000000;
    parameter SLV3_MASK  = 32'hff000000;
    parameter SLV4_ADDR  = 32'h93000000;
    parameter SLV4_MASK  = 32'hff000000;
    parameter SLV5_ADDR  = 32'h94000000;
    parameter SLV5_MASK  = 32'hff000000;

    //-----------------------------------------------------------------
    // AXI: Read
    //-----------------------------------------------------------------
    reg [3:0]              read_pending_q;
    reg [3:0]              read_pending_r;
    reg [`ADDR_SEL_W-1:0]  read_port_q;
    reg [`ADDR_SEL_W-1:0]  read_port_r;

    always @(*) begin
        read_port_r = `ADDR_SEL_W'd0;
        if ((mst_araddr_i & SLV1_MASK) == SLV1_ADDR) read_port_r = `ADDR_SEL_W'd1;
        if ((mst_araddr_i & SLV2_MASK) == SLV2_ADDR) read_port_r = `ADDR_SEL_W'd2;
        if ((mst_araddr_i & SLV3_MASK) == SLV3_ADDR) read_port_r = `ADDR_SEL_W'd3;
        if ((mst_araddr_i & SLV4_MASK) == SLV4_ADDR) read_port_r = `ADDR_SEL_W'd4;
        if ((mst_araddr_i & SLV5_MASK) == SLV5_ADDR) read_port_r = `ADDR_SEL_W'd5;
    end

    wire read_incr_w = (mst_arvalid_i && mst_arready_o);
    wire read_decr_w = (mst_rvalid_o  && mst_rlast_o && mst_rready_i);

    always @(*) begin
        read_pending_r = read_pending_q;
    
        if (read_incr_w && !read_decr_w)
            read_pending_r = read_pending_r + 4'd1;
        else if (!read_incr_w && read_decr_w)
            read_pending_r = read_pending_r - 4'd1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            read_pending_q <= 4'b0;
        else begin
            read_pending_q <= read_pending_r;
        
            // Read command accepted
            if (mst_arvalid_i && mst_arready_o)
                read_port_q <= read_port_r;
        end
    end

    wire read_accept_w = (read_port_q == read_port_r && read_pending_q != 4'hF) || (read_pending_q == 4'h0);

    assign slv0_arvalid_o = mst_arvalid_i & read_accept_w & (read_port_r == `ADDR_SEL_W'd0);
    assign slv0_araddr_o  = mst_araddr_i;
    assign slv0_arid_o    = mst_arid_i;
    assign slv0_arlen_o   = mst_arlen_i;
    assign slv0_arburst_o = mst_arburst_i;
    assign slv0_rready_o  = mst_rready_i;

    assign slv1_arvalid_o = mst_arvalid_i & read_accept_w & (read_port_r == `ADDR_SEL_W'd1);
    assign slv1_araddr_o  = mst_araddr_i;
    assign slv1_arid_o    = mst_arid_i;
    assign slv1_arlen_o   = mst_arlen_i;
    assign slv1_arburst_o = mst_arburst_i;
    assign slv1_rready_o  = mst_rready_i;

    assign slv2_arvalid_o = mst_arvalid_i & read_accept_w & (read_port_r == `ADDR_SEL_W'd2);
    assign slv2_araddr_o  = mst_araddr_i;
    assign slv2_arid_o    = mst_arid_i;
    assign slv2_arlen_o   = mst_arlen_i;
    assign slv2_arburst_o = mst_arburst_i;
    assign slv2_rready_o  = mst_rready_i;

    assign slv3_arvalid_o = mst_arvalid_i & read_accept_w & (read_port_r == `ADDR_SEL_W'd3);
    assign slv3_araddr_o  = mst_araddr_i;
    assign slv3_arid_o    = mst_arid_i;
    assign slv3_arlen_o   = mst_arlen_i;
    assign slv3_arburst_o = mst_arburst_i;
    assign slv3_rready_o  = mst_rready_i;

    assign slv4_arvalid_o = mst_arvalid_i & read_accept_w & (read_port_r == `ADDR_SEL_W'd4);
    assign slv4_araddr_o  = mst_araddr_i;
    assign slv4_arid_o    = mst_arid_i;
    assign slv4_arlen_o   = mst_arlen_i;
    assign slv4_arburst_o = mst_arburst_i;
    assign slv4_rready_o  = mst_rready_i;

    assign slv5_arvalid_o = mst_arvalid_i & read_accept_w & (read_port_r == `ADDR_SEL_W'd5);
    assign slv5_araddr_o  = mst_araddr_i;
    assign slv5_arid_o    = mst_arid_i;
    assign slv5_arlen_o   = mst_arlen_i;
    assign slv5_arburst_o = mst_arburst_i;
    assign slv5_rready_o  = mst_rready_i;

    reg        slv_rvalid_r;
    reg [31:0] slv_rdata_r;
    reg [1:0]  slv_rresp_r;
    reg [3:0]  slv_rid_r;
    reg        slv_rlast_r;

    always @(*) begin
        case (read_port_q)
            default:
            begin
                slv_rvalid_r = slv0_rvalid_i;
                slv_rdata_r  = slv0_rdata_i;
                slv_rresp_r  = slv0_rresp_i;
                slv_rid_r    = slv0_rid_i;
                slv_rlast_r  = slv0_rlast_i;
            end
            `ADDR_SEL_W'd1:
            begin
                slv_rvalid_r = slv1_rvalid_i;
                slv_rdata_r  = slv1_rdata_i;
                slv_rresp_r  = slv1_rresp_i;
                slv_rid_r    = slv1_rid_i;
                slv_rlast_r  = slv1_rlast_i;
            end
            `ADDR_SEL_W'd2:
            begin
                slv_rvalid_r = slv2_rvalid_i;
                slv_rdata_r  = slv2_rdata_i;
                slv_rresp_r  = slv2_rresp_i;
                slv_rid_r    = slv2_rid_i;
                slv_rlast_r  = slv2_rlast_i;
            end
            `ADDR_SEL_W'd3:
            begin
                slv_rvalid_r = slv3_rvalid_i;
                slv_rdata_r  = slv3_rdata_i;
                slv_rresp_r  = slv3_rresp_i;
                slv_rid_r    = slv3_rid_i;
                slv_rlast_r  = slv3_rlast_i;
            end
            `ADDR_SEL_W'd4:
            begin
                slv_rvalid_r = slv4_rvalid_i;
                slv_rdata_r  = slv4_rdata_i;
                slv_rresp_r  = slv4_rresp_i;
                slv_rid_r    = slv4_rid_i;
                slv_rlast_r  = slv4_rlast_i;
            end
            `ADDR_SEL_W'd5:
            begin
                slv_rvalid_r = slv5_rvalid_i;
                slv_rdata_r  = slv5_rdata_i;
                slv_rresp_r  = slv5_rresp_i;
                slv_rid_r    = slv5_rid_i;
                slv_rlast_r  = slv5_rlast_i;
            end
        endcase
    end

    assign mst_rvalid_o  = slv_rvalid_r;
    assign mst_rdata_o   = slv_rdata_r;
    assign mst_rresp_o   = slv_rresp_r;
    assign mst_rid_o     = slv_rid_r;
    assign mst_rlast_o   = slv_rlast_r;

    reg mst_arready_r;
    
    always @(*) begin
        case (read_port_r)
            default:
                mst_arready_r = slv0_arready_i;
            `ADDR_SEL_W'd1:
                mst_arready_r = slv1_arready_i;
            `ADDR_SEL_W'd2:
                mst_arready_r = slv2_arready_i;
            `ADDR_SEL_W'd3:
                mst_arready_r = slv3_arready_i;
            `ADDR_SEL_W'd4:
                mst_arready_r = slv4_arready_i;
            `ADDR_SEL_W'd5:
                mst_arready_r = slv5_arready_i;
        endcase
    end

    assign mst_arready_o = read_accept_w & mst_arready_r;

    //-----------------------------------------------------------------
    // AXI: Write
    //-----------------------------------------------------------------
    reg [3:0]              write_pending_q;
    reg [3:0]              write_pending_r;
    reg [`ADDR_SEL_W-1:0]  write_port_q;
    reg [`ADDR_SEL_W-1:0]  write_port_r;

    always @(*) begin
        write_port_r = write_port_q;

        if (mst_awvalid_i) begin
            write_port_r = `ADDR_SEL_W'd0;
            if ((mst_awaddr_i & SLV1_MASK) == SLV1_ADDR) write_port_r = `ADDR_SEL_W'd1;
            if ((mst_awaddr_i & SLV2_MASK) == SLV2_ADDR) write_port_r = `ADDR_SEL_W'd2;
            if ((mst_awaddr_i & SLV3_MASK) == SLV3_ADDR) write_port_r = `ADDR_SEL_W'd3;
            if ((mst_awaddr_i & SLV4_MASK) == SLV4_ADDR) write_port_r = `ADDR_SEL_W'd4;
            if ((mst_awaddr_i & SLV5_MASK) == SLV5_ADDR) write_port_r = `ADDR_SEL_W'd5;
        end
    end

    wire write_incr_w = (mst_awvalid_i && mst_awready_o);
    wire write_decr_w = (mst_bvalid_o  && mst_bready_i);

    // NOTE: This IP expect AWVALID and WVALID to appear in the same cycle...
    always @(*) begin
        write_pending_r = write_pending_q;
    
        if (write_incr_w && !write_decr_w)
            write_pending_r = write_pending_r + 4'd1;
        else if (!write_incr_w && write_decr_w)
            write_pending_r = write_pending_r - 4'd1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            write_pending_q <= 4'b0;
        else begin
            write_pending_q <= write_pending_r;
        
            // Write command accepted
            if (mst_awvalid_i && mst_awready_o)
                write_port_q <= write_port_r;
        end
    end

    wire write_accept_w = (write_port_q == write_port_r && write_pending_q != 4'hF) || (write_pending_q == 4'h0);

    assign slv0_awvalid_o = mst_awvalid_i & write_accept_w & (write_port_r == `ADDR_SEL_W'd0);
    assign slv0_awaddr_o  = mst_awaddr_i;
    assign slv0_awid_o    = mst_awid_i;
    assign slv0_awlen_o   = mst_awlen_i;
    assign slv0_awburst_o = mst_awburst_i;
    assign slv0_wvalid_o  = mst_wvalid_i & write_accept_w & (write_port_r == `ADDR_SEL_W'd0);
    assign slv0_wdata_o   = mst_wdata_i;
    assign slv0_wstrb_o   = mst_wstrb_i;
    assign slv0_wlast_o   = mst_wlast_i;
    assign slv0_bready_o  = mst_bready_i;

    assign slv1_awvalid_o = mst_awvalid_i & write_accept_w & (write_port_r == `ADDR_SEL_W'd1);
    assign slv1_awaddr_o  = mst_awaddr_i;
    assign slv1_awid_o    = mst_awid_i;
    assign slv1_awlen_o   = mst_awlen_i;
    assign slv1_awburst_o = mst_awburst_i;
    assign slv1_wvalid_o  = mst_wvalid_i & write_accept_w & (write_port_r == `ADDR_SEL_W'd1);
    assign slv1_wdata_o   = mst_wdata_i;
    assign slv1_wstrb_o   = mst_wstrb_i;
    assign slv1_wlast_o   = mst_wlast_i;
    assign slv1_bready_o  = mst_bready_i;

    assign slv2_awvalid_o = mst_awvalid_i & write_accept_w & (write_port_r == `ADDR_SEL_W'd2);
    assign slv2_awaddr_o  = mst_awaddr_i;
    assign slv2_awid_o    = mst_awid_i;
    assign slv2_awlen_o   = mst_awlen_i;
    assign slv2_awburst_o = mst_awburst_i;
    assign slv2_wvalid_o  = mst_wvalid_i & write_accept_w & (write_port_r == `ADDR_SEL_W'd2);
    assign slv2_wdata_o   = mst_wdata_i;
    assign slv2_wstrb_o   = mst_wstrb_i;
    assign slv2_wlast_o   = mst_wlast_i;
    assign slv2_bready_o  = mst_bready_i;

    assign slv3_awvalid_o = mst_awvalid_i & write_accept_w & (write_port_r == `ADDR_SEL_W'd3);
    assign slv3_awaddr_o  = mst_awaddr_i;
    assign slv3_awid_o    = mst_awid_i;
    assign slv3_awlen_o   = mst_awlen_i;
    assign slv3_awburst_o = mst_awburst_i;
    assign slv3_wvalid_o  = mst_wvalid_i & write_accept_w & (write_port_r == `ADDR_SEL_W'd3);
    assign slv3_wdata_o   = mst_wdata_i;
    assign slv3_wstrb_o   = mst_wstrb_i;
    assign slv3_wlast_o   = mst_wlast_i;
    assign slv3_bready_o  = mst_bready_i;

    assign slv4_awvalid_o = mst_awvalid_i & write_accept_w & (write_port_r == `ADDR_SEL_W'd4);
    assign slv4_awaddr_o  = mst_awaddr_i;
    assign slv4_awid_o    = mst_awid_i;
    assign slv4_awlen_o   = mst_awlen_i;
    assign slv4_awburst_o = mst_awburst_i;
    assign slv4_wvalid_o  = mst_wvalid_i & write_accept_w & (write_port_r == `ADDR_SEL_W'd4);
    assign slv4_wdata_o   = mst_wdata_i;
    assign slv4_wstrb_o   = mst_wstrb_i;
    assign slv4_wlast_o   = mst_wlast_i;
    assign slv4_bready_o  = mst_bready_i;

    assign slv5_awvalid_o = mst_awvalid_i & write_accept_w & (write_port_r == `ADDR_SEL_W'd5);
    assign slv5_awaddr_o  = mst_awaddr_i;
    assign slv5_awid_o    = mst_awid_i;
    assign slv5_awlen_o   = mst_awlen_i;
    assign slv5_awburst_o = mst_awburst_i;
    assign slv5_wvalid_o  = mst_wvalid_i & write_accept_w & (write_port_r == `ADDR_SEL_W'd5);
    assign slv5_wdata_o   = mst_wdata_i;
    assign slv5_wstrb_o   = mst_wstrb_i;
    assign slv5_wlast_o   = mst_wlast_i;
    assign slv5_bready_o  = mst_bready_i;

    reg        slv_bvalid_r;
    reg [1:0]  slv_bresp_r;
    reg [3:0]  slv_bid_r;

    always @(*) begin
        case (write_port_q)
            default:
            begin
                slv_bvalid_r = slv0_bvalid_i;
                slv_bresp_r  = slv0_bresp_i;
                slv_bid_r    = slv0_bid_i;
            end
            `ADDR_SEL_W'd1:
            begin
                slv_bvalid_r = slv1_bvalid_i;
                slv_bresp_r  = slv1_bresp_i;
                slv_bid_r    = slv1_bid_i;
            end
            `ADDR_SEL_W'd2:
            begin
                slv_bvalid_r = slv2_bvalid_i;
                slv_bresp_r  = slv2_bresp_i;
                slv_bid_r    = slv2_bid_i;
            end
            `ADDR_SEL_W'd3:
            begin
                slv_bvalid_r = slv3_bvalid_i;
                slv_bresp_r  = slv3_bresp_i;
                slv_bid_r    = slv3_bid_i;
            end
            `ADDR_SEL_W'd4:
            begin
                slv_bvalid_r = slv4_bvalid_i;
                slv_bresp_r  = slv4_bresp_i;
                slv_bid_r    = slv4_bid_i;
            end
            `ADDR_SEL_W'd5:
            begin
                slv_bvalid_r = slv5_bvalid_i;
                slv_bresp_r  = slv5_bresp_i;
                slv_bid_r    = slv5_bid_i;
            end
        endcase
    end

    assign mst_bvalid_o  = slv_bvalid_r;
    assign mst_bresp_o   = slv_bresp_r;
    assign mst_bid_o     = slv_bid_r;

    reg mst_awready_r;
    reg mst_wready_r;

    // NOTE: This IP expects AWREADY and WREADY to follow each other....
    always @(*) begin
        case (write_port_r)
            default:
            begin
                mst_awready_r = slv0_awready_i;
                mst_wready_r  = slv0_wready_i;
            end        
            `ADDR_SEL_W'd1:
            begin
                mst_awready_r = slv1_awready_i;
                mst_wready_r  = slv1_wready_i;
            end
            `ADDR_SEL_W'd2:
            begin
                mst_awready_r = slv2_awready_i;
                mst_wready_r  = slv2_wready_i;
            end
            `ADDR_SEL_W'd3:
            begin
                mst_awready_r = slv3_awready_i;
                mst_wready_r  = slv3_wready_i;
            end
            `ADDR_SEL_W'd4:
            begin
                mst_awready_r = slv4_awready_i;
                mst_wready_r  = slv4_wready_i;
            end
            `ADDR_SEL_W'd5:
            begin
                mst_awready_r = slv5_awready_i;
                mst_wready_r  = slv5_wready_i;
            end
        endcase
    end
    
    assign mst_awready_o = write_accept_w & mst_awready_r;
    assign mst_wready_o  = write_accept_w & mst_wready_r;

endmodule

