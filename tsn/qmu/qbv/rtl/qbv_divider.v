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
 * 32-bit Unsigned Divider
 * implements a simple non-restoring divider with start and complete signals.
-*/

module qbv_divider
(
    input           clk,
    input           rst_n,
    input           start_i,         // Start division
    input  [31:0]   dividend_i,      // Dividend
    input  [31:0]   divisor_i,       // Divisor
    output          complete_o,      // Division complete
    output [31:0]   quotient_o,      // Quotient
    output [31:0]   remainder_o      // Remainder
);

    reg        busy_q;
    reg [31:0] dividend_q;
    reg [62:0] divisor_q;
    reg [31:0] quotient_q;
    reg [31:0] q_mask_q;
    reg [31:0] remainder_q;

    wire div_start_w    = start_i & ~busy_q;
    wire div_complete_w = !(|q_mask_q) & busy_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy_q      <= 1'b0;
            dividend_q  <= 32'b0;
            divisor_q   <= 63'b0;
            quotient_q  <= 32'b0;
            q_mask_q    <= 32'b0;
            remainder_q <= 32'b0;
        end else if (div_start_w) begin
            busy_q      <= 1'b1;
            dividend_q  <= dividend_i;
            divisor_q   <= {divisor_i, 31'b0};
            quotient_q  <= 32'b0;
            q_mask_q    <= 32'h80000000;
            remainder_q <= 32'b0;
        end else if (div_complete_w) begin
            busy_q <= 1'b0;
            remainder_q <= dividend_q;
        end else if (busy_q) begin
            if (divisor_q <= {31'b0, dividend_q}) begin
                dividend_q <= dividend_q - divisor_q[31:0];
                quotient_q <= quotient_q | q_mask_q;
            end
            divisor_q <= {1'b0, divisor_q[62:1]};
            q_mask_q  <= {1'b0, q_mask_q[31:1]};
        end
    end

    assign complete_o  = div_complete_w;
    assign quotient_o  = quotient_q;
    assign remainder_o = remainder_q;

endmodule
