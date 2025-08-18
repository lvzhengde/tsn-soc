/*+
 * Copyright (c) 2022-2025 Zhengde
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
 * Description : Dual Port Block RAM
 *               Two independent read/write ports, each with its own clock domain.
 * File        : qbv_dpram.v
-*/

module qbv_dpram
#(
    parameter ADDR_WIDTH = 11,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 2048
)
(
    // Port 0
    input                   clk0,
    input                   rst0_n,
    input  [ADDR_WIDTH-1:0] addr0_i,
    input  [DATA_WIDTH-1:0] data0_i,
    input  [3:0]            wr0_i,
    output [DATA_WIDTH-1:0] data0_o,

    // Port 1
    input                   clk1,
    input                   rst1_n,
    input  [ADDR_WIDTH-1:0] addr1_i,
    input  [DATA_WIDTH-1:0] data1_i,
    input  [3:0]            wr1_i,
    output [DATA_WIDTH-1:0] data1_o
);

    // Dual Port RAM
    reg [DATA_WIDTH-1:0] ram [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] ram_read0_q;
    reg [DATA_WIDTH-1:0] ram_read1_q;

    // Port 0: Synchronous write, read-first
    always @(posedge clk0) begin
        if (wr0_i[0]) ram[addr0_i][7:0]   <= data0_i[7:0];
        if (wr0_i[1]) ram[addr0_i][15:8]  <= data0_i[15:8];
        if (wr0_i[2]) ram[addr0_i][23:16] <= data0_i[23:16];
        if (wr0_i[3]) ram[addr0_i][31:24] <= data0_i[31:24];
        //ram_read0_q <= ram[addr0_i];
    end

    always @(*) begin
        ram_read0_q = ram[addr0_i];
    end

    // Port 1: Synchronous write, read-first
    always @(posedge clk1) begin
        if (wr1_i[0]) ram[addr1_i][7:0]   <= data1_i[7:0];
        if (wr1_i[1]) ram[addr1_i][15:8]  <= data1_i[15:8];
        if (wr1_i[2]) ram[addr1_i][23:16] <= data1_i[23:16];
        if (wr1_i[3]) ram[addr1_i][31:24] <= data1_i[31:24];
        //ram_read1_q <= ram[addr1_i];
    end

    always @(*) begin
        ram_read1_q = ram[addr1_i];
    end

    assign data0_o = ram_read0_q;
    assign data1_o = ram_read1_q;

endmodule
