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
 *  Description : Simple FIFO for SPI
 *                Refer to the commonly used FIFO design in the riscv project
 *  File        : spi_master.v
-*/

module spi_fifo
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter WIDTH   = 8,
    parameter DEPTH   = 4,
    parameter ADDR_W  = 2
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
    input               clk        ,
    input               rst_n      ,
    input  [WIDTH-1:0]  data_in_i  ,
    input               push_i     ,
    input               pop_i      ,
    input               flush_i    ,
    
    // Outputs
    output [WIDTH-1:0]  data_out_o ,
    output              accept_o   ,
    output              valid_o     
);

    //-----------------------------------------------------------------
    // Local Params
    //-----------------------------------------------------------------
    localparam COUNT_W = ADDR_W + 1;

    //-----------------------------------------------------------------
    // Registers
    //-----------------------------------------------------------------
    reg [WIDTH-1:0]   ram_q[DEPTH-1:0];
    reg [ADDR_W-1:0]  rd_ptr_q;
    reg [ADDR_W-1:0]  wr_ptr_q;
    reg [COUNT_W-1:0] count_q;

    //-----------------------------------------------------------------
    // Sequential
    //-----------------------------------------------------------------
    always @(posedge clk or posedge rst_n) begin
        if (!rst_n) begin
            count_q   <= {(COUNT_W) {1'b0}};
            rd_ptr_q  <= {(ADDR_W) {1'b0}};
            wr_ptr_q  <= {(ADDR_W) {1'b0}};
        end
        else if (flush_i) begin
            count_q   <= {(COUNT_W) {1'b0}};
            rd_ptr_q  <= {(ADDR_W) {1'b0}};
            wr_ptr_q  <= {(ADDR_W) {1'b0}};
        end
        else begin
            // Push
            if (push_i & accept_o)
            begin
                ram_q[wr_ptr_q] <= data_in_i;
                wr_ptr_q        <= wr_ptr_q + 1;
            end
        
            // Pop
            if (pop_i & valid_o)
                rd_ptr_q       <= rd_ptr_q + 1;
        
            // Count up
            if ((push_i & accept_o) & ~(pop_i & valid_o))
                count_q <= count_q + 1;
            // Count down
            else if (~(push_i & accept_o) & (pop_i & valid_o))
                count_q <= count_q - 1;
        end
    end //always

    //-------------------------------------------------------------------
    // Combinatorial
    //-------------------------------------------------------------------
    /* verilator lint_off WIDTH */
    assign valid_o       = (count_q != 0);
    assign accept_o      = (count_q != DEPTH);
    /* verilator lint_on WIDTH */
    
    assign data_out_o    = ram_q[rd_ptr_q];

endmodule
