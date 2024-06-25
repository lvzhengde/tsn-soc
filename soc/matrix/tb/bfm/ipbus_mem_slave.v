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
 * IPBus slave memory
 * PARAMETERS:
 *    SIZE_IN_BYTES - size of memory in bytes
 *    BLOCK_ID - block address for address decoding
-*/
module ipbus_mem_slave
#(
    parameter SIZE_IN_BYTES = 1024, // memory depth
    parameter BLOCK_ID      = 8'h1
)
(
    input               bus2ip_clk     ,         //clock 
    input               bus2ip_rst_n   ,         //active low reset
    input  [31:0]       bus2ip_addr_i  ,
    input  [31:0]       bus2ip_data_i  ,
    input               bus2ip_rd_ce_i ,         //active high
    input               bus2ip_wr_ce_i ,         //active high
    output reg [31:0]   ip2bus_data_o   
);
    localparam DEPTH  = (SIZE_IN_BYTES + 3) / 4;
    localparam ADDR_W = logb2(SIZE_IN_BYTES);
    
    reg  [7:0] mem0[0:DEPTH-1];
    reg  [7:0] mem1[0:DEPTH-1];
    reg  [7:0] mem2[0:DEPTH-1];
    reg  [7:0] mem3[0:DEPTH-1];

    wire [ADDR_W-3:0] t_addr_w = bus2ip_addr_i[ADDR_W-1:2];

    //-----------------------------------------------------------------------
    // write case
    //-----------------------------------------------------------------------
    integer i;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if(!bus2ip_rst_n) begin
            for (i = 0; i < DEPTH; i = i+1) begin
                mem0[i] <= 0;
                mem1[i] <= 0;
                mem2[i] <= 0;
                mem3[i] <= 0;
            end
        end
        else if (bus2ip_wr_ce_i == 1'b1 && bus2ip_addr_i[31:24] == BLOCK_ID)begin
            mem0[t_addr_w] <= bus2ip_data_i[ 7: 0];
            mem1[t_addr_w] <= bus2ip_data_i[15: 8];
            mem2[t_addr_w] <= bus2ip_data_i[23:16];
            mem3[t_addr_w] <= bus2ip_data_i[31:24];
        end
    end    

    //-----------------------------------------------------------------------
    // read case
    //-----------------------------------------------------------------------
    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if(!bus2ip_rst_n) begin
            ip2bus_data_o <= 32'h0;
        end
        else if (bus2ip_rd_ce_i == 1'b1 && bus2ip_addr_i[31:24] == BLOCK_ID)begin
            ip2bus_data_o[ 7: 0] <= mem0[t_addr_w];
            ip2bus_data_o[15: 8] <= mem1[t_addr_w];
            ip2bus_data_o[23:16] <= mem2[t_addr_w];
            ip2bus_data_o[31:24] <= mem3[t_addr_w];
        end
        else begin
            ip2bus_data_o <= 32'h0;
        end
    end    

    // Calculate log-base2
    function integer logb2;
        input [31:0] value;
        reg   [31:0] tmp;
    begin
        tmp = value - 1;
        for (logb2 = 0; tmp > 0; logb2 = logb2 + 1) tmp = tmp >> 1;
    end
    endfunction

endmodule
