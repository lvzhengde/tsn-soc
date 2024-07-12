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

module uart_axi_mst 
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter AXI_ID = 4'd0
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    input           clk     ,
    input           rst_n   ,      

    // AXI4 bus master interface
    output          axi_awvalid_o ,  
    output [ 31:0]  axi_awaddr_o  ,   
    output [  3:0]  axi_awid_o    ,   
    output [  7:0]  axi_awlen_o   ,   
    output [  1:0]  axi_awburst_o ,  
    output          axi_wvalid_o  ,   
    output [ 31:0]  axi_wdata_o   ,  
    output [  3:0]  axi_wstrb_o   ,  
    output          axi_wlast_o   ,  
    output          axi_bready_o  ,   
    output          axi_arvalid_o ,    
    output [ 31:0]  axi_araddr_o  ,   
    output [  3:0]  axi_arid_o    ,   
    output [  7:0]  axi_arlen_o   ,  
    output [  1:0]  axi_arburst_o ,    
    output          axi_rready_o  ,   

    input           axi_awready_i ,   
    input           axi_wready_i  ,  
    input           axi_bvalid_i  ,  
    input  [  1:0]  axi_bresp_i   , 
    input  [  3:0]  axi_bid_i     ,
    input           axi_arready_i ,   
    input           axi_rvalid_i  ,  
    input  [ 31:0]  axi_rdata_i   , 
    input  [  1:0]  axi_rresp_i   , 
    input  [  3:0]  axi_rid_i     , 
    input           axi_rlast_i   , 

    // uart rx interface
    input  [  7:0] mst_rdata_i    ,
    output         mst_read_o     ,
    input          rx_buffer_data_present_i ,
    
    // uart tx interface
    output [  7:0] mst_wdata_o       ,
    output         mst_write_o       ,      
    input          tx_buffer_full_i  ,
    input          tx_buffer_afull_i 
);


endmodule
