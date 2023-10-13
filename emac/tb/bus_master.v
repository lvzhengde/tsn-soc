/*+
 * Copyright (c) 2022-2023 Zhengde
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
 * Ethernet MAC IP bus master for testbench
-*/

`include "tb_emac_defines.v"

module bus_master (
    //standard access bus interface for registers
    input                  bus2ip_clk   ,
    input                  bus2ip_rst_n  ,
    output reg  [31:0]     bus2ip_addr_o ,
    output reg  [31:0]     bus2ip_data_o ,
    output reg             bus2ip_rd_ce_o ,         //active high
    output reg             bus2ip_wr_ce_o ,         //active high
    input   [31:0]         ip2bus_data_i   
);  
    //initialize outputs
    initial begin
        bus2ip_addr_o  = {32{1'bx}};
        bus2ip_data_o  = {32{1'bx}};
        bus2ip_rd_ce_o = 1'b0;         
        bus2ip_wr_ce_o = 1'b0;        
    end

    //tasks for register read
    task read_reg;
        input  [31:0] rd_addr;
        output [31:0] rd_data;

    begin
        force bus2ip_rd_ce_o = 1'b0;
        force bus2ip_addr_o = 32'h0;

        @(posedge bus2ip_clk) begin
            force bus2ip_rd_ce_o = 1'b1;
            force bus2ip_addr_o = rd_addr; 
        end

        @(posedge bus2ip_clk);
        @(posedge bus2ip_clk);

        @(posedge bus2ip_clk) 
        rd_data = ip2bus_data_i;

        @(posedge bus2ip_clk);
     
        @(posedge bus2ip_clk);
        force bus2ip_rd_ce_o = 1'b0;  

        @(posedge bus2ip_clk);
        @(posedge bus2ip_clk);
        
        force bus2ip_addr_o = 32'h0;
         
        release bus2ip_rd_ce_o;
        release bus2ip_addr_o ;
    end
    endtask

    //tasks for register write
    task write_reg;
        input [31:0] wr_addr;
        input [31:0] wr_data;

    begin
        force bus2ip_wr_ce_o = 0;
        force bus2ip_addr_o = 32'h0;
        force bus2ip_data_o = 32'h0;

        @(posedge bus2ip_clk) begin
            force bus2ip_wr_ce_o = 1;
            force bus2ip_addr_o = wr_addr;
            force bus2ip_data_o = wr_data;
        end

        @(posedge bus2ip_clk);

        @(posedge bus2ip_clk) begin
            force bus2ip_wr_ce_o = 0;
            force bus2ip_addr_o = 32'h0;
            force bus2ip_data_o = 32'h0;
        end

        release bus2ip_wr_ce_o;
        release bus2ip_addr_o;
        release bus2ip_data_o; 
    end
    endtask

endmodule
