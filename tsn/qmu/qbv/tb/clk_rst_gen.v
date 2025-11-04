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
 * Description : Clock and Reset Generator for QBV Testbench
 *               Generates clock and reset signals for tb_top.v
 * File        : clk_rst_gen.v
-*/

`timescale 1ns/1ps

module clk_rst_gen 
#(
    parameter BUS_CLK_PERIOD  = 10,
    parameter OPER_CLK_PERIOD = 8
) 
(
    output reg bus_clk,
    output reg bus_rst_n,
    output reg oper_clk,
    output reg oper_rst_n
);

    // Bus clock generation
    initial begin
        bus_clk = 0;
        forever #(BUS_CLK_PERIOD/2) bus_clk = ~bus_clk;
    end

    // Operational clock generation
    initial begin
        oper_clk = 0;
        forever #(OPER_CLK_PERIOD/2) oper_clk = ~oper_clk;
    end

    // Reset generation
    initial begin
        bus_rst_n = 0;
        #500;
        bus_rst_n = 1;
    end

    initial begin
        oper_rst_n = 0;
        #600;
        oper_rst_n = 1;
    end    

    task reset;
    begin
        fork
            begin
                bus_rst_n = 0;
                #500;
                bus_rst_n = 1;
            end
            begin
                oper_rst_n = 0;
                #600;
                oper_rst_n = 1;
            end
        join
    end
    endtask         

endmodule
