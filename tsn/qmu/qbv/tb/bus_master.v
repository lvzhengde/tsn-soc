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
 *  Description : Bus Master for QBV Testbench
 *                Implements bus read/write tasks for qbv_top.v
 *  File        : bus_master.v
-*/

module bus_master
(
    input                  bus2ip_clk     ,
    input                  bus2ip_rst_n   ,
    output reg  [31:0]     bus2ip_addr_o  ,
    output reg  [31:0]     bus2ip_data_o  ,
    output reg  [ 3:0]     bus2ip_wstrb_o ,
    output reg             bus2ip_rd_ce_o ,         //active high
    output reg             bus2ip_wr_ce_o ,         //active high
    input   [31:0]         ip2bus_data_i  , 
    input                  ip2bus_ready_i
);

    //++
    //_tasks for register read/write
    //--
    parameter Tp = 1;    //add Tp delay to avoid write/read simulation exception

    //tasks for register read
    task bus_read;
        input  [31:0] addr;
        output [31:0] data;

    begin
        bus2ip_rd_ce_o = 1'b0;
        bus2ip_addr_o = 32'h0;

        @(posedge bus2ip_clk) 
        #Tp;

        bus2ip_rd_ce_o = 1'b1;
        bus2ip_addr_o = addr; 

        wait(ip2bus_ready_i == 1'b1);
        @(posedge bus2ip_clk);
        #Tp;

        data = ip2bus_data_i;

        repeat(2) @(posedge bus2ip_clk);
        #Tp;
     
        bus2ip_rd_ce_o = 1'b0;  
        bus2ip_addr_o = 32'h0;
    end
    endtask

    //tasks for register write
    task bus_write;
        input [31:0] addr;
        input [31:0] data;
        input [3:0]  wstrb;

    begin
        bus2ip_wr_ce_o = 0;
        bus2ip_addr_o  = 32'h0;
        bus2ip_data_o  = 32'h0;
        bus2ip_wstrb_o = 4'h0;

        @(posedge bus2ip_clk) 
        #Tp;

        bus2ip_wr_ce_o = 1;
        bus2ip_addr_o  = addr;
        bus2ip_data_o  = data;
        bus2ip_wstrb_o = wstrb;

        wait(ip2bus_ready_i == 1'b1);
        @(posedge bus2ip_clk);  
        #Tp;

        bus2ip_wr_ce_o = 0;
        bus2ip_addr_o  = 32'h0;
        bus2ip_data_o  = 32'h0;
        bus2ip_wstrb_o = 4'h0;
    end
    endtask

endmodule
