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
 * Description : QBV Control List with Ping-Pong Buffer
 *               Instantiates two qbv_dpram blocks for admin and operative control lists.
 *               Ping-pong switching is controlled by OperControlListPopulated_i.
 * File        : qbv_control_list.v
-*/

module qbv_control_list 
#(
    parameter ADDR_WIDTH = 9,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 512
) 
(
    // Admin port
    input                   admin_clk,
    input                   admin_rst_n,
    input  [ADDR_WIDTH-1:0] admin_addr_i,
    input  [DATA_WIDTH-1:0] admin_data_i,
    input  [3:0]            admin_wr_i,
    output [DATA_WIDTH-1:0] admin_data_o,
    input  [ADDR_WIDTH-1:0] reg_oper_addr_i,
    output [DATA_WIDTH-1:0] reg_oper_data_o,

    // Oper port
    input                   oper_clk,
    input                   oper_rst_n,
    input  [ADDR_WIDTH-1:0] oper_addr_i,
    output [DATA_WIDTH-1:0] oper_data_o,

    input                   OperControlListPopulated_i
);

    // Two DPRAMs: one for admin, one for oper
    wire [DATA_WIDTH-1:0] dpram0_admin_data_o, dpram0_oper_data_o;
    wire [DATA_WIDTH-1:0] dpram1_admin_data_o, dpram1_oper_data_o;

    // Synchronize OperControlListPopulated_i to oper_clk domain 
    // and toggle admin_sel_q on its rising edge
    reg [2:0] oper_ctrl_sync;
    always @(posedge oper_clk or negedge oper_rst_n) begin
        if (!oper_rst_n)
            oper_ctrl_sync <= 3'b000;
        else
            oper_ctrl_sync <= {oper_ctrl_sync[1:0], OperControlListPopulated_i};
    end

    wire oper_ctrl_posedge = (oper_ctrl_sync[1:0] == 2'b01);

    reg admin_sel_q;
    always @(posedge oper_clk or negedge oper_rst_n) begin
        if (!oper_rst_n)
            admin_sel_q <= 1'b0;
        else if (oper_ctrl_posedge)
            admin_sel_q <= ~admin_sel_q;
    end

    // DPRAM0
    wire [3:0] dpram0_admin_wr = admin_sel_q ? 4'b0 : admin_wr_i;
    wire [ADDR_WIDTH-1:0] dpram0_addr = admin_sel_q ? reg_oper_addr_i : admin_addr_i;

    qbv_dpram 
    #(
        .ADDR_WIDTH (ADDR_WIDTH), 
        .DATA_WIDTH (DATA_WIDTH), 
        .DEPTH      (DEPTH     )
    ) 
    u_dpram0 (
        .clk0      (admin_clk          ),
        .rst0_n    (admin_rst_n        ),
        .addr0_i   (dpram0_addr        ),
        .data0_i   (admin_data_i       ),
        .wr0_i     (dpram0_admin_wr    ),
        .data0_o   (dpram0_admin_data_o),
        .clk1      (oper_clk           ),
        .rst1_n    (oper_rst_n         ),
        .addr1_i   (oper_addr_i        ),
        .data1_i   ({DATA_WIDTH{1'b0}} ),
        .wr1_i     (4'b0               ),
        .data1_o   (dpram0_oper_data_o )
    );

    // DPRAM1
    wire [3:0] dpram1_admin_wr = admin_sel_q ? admin_wr_i : 4'b0;
    wire [ADDR_WIDTH-1:0] dpram1_addr = admin_sel_q ? admin_addr_i : reg_oper_addr_i;

    qbv_dpram 
    #(
        .ADDR_WIDTH (ADDR_WIDTH), 
        .DATA_WIDTH (DATA_WIDTH), 
        .DEPTH      (DEPTH     )
    ) 
    u_dpram1 (
        .clk0      (admin_clk          ),
        .rst0_n    (admin_rst_n        ),
        .addr0_i   (dpram1_addr        ),
        .data0_i   (admin_data_i       ),
        .wr0_i     (dpram1_admin_wr    ),
        .data0_o   (dpram1_admin_data_o),
        .clk1      (oper_clk           ),
        .rst1_n    (oper_rst_n         ),
        .addr1_i   (oper_addr_i        ),
        .data1_i   ({DATA_WIDTH{1'b0}} ),
        .wr1_i     (4'b0               ),
        .data1_o   (dpram1_oper_data_o )
    );

    // Ping-pong buffer selection
    // When admin_sel_q == 0: dpram0 is admin, dpram1 is oper
    // When admin_sel_q == 1: dpram1 is admin, dpram0 is oper
    assign admin_data_o    = admin_sel_q ? dpram1_admin_data_o : dpram0_admin_data_o;
    assign oper_data_o     = admin_sel_q ? dpram0_oper_data_o  : dpram1_oper_data_o;
    assign reg_oper_data_o = admin_sel_q ? dpram0_admin_data_o : dpram1_admin_data_o;

endmodule
