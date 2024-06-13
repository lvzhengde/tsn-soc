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
 * AXI4 to IPBUS conversion bridge
-*/

module axi4_ipbus_bridge
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

    //standard ip access bus interface
    output          bus2ip_clk      ,
    output          bus2ip_rst_n    ,
    output [ 31:0]  bus2ip_addr_o   ,
    output [ 31:0]  bus2ip_data_o   ,
    output          bus2ip_rd_ce_o  ,  //active high
    output          bus2ip_wr_ce_o  ,  //active high
    input  [ 31:0]  ip2bus_data_i       

);

    reg          grant_write_q;
    reg          grant_read_q ;

    reg          req_r;
    reg          ack_q;
    reg  [31:0]  addr_r;
    reg          wr_r;
    reg  [31:0]  wdata_r;  
    reg  [31:0]  rdata_r; 
    reg  [ 3:0]  be_r;

    reg  [31:0]  t_waddr_q ;
    reg  [31:0]  t_wdata_q ;
    reg  [ 3:0]  t_wstrb_q ;
    reg          t_wen_q   ;

    reg  [31:0]  t_raddr_q ;
    wire [31:0]  t_rdata_w = rdata_r;
    reg  [ 3:0]  t_rstrb_q ;
    reg          t_ren_q   ;

    always @(*) begin
        case ({grant_write_q,grant_read_q})
            2'b10: 
            begin // write-case
                   req_r   = t_wen_q  ;
                   addr_r  = t_waddr_q;
                   wr_r    = 1'b1  ;
                   wdata_r = t_wdata_q; // WDATA (AXI)
                   be_r    = t_wstrb_q;
            end
            2'b01: 
            begin // read-case
                   req_r   = t_ren_q  ;
                   addr_r  = t_raddr_q;
                   wr_r    = 1'b0  ;
                   wdata_r = 32'h0 ;
                   be_r    = t_rstrb_q;
            end
            2'b00, 
            2'b11: 
            begin
                   req_r   = 1'b0  ;
                   addr_r  = 32'h0 ;
                   wr_r    = 1'b0  ;
                   wdata_r = 32'h0; // WDATA (AXI)
                   be_r    = 1'b0;
            end
        endcase
    end




    assign bus2ip_clk     = clk;
    assign bus2ip_rst_n   = rst_n;
    assign bus2ip_rd_ce_o = 1'b1;  //always read active

endmodule
