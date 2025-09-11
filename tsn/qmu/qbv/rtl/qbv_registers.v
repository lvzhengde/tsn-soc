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
    input                   bus2ip_clk,
    input                   bus2ip_rst_n,
    input  [31:0]           bus2ip_addr_i,
    input  [31:0]           bus2ip_data_i,
    input  [ 3:0]           bus2ip_wstrb_i,
    input                   bus2ip_rd_ce_i,
    input                   bus2ip_wr_ce_i,
    output [31:0]           ip2bus_data_o,
    output                  ip2bus_ready_o,

    // QBV specific inputs 
    input  [ 5:0]           TickGranularity_i,        
    input  [ 8:0]           OperControlListLength_i,  
    input  [ 2:0]           OperGateStates_i,         
    input                   OperControlListPopulated_i, // Operative Control List Populated
    input                   ConfigPending_i, // Config Pending
    input  [79:0]           ConfigChangeTime_i, // Config Change Time, in PTP time format
    input  [31:0]           OperCycleTime_i,
    input  [31:0]           OperCycleTimeExtension_i,
    input  [79:0]           OperBaseTime_i, // Operative Base Time in PTP time format
    input  [ 7:0]           BEOverrunCount_i, // BE TX Overrun Count
    input  [ 7:0]           RSOverrunCount_i, // RES TX Overrun Count
    input  [ 7:0]           STOverrunCount_i, // ST TX Overrun Count

    // QBV specific outputs 
    output                  GateEnabled_o,            
    output                  ConfigChange_o,           
    output [ 8:0]           AdminControlListLength_o, 
    output [ 2:0]           AdminGateStates_o,        
    output [31:0]           AdminCycleTime_o,
    output [31:0]           AdminCycleTimeExtension_o,
    output [79:0]           AdminBaseTime_o, // Admin Base Time in PTP time format

    // BRAM Access Interface
    output [ 8:0]           admin_addr_o,
    output [31:0]           admin_data_o,
    output [ 3:0]           admin_wr_o,
    input  [31:0]           admin_data_i,
    output [ 8:0]           oper_addr_o,
    input  [31:0]           oper_data_i,

    // Interrupt event inputs
    input                   st_oco_i, // ST TX Overrun Count overflow
    input                   rt_oco_i, // RES TX Overrun Count overflow
    input                   bt_oco_i, // BE TX Overrun Count overflow
    input                   cc_pr_i,  // Config Change is taken for processing
    input                   cc_err_i, // Config Change Error Set
    input                   cp_clr_i, // Config Pending Cleared
    input                   cp_set_i, // Config Pending Set

    // Interrupt output
    output                  intr_o
);

    wire blk_sel_w  = ((bus2ip_addr_i & `QBV_ADDR_MASK) == `QBV_REG_BASEADDR);
    wire write_en_w = bus2ip_wr_ce_i & ip2bus_ready_o;
    wire read_en_w  = bus2ip_rd_ce_i & ip2bus_ready_o;

    // Synchronize and generate 1-cycle pulse for each interrupt event input
    reg st_oco_d0, st_oco_d1, st_oco_d2;
    reg rt_oco_d0, rt_oco_d1, rt_oco_d2;
    reg bt_oco_d0, bt_oco_d1, bt_oco_d2;
    reg cc_pr_d0,  cc_pr_d1 , cc_pr_d2 ;
    reg cc_err_d0, cc_err_d1, cc_err_d2;
    reg cp_clr_d0, cp_clr_d1, cp_clr_d2;
    reg cp_set_d0, cp_set_d1, cp_set_d2;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n) begin
            {st_oco_d0, st_oco_d1, st_oco_d2} <= 3'b0;
            {rt_oco_d0, rt_oco_d1, rt_oco_d2} <= 3'b0;
            {bt_oco_d0, bt_oco_d1, bt_oco_d2} <= 3'b0;
            {cc_pr_d0,  cc_pr_d1,  cc_pr_d2}  <= 3'b0;
            {cc_err_d0, cc_err_d1, cc_err_d2} <= 3'b0;
            {cp_clr_d0, cp_clr_d1, cp_clr_d2} <= 3'b0;
            {cp_set_d0, cp_set_d1, cp_set_d2} <= 3'b0;
        end else begin
            {st_oco_d0, st_oco_d1, st_oco_d2} <= {st_oco_i, st_oco_d0, st_oco_d1};
            {rt_oco_d0, rt_oco_d1, rt_oco_d2} <= {rt_oco_i, rt_oco_d0, rt_oco_d1};
            {bt_oco_d0, bt_oco_d1, bt_oco_d2} <= {bt_oco_i, bt_oco_d0, bt_oco_d1};
            {cc_pr_d0,  cc_pr_d1,  cc_pr_d2}  <= {cc_pr_i,  cc_pr_d0,  cc_pr_d1};
            {cc_err_d0, cc_err_d1, cc_err_d2} <= {cc_err_i, cc_err_d0, cc_err_d1};
            {cp_clr_d0, cp_clr_d1, cp_clr_d2} <= {cp_clr_i, cp_clr_d0, cp_clr_d1};
            {cp_set_d0, cp_set_d1, cp_set_d2} <= {cp_set_i, cp_set_d0, cp_set_d1};
        end
    end

    wire st_oco_pulse  =  st_oco_d1 & (~st_oco_d2);
    wire rt_oco_pulse  =  rt_oco_d1 & (~rt_oco_d2);
    wire bt_oco_pulse  =  bt_oco_d1 & (~bt_oco_d2);
    wire cc_pr_pulse   =  cc_pr_d1  & (~cc_pr_d2 );
    wire cc_err_pulse  =  cc_err_d1 & (~cc_err_d2);
    wire cp_clr_pulse  =  cp_clr_d1 & (~cp_clr_d2);
    wire cp_set_pulse  =  cp_set_d1 & (~cp_set_d2);

    // QBV_CFG Register
    // {GE, CC, 13'b0, ACLL[8:0], 5'b0, AGS[2:0]}
    wire cfg_sel_w = (bus2ip_addr_i[15:0] == `QBV_CFG) & blk_sel_w;
    reg         GateEnabled_q;            // GE
    reg         ConfigChange_q;           // CC
    reg  [8:0]  AdminControlListLength_q; // ACLL
    reg  [2:0]  AdminGateStates_q;        // AGS 

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n) begin
            GateEnabled_q            <= 1'b0;
            AdminControlListLength_q <= 9'h0; 
            AdminGateStates_q        <= 3'hf;
        end
        else if (write_en_w && cfg_sel_w) begin
            if (bus2ip_wstrb_i[3]) 
                GateEnabled_q            <= bus2ip_data_i[31];
            if (bus2ip_wstrb_i[2] & bus2ip_wstrb_i[1]) 
                AdminControlListLength_q <= bus2ip_data_i[16:8];
            if (bus2ip_wstrb_i[0]) 
                AdminGateStates_q        <= bus2ip_data_i[2:0];
        end
    end

    // ConfigChange_q is set when a write to the config register occurs
    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n) 
            ConfigChange_q <= 1'b0;
        else if (write_en_w & cfg_sel_w & bus2ip_wstrb_i[3] & (~ConfigChange_q) & GateEnabled_q) 
            ConfigChange_q  <= bus2ip_data_i[30];
        else if (cc_pr_pulse == 1'b1 || GateEnabled_q == 1'b0) 
            ConfigChange_q <= 1'b0;
    end

    assign GateEnabled_o            = GateEnabled_q;
    assign ConfigChange_o           = ConfigChange_q;
    assign AdminControlListLength_o = AdminControlListLength_q;
    assign AdminGateStates_o        = AdminGateStates_q;

    wire [31:0] qbv_cfg_w = {
        GateEnabled_q, 
        ConfigChange_q, 
        13'b0, 
        AdminControlListLength_q, 
        5'b0, 
        AdminGateStates_q
    };

    // QBV_STATE Register
    // {2'b0, TG[5:0], 7'b0, OCLL[8:0], 5'b0, OGS[2:0]}
    wire state_sel_w = (bus2ip_addr_i[15:0] == `QBV_STATE) & blk_sel_w;
    
    wire [31:0] qbv_state_w = {
        2'b0, 
        TickGranularity_i, 
        7'b0, 
        OperControlListLength_i, 
        5'b0, 
        OperGateStates_i
    };

    // QBV_ACTD Register
    // Admin Cycle Time in nanoseconds, corresponds to 1/N second.
    wire actd_sel_w = (bus2ip_addr_i[15:0] == `QBV_ACTD) & blk_sel_w;
    reg  [31:0] qbv_actd_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            qbv_actd_q <= 32'h0;
        else if (write_en_w && actd_sel_w) begin
            if (bus2ip_wstrb_i[0]) qbv_actd_q[ 7: 0] <= bus2ip_data_i[ 7: 0];
            if (bus2ip_wstrb_i[1]) qbv_actd_q[15: 8] <= bus2ip_data_i[15: 8];
            if (bus2ip_wstrb_i[2]) qbv_actd_q[23:16] <= bus2ip_data_i[23:16];
            if (bus2ip_wstrb_i[3]) qbv_actd_q[31:24] <= bus2ip_data_i[31:24];
        end
    end
    assign AdminCycleTime_o = qbv_actd_q; 

    // QBV_ACTE Register
    // Admin Cycle Time Extension in nanoseconds
    wire acte_sel_w = (bus2ip_addr_i[15:0] == `QBV_ACTE) & blk_sel_w;
    reg  [31:0] qbv_acte_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            qbv_acte_q <= 32'd0;
        else if (write_en_w && acte_sel_w) begin
            if (bus2ip_wstrb_i[0]) qbv_acte_q[ 7: 0] <= bus2ip_data_i[ 7: 0];
            if (bus2ip_wstrb_i[1]) qbv_acte_q[15: 8] <= bus2ip_data_i[15: 8];
            if (bus2ip_wstrb_i[2]) qbv_acte_q[23:16] <= bus2ip_data_i[23:16];
            if (bus2ip_wstrb_i[3]) qbv_acte_q[31:24] <= bus2ip_data_i[31:24];
        end
    end

    assign AdminCycleTimeExtension_o = qbv_acte_q;

    // QBV_ABTN Register 
    wire abtn_sel_w = (bus2ip_addr_i[15:0] == `QBV_ABTN) & blk_sel_w;
    reg  [31:0] qbv_abtn_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            qbv_abtn_q <= 32'd0;
        else if (write_en_w && abtn_sel_w) begin
            if (bus2ip_wstrb_i[0]) qbv_abtn_q[ 7: 0] <= bus2ip_data_i[ 7: 0];
            if (bus2ip_wstrb_i[1]) qbv_abtn_q[15: 8] <= bus2ip_data_i[15: 8];
            if (bus2ip_wstrb_i[2]) qbv_abtn_q[23:16] <= bus2ip_data_i[23:16];
            if (bus2ip_wstrb_i[3]) qbv_abtn_q[31:24] <= bus2ip_data_i[31:24];
        end
    end
    assign qbv_abtn_o = qbv_abtn_q;

    // QBV_ABTSL Register (32 bits)
    wire abtsl_sel_w = (bus2ip_addr_i[15:0] == `QBV_ABTSL) & blk_sel_w;
    reg [31:0] qbv_abtsl_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            qbv_abtsl_q <= 32'd0;
        else if (write_en_w && abtsl_sel_w) begin
            if (bus2ip_wstrb_i[0]) qbv_abtsl_q[ 7: 0] <= bus2ip_data_i[ 7: 0];
            if (bus2ip_wstrb_i[1]) qbv_abtsl_q[15: 8] <= bus2ip_data_i[15: 8];
            if (bus2ip_wstrb_i[2]) qbv_abtsl_q[23:16] <= bus2ip_data_i[23:16];
            if (bus2ip_wstrb_i[3]) qbv_abtsl_q[31:24] <= bus2ip_data_i[31:24];
        end
    end

    // QBV_ABTSH Register (16 bits, upper 16 bits zero)
    wire abtsh_sel_w = (bus2ip_addr_i[15:0] == `QBV_ABTSH) & blk_sel_w;
    reg [15:0] qbv_abtsh_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            qbv_abtsh_q <= 16'd0;
        else if (write_en_w && abtsh_sel_w) begin
            if (bus2ip_wstrb_i[0]) qbv_abtsh_q[ 7: 0] <= bus2ip_data_i[ 7: 0];
            if (bus2ip_wstrb_i[1]) qbv_abtsh_q[15: 8] <= bus2ip_data_i[15: 8];
        end
    end

    wire [31:0] qbv_abtsh_w = {16'd0, qbv_abtsh_q};

    // Concatenate to form 80-bit Admin Base Time
    wire [79:0] AdminBaseTime_o = {qbv_abtsh_q, qbv_abtsl_q, qbv_abtn_q}; 

    // Interrupt Status Register (QBV_ISR)
    // Bit mapping: {13'b0, ST_OCO, RT_OCO, BT_OCO, 12'b0, CC_PR, CC_ERR, CP_CLR, CP_SET}
    reg [31:0] qbv_isr_q;
    wire [6:0] isr_pulse_w = {st_oco_pulse, rt_oco_pulse, bt_oco_pulse, cc_pr_pulse, cc_err_pulse, cp_clr_pulse, cp_set_pulse};

    wire isr_sel_w  = (bus2ip_addr_i[15:0] == `QBV_ISR) & blk_sel_w;
    wire ier_sel_w  = (bus2ip_addr_i[15:0] == `QBV_IER) & blk_sel_w;
    wire icr_sel_w  = (bus2ip_addr_i[15:0] == `QBV_ICR) & blk_sel_w;

    // Interrupt Enable Register (QBV_IER)
    reg [31:0] qbv_ier_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            qbv_ier_q <= 32'd0;
        else if (write_en_w && ier_sel_w)
            qbv_ier_q <= bus2ip_data_i;
    end

    // Interrupt Clear Register (QBV_ICR) - write 1 to clear corresponding ISR bit
    // Write logic for ISR (set by pulse, cleared by ICR write)
    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            qbv_isr_q <= 32'd0;
        else begin
            // Set bits on pulse
            if (isr_pulse_w[6]) qbv_isr_q[18] <= 1'b1; // ST_OCO
            if (isr_pulse_w[5]) qbv_isr_q[17] <= 1'b1; // RT_OCO
            if (isr_pulse_w[4]) qbv_isr_q[16] <= 1'b1; // BT_OCO
            if (isr_pulse_w[3]) qbv_isr_q[3]  <= 1'b1; // CC_PR
            if (isr_pulse_w[2]) qbv_isr_q[2]  <= 1'b1; // CC_ERR
            if (isr_pulse_w[1]) qbv_isr_q[1]  <= 1'b1; // CP_CLR
            if (isr_pulse_w[0]) qbv_isr_q[0]  <= 1'b1; // CP_SET
            // Clear bits on ICR write
            if (write_en_w && icr_sel_w && bus2ip_wstrb_i[2]) begin
                if (bus2ip_data_i[18]) qbv_isr_q[18] <= 1'b0;
                if (bus2ip_data_i[17]) qbv_isr_q[17] <= 1'b0;
                if (bus2ip_data_i[16]) qbv_isr_q[16] <= 1'b0;
            end
            if (write_en_w && icr_sel_w && bus2ip_wstrb_i[0]) begin
                if (bus2ip_data_i[7])  qbv_isr_q[3]  <= 1'b0;
                if (bus2ip_data_i[6])  qbv_isr_q[2]  <= 1'b0;
                if (bus2ip_data_i[5])  qbv_isr_q[1]  <= 1'b0;
                if (bus2ip_data_i[4])  qbv_isr_q[0]  <= 1'b0;
            end
        end
    end

    // Interrupt output: any enabled and active ISR bit
    assign intr_o = |(qbv_isr_q & qbv_ier_q);

    // QBV Status Register
    wire [31:0] qbv_status_w = {
        30'b0, // Reserved bits
        OperControlListPopulated_i, // Bit 1: Operative Control List Populated
        ConfigPending_i // Bit 0: Config Pending
    };

    // QBV_ACLE_BASE register block: access external BRAM (admin)
    // Address range: QBV_ACLE_BASE + 0x0 ~ QBV_ACLE_BASE + 0x3FC (256 x 4 bytes)
    // Each access is 32 bits wide, 256 depth
    // Write: bus2ip_addr_i[9:2] is BRAM address (8 bits), bus2ip_data_i is data, bus2ip_wstrb_i is byte enables
    // Read: bus2ip_addr_i[9:2] is BRAM address, admin_data_i is read data

    // Address decode for admin BRAM
    wire admin_bram_sel_w = ((bus2ip_addr_i[15:0] & 16'hFF00) == (`QBV_ACLE_BASE & 16'hFF00)) & blk_sel_w;
    wire [7:0] admin_bram_addr_w = bus2ip_addr_i[9:2];

    // Registered outputs for BRAM access
    reg [7:0]  admin_addr_q;
    reg [31:0] admin_data_q;
    reg [3:0]  admin_wr_q;

    // Access logic for admin BRAM
    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n) begin
            admin_addr_q <= 8'd0;
            admin_data_q <= 32'd0;
            admin_wr_q   <= 4'd0;
        end else begin
            if (bus2ip_wr_ce_i && admin_bram_sel_w) begin
                admin_addr_q <= admin_bram_addr_w;
                admin_data_q <= bus2ip_data_i;
                admin_wr_q   <= bus2ip_wstrb_i;
            end else if (bus2ip_rd_ce_i && admin_bram_sel_w) begin
                admin_addr_q <= admin_bram_addr_w; // Keep address for read
                admin_data_q <= 32'd0;             // No data output on read
                admin_wr_q   <= 4'd0;              // No write enable on read
            end else begin
                admin_wr_q   <= 4'd0; // Only pulse for one cycle
            end
        end
    end

    // Connect outputs
    assign admin_addr_o = admin_addr_q;
    assign admin_data_o = admin_data_q;
    assign admin_wr_o   = admin_wr_q;

    // QBV_OCLE_BASE register block: access external BRAM (operative, read-only)
    // Address range: QBV_OCLE_BASE + 0x0 ~ QBV_OCLE_BASE + 0x3FC (256 x 4 bytes)
    // Each access is 32 bits wide, 256 depth
    // Read: bus2ip_addr_i[9:2] is BRAM address, oper_data_i is read data

    // Address decode for oper BRAM
    wire oper_bram_sel_w = ((bus2ip_addr_i[15:0] & 16'hFF00) == (`QBV_OCLE_BASE & 16'hFF00)) & blk_sel_w;
    wire [7:0] oper_bram_addr_w = bus2ip_addr_i[9:2];

    // Registered output for BRAM address
    reg [7:0] oper_addr_q;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            oper_addr_q <= 8'd0;
        else if ((bus2ip_rd_ce_i || bus2ip_wr_ce_i) && oper_bram_sel_w)
            oper_addr_q <= oper_bram_addr_w;
    end

    assign oper_addr_o = oper_addr_q;

    // Read mux for IPBus: returns read data for all registers
    reg [31:0] ip2bus_data_r;
    always @(*) begin
        // Default
        ip2bus_data_r = 32'd0;
        // Admin BRAM read
        if (admin_bram_sel_w && bus2ip_rd_ce_i)
            ip2bus_data_r = admin_data_i;
        // Oper BRAM read
        else if (oper_bram_sel_w && bus2ip_rd_ce_i)
            ip2bus_data_r = oper_data_i;
        else begin
            case (bus2ip_addr_i[15:0])
                `QBV_CFG:     ip2bus_data_r = qbv_cfg_w;
                `QBV_STATE:   ip2bus_data_r = qbv_state_w;
                `QBV_ACTD:    ip2bus_data_r = qbv_actd_q;
                `QBV_ACTE:    ip2bus_data_r = qbv_acte_q;
                `QBV_ABTN:    ip2bus_data_r = qbv_abtn_q;
                `QBV_ABTSL:   ip2bus_data_r = qbv_abtsl_q;
                `QBV_ABTSH:   ip2bus_data_r = qbv_abtsh_w;
                `QBV_ISR:     ip2bus_data_r = qbv_isr_q;
                `QBV_IER:     ip2bus_data_r = qbv_ier_q;
                `QBV_ICR:     ip2bus_data_r = 32'd0;
                `QBV_STATUS:  ip2bus_data_r = qbv_status_w;
                `QBV_CCTN:    ip2bus_data_r = ConfigChangeTime_i[31:0]; 
                `QBV_CCTSL:   ip2bus_data_r = ConfigChangeTime_i[63:32]; 
                `QBV_CCTSH:   ip2bus_data_r = {16'b0, ConfigChangeTime_i[79:64]};
                `QBV_OCTD:    ip2bus_data_r = OperCycleTime_i;
                `QBV_OCTE:    ip2bus_data_r = OperCycleTimeExtension_i;
                `QBV_OBTN:    ip2bus_data_r = OperBaseTime_i[31:0];
                `QBV_OBTSL:   ip2bus_data_r = OperBaseTime_i[63:32];
                `QBV_OBTSH:   ip2bus_data_r = {16'b0, OperBaseTime_i[79:64]};
                `QBV_BETC:    ip2bus_data_r = {24'b0, BEOverrunCount_i};
                `QBV_RSTC:    ip2bus_data_r = {24'b0, RSOverrunCount_i};
                `QBV_STTC:    ip2bus_data_r = {24'b0, STOverrunCount_i};
                default:      ip2bus_data_r = 32'd0;
            endcase
        end
    end

    // Register ip2bus_data_o output for timing
    reg [31:0] ip2bus_data_q;
    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n)
            ip2bus_data_q <= 32'd0;
        else
            ip2bus_data_q <= ip2bus_data_r;
    end

    // Delay bus2ip_wr_ce_i and bus2ip_rd_ce_i by one clock cycle
    reg bus2ip_wr_ce_d;
    reg bus2ip_rd_ce_d;

    always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n) begin
            bus2ip_wr_ce_d <= 1'b0;
            bus2ip_rd_ce_d <= 1'b0;
        end else begin
            bus2ip_wr_ce_d <= bus2ip_wr_ce_i;
            bus2ip_rd_ce_d <= bus2ip_rd_ce_i;
        end
    end

    // Generate ip2bus_ready_o: active high for one cycle after a valid read or write access
    // For BRAM accesses, ready is asserted only when address and data are registered 
    reg ip2bus_ready_q;

     always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
        if (!bus2ip_rst_n) 
            ip2bus_ready_q <= 1'b0;
        else if (ip2bus_ready_o & (bus2ip_rd_ce_i | bus2ip_wr_ce_i))
            ip2bus_ready_q <= 1'b0;
        else if ((admin_bram_sel_w || oper_bram_sel_w) && (bus2ip_wr_ce_d | bus2ip_rd_ce_d))
            ip2bus_ready_q <= 1'b1; // Ready for BRAM access
        else if (bus2ip_rd_ce_i | bus2ip_wr_ce_i)
            ip2bus_ready_q <= 1'b1;
    end   

    assign ip2bus_data_o  = ip2bus_data_q;
    assign ip2bus_ready_o = ip2bus_ready_q;
endmodule
