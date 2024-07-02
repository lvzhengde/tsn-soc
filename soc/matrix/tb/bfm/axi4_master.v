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
 * AXI4 bus master behavioral model
-*/

module axi4_master
#(
    parameter ID = 0
)
(
    input wire           clk             ,
    input wire           rst_n           ,

    input wire           axi_awready_i   ,
    input wire           axi_wready_i    ,
    input wire           axi_bvalid_i    ,
    input wire  [  1:0]  axi_bresp_i     ,
    input wire  [  3:0]  axi_bid_i       ,
    input wire           axi_arready_i   ,
    input wire           axi_rvalid_i    ,
    input wire  [ 31:0]  axi_rdata_i     ,
    input wire  [  1:0]  axi_rresp_i     ,
    input wire  [  3:0]  axi_rid_i       ,
    input wire           axi_rlast_i     ,

    output reg           axi_awvalid_o   ,
    output reg  [ 31:0]  axi_awaddr_o    ,
    output reg  [  3:0]  axi_awid_o      ,
    output reg  [  7:0]  axi_awlen_o     ,
    output reg  [  1:0]  axi_awburst_o   ,
    output reg           axi_wvalid_o    ,
    output reg  [ 31:0]  axi_wdata_o     ,
    output reg  [  3:0]  axi_wstrb_o     ,
    output reg           axi_wlast_o     ,
    output reg           axi_bready_o    ,
    output reg           axi_arvalid_o   ,
    output reg  [ 31:0]  axi_araddr_o    ,
    output reg  [  3:0]  axi_arid_o      ,
    output reg  [  7:0]  axi_arlen_o     ,
    output reg  [  1:0]  axi_arburst_o   ,
    output reg           axi_rready_o    ,

    input wire           busy_i          ,
    output reg           busy_o
);
    parameter AXI_ID = ID << 2;

    `include "axi4_master_tasks.v"
    `include "mem_test_tasks.v"
    
    reg  [ 31:0]  rdata[0:1023]; 
    reg  [ 31:0]  wdata[0:1023]; 

    reg  done = 1'b0;

    initial begin
        axi_awvalid_o = 0 ;
        axi_awaddr_o  = ~0 ;
        axi_awid_o    = 0 ;
        axi_awlen_o   = 0 ;
        axi_awburst_o = 0 ;
        axi_wvalid_o  = 0 ;
        axi_wdata_o   = ~0 ;
        axi_wstrb_o   = 0 ;
        axi_wlast_o   = 0 ;
        axi_bready_o  = 0 ;
        axi_arvalid_o = 0 ;
        axi_araddr_o  = ~0 ;
        axi_arid_o    = 0 ;
        axi_arlen_o   = 0 ;
        axi_arburst_o = 0 ;
        axi_rready_o  = 0 ;

        busy_o = 0;

        wait (rst_n == 1'b0);
        wait (rst_n == 1'b1);
        repeat (5) @ (posedge clk);

        #100;

        while (busy_i == 1'b1) @(posedge clk);

        repeat (5) @(posedge clk);

        done = 1'b1;
        axi_statistics(ID);
    end

endmodule

