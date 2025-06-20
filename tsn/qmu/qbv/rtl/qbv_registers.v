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
 *  Description : QBV control and status registers
 *  File        : qbv_registers.v
-*/

`include "qbv_defines.v"

module qbv_registers
(
    input                   clk,
    input                   rst_n,
    input  [31:0]           bus2ip_addr_i,
    input  [31:0]           bus2ip_data_i,
    input  [ 3:0]           bus2ip_wstrb_i,
    input                   bus2ip_rd_ce_i,
    input                   bus2ip_wr_ce_i,
    output [31:0]           ip2bus_data_o,
    output                  ip2bus_ready_o,

    // QBV specific outputs 
    output                  qbv_cfg_enable_o,
    output [31:0]           qbv_state_o,
    output [31:0]           qbv_actd_o,
    output [31:0]           qbv_abtn_o,
    output                  intr_o
);

    wire blk_sel_w  = ((bus2ip_addr_i & `QBV_ADDR_MASK) == `QBV_REG_BASEADDR);
    wire write_en_w = bus2ip_wr_ce_i & ip2bus_ready_o;
    wire read_en_w  = bus2ip_rd_ce_i & ip2bus_ready_o;

    // QBV_CFG Register
    wire cfg_sel_w = (bus2ip_addr_i[15:0] == `QBV_CFG) & blk_sel_w;
    reg  [31:0] qbv_cfg_q;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            qbv_cfg_q <= `QBV_CFG_DEFAULT;
        else if (write_en_w && cfg_sel_w) begin
            if (bus2ip_wstrb_i[0]) qbv_cfg_q[ 7: 0] <= bus2ip_data_i[ 7: 0];
            if (bus2ip_wstrb_i[1]) qbv_cfg_q[15: 8] <= bus2ip_data_i[15: 8];
            if (bus2ip_wstrb_i[2]) qbv_cfg_q[23:16] <= bus2ip_data_i[23:16];
            if (bus2ip_wstrb_i[3]) qbv_cfg_q[31:24] <= bus2ip_data_i[31:24];
        end
    end
    assign qbv_cfg_enable_o = qbv_cfg_q[0];

    // QBV_STATE Register
    wire state_sel_w = (bus2ip_addr_i[15:0] == `QBV_STATE) & blk_sel_w;
    reg  [31:0] qbv_state_q;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            qbv_state_q <= `QBV_STATE_DEFAULT;
        else if (write_en_w && state_sel_w) begin
            if (bus2ip_wstrb_i[0]) qbv_state_q[ 7: 0] <= bus2ip_data_i[ 7: 0];
            if (bus2ip_wstrb_i[1]) qbv_state_q[15: 8] <= bus2ip_data_i[15: 8];
            if (bus2ip_wstrb_i[2]) qbv_state_q[23:16] <= bus2ip_data_i[23:16];
            if (bus2ip_wstrb_i[3]) qbv_state_q[31:24] <= bus2ip_data_i[31:24];
        end
    end
    assign qbv_state_o = qbv_state_q;

    // QBV_ACTD Register
    wire actd_sel_w = (bus2ip_addr_i[15:0] == `QBV_ACTD) & blk_sel_w;
    reg  [31:0] qbv_actd_q;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            qbv_actd_q <= `QBV_ACTD_DEFAULT;
        else if (write_en_w && actd_sel_w) begin
            if (bus2ip_wstrb_i[0]) qbv_actd_q[ 7: 0] <= bus2ip_data_i[ 7: 0];
            if (bus2ip_wstrb_i[1]) qbv_actd_q[15: 8] <= bus2ip_data_i[15: 8];
            if (bus2ip_wstrb_i[2]) qbv_actd_q[23:16] <= bus2ip_data_i[23:16];
            if (bus2ip_wstrb_i[3]) qbv_actd_q[31:24] <= bus2ip_data_i[31:24];
        end
    end
    assign qbv_actd_o = qbv_actd_q;

    // QBV_ABTN Register
    wire abtn_sel_w = (bus2ip_addr_i[15:0] == `QBV_ABTN) & blk_sel_w;
    reg  [31:0] qbv_abtn_q;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            qbv_abtn_q <= 32'd0;
        else if (write_en_w && abtn_sel_w) begin
            if (bus2ip_wstrb_i[0]) qbv_abtn_q[ 7: 0] <= bus2ip_data_i[ 7: 0];
            if (bus2ip_wstrb_i[1]) qbv_abtn_q[15: 8] <= bus2ip_data_i[15: 8];
            if (bus2ip_wstrb_i[2]) qbv_abtn_q[23:16] <= bus2ip_data_i[23:16];
            if (bus2ip_wstrb_i[3]) qbv_abtn_q[31:24] <= bus2ip_data_i[31:24];
        end
    end
    assign qbv_abtn_o = qbv_abtn_q;

    // Interrupt output (example: based on a bit in state register)
    assign intr_o = qbv_state_q[0];

    // Read mux
    reg [31:0] ip2bus_data_r;
    always @(*) begin
        case (bus2ip_addr_i[15:0])
            `QBV_CFG:   ip2bus_data_r = qbv_cfg_q;
            `QBV_STATE: ip2bus_data_r = qbv_state_q;
            `QBV_ACTD:  ip2bus_data_r = qbv_actd_q;
            `QBV_ABTN:  ip2bus_data_r = qbv_abtn_q;
            default:    ip2bus_data_r = 32'd0;
        endcase
    end
    assign ip2bus_data_o = ip2bus_data_r;

    // Always ready (can be improved for wait states)
    assign ip2bus_ready_o = 1'b1;

endmodule
