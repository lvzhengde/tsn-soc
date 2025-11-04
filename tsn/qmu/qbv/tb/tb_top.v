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
 * Description : Testbench for QBV Top
 *               Instantiates qbv_top and bus function modules, generates clocks and resets.
 * File        : tb_top.v
-*/

`timescale 1ns/1ps

module tb_top;
    // Parameters
    localparam BUS_CLK_PERIOD  = 10;
    localparam OPER_CLK_PERIOD = 8;

    // Clock and reset signals
    wire bus_clk;
    wire bus_rst_n;
    wire oper_clk;
    wire oper_rst_n;

     clk_rst_gen 
    #(
        .BUS_CLK_PERIOD  (BUS_CLK_PERIOD),
        .OPER_CLK_PERIOD (OPER_CLK_PERIOD)
    ) 
    u_clk_rst_gen
    (
        .bus_clk     (bus_clk   ),
        .bus_rst_n   (bus_rst_n ),
        .oper_clk    (oper_clk  ),
        .oper_rst_n  (oper_rst_n)
    );

    // Bus signals for qbv_registers
    reg  [31:0] bus2ip_addr_w ;
    reg  [31:0] bus2ip_data_w ;
    reg  [3:0]  bus2ip_wstrb_w;
    reg         bus2ip_rd_ce_w;
    reg         bus2ip_wr_ce_w;
    wire [31:0] ip2bus_data_w ;
    wire        ip2bus_ready_w;

    bus_master u_bus_master
    (
        .bus2ip_clk         (bus_clk       ),
        .bus2ip_rst_n       (bus_rst_n     ),
        .bus2ip_addr_o      (bus2ip_addr_w ),
        .bus2ip_data_o      (bus2ip_data_w ),
        .bus2ip_wstrb_o     (bus2ip_wstrb_w),
        .bus2ip_rd_ce_o     (bus2ip_rd_ce_w),
        .bus2ip_wr_ce_o     (bus2ip_wr_ce_w),
        .ip2bus_data_i      (ip2bus_data_w ),
        .ip2bus_ready_i     (ip2bus_ready_w)
    );

    // Instantiate Device Under Test (qbv_top)
    wire  [ 7:0]           BEOverrunCount_w; 
    wire  [ 7:0]           RSOverrunCount_w; 
    wire  [ 7:0]           STOverrunCount_w; 
    wire                   st_oco_w; 
    wire                   rt_oco_w; 
    wire                   bt_oco_w; 
    wire  [79:0]           CurrentTime_w   ;
    wire  [2:0]            OperGateStates_w;
    wire  [19:0]           ExitTimer_w     ;

    qbv_top 
    #(
        .ADDR_WIDTH (9  ),
        .DATA_WIDTH (32 ),
        .DEPTH      (512)
    )
    u_qbv_top
    (
        // Register (admin) clock domain
        .bus2ip_clk            (bus_clk        ),
        .bus2ip_rst_n          (bus_rst_n      ),
        .bus2ip_addr_i         (bus2ip_addr_w  ),
        .bus2ip_data_i         (bus2ip_data_w  ),
        .bus2ip_wstrb_i        (bus2ip_wstrb_w ),
        .bus2ip_rd_ce_i        (bus2ip_rd_ce_w ),
        .bus2ip_wr_ce_i        (bus2ip_wr_ce_w ),
        .ip2bus_data_o         (ip2bus_data_w  ),
        .ip2bus_ready_o        (ip2bus_ready_w ),

        .BEOverrunCount_i      (BEOverrunCount_w), 
        .RSOverrunCount_i      (RSOverrunCount_w), 
        .STOverrunCount_i      (STOverrunCount_w), 
        .st_oco_i              (st_oco_w        ), 
        .rt_oco_i              (rt_oco_w        ), 
        .bt_oco_i              (bt_oco_w        ), 

        // STSM (oper) clock domain
        .oper_clk              (oper_clk       ),
        .oper_rst_n            (oper_rst_n     ),
        .CurrentTime_i         (CurrentTime_w  ),

        // Outputs from STSM
        .OperGateStates_o      (OperGateStates_w),
        .ExitTimer_o           (ExitTimer_w     )
    );

endmodule
