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
 * Description : QBV Scheduled Traffic State Machines
 *               This file implements the Scheduled Traffic State Machines (STSM) as described
 *               in IEEE 802.1Qbv section 8.6.9.
 * File        : qbv_stsm.v
-*/

`include "qbv_defines.v"

module qbv_stsm
(
    input               clk,            
    input               rst_n,          

    input               GateEnabled_i,    // State machine enable signal
    input   [79:0]      CurrentTime_i,    // 80-bit current time (48-bit seconds + 32-bit nanoseconds)
    input               ConfigChange_i,   // Config change trigger signal
    input   [79:0]      AdminBaseTime_i,  // Admin base time
    input   [ 1:0]      AdminCycleTimeNumerator_i, //Admin cycle time numerator, supported values: 1, 2, 3
    input   [31:0]      AdminCycleTime_i, // Admin cycle time nanoseconds, corresponds to 1/N second
    input   [31:0]      AdminCycleTimeExtension_i,   // Admin cycle time extension
    input   [7:0]       AdminGateStates_i,// Admin gate initial state
    input   [31:0]      AdminControlListLength_i,    // Admin control list length
    input   [ 5:0]      TickGranularity_i,        

    output  [ 8:0]      OperControlListLength_o,  
    output  [ 2:0]      OperGateStates_o,         
    output  [19:0]      ExitTimer_o,       // Exit timer value
    output              OperControlListPopulated_o, // Operative Control List Populated
    output              ConfigPending_o,    // Config Pending
    output  [79:0]      ConfigChangeTime_o, // Config Change Time, in PTP time format
    output  [ 1:0]      OperCycleTimeNumerator_o, // Operative Cycle Time Numerator
    output  [31:0]      OperCycleTime_o,
    output  [31:0]      OperCycleTimeExtension_o,
    output  [79:0]      OperBaseTime_o,     // Operative Base Time in PTP time format

    output              cc_process_o,       // Config Change is taken for processing
    output [ 8:0]       oper_addr_o,
    input  [31:0]       oper_data_i
);
    localparam SC2NS  = 32'd10_0000_0000;  //1 seconds = 10^9 nanoseconds

    // =====================================================
    // State encoding definitions
    // =====================================================
    // Cycle Timer State Machine (CTSM)
    localparam [1:0] CT_IDLE           = 2'b00;
    localparam [1:0] CT_SET_START_TIME = 2'b01;
    localparam [1:0] CT_START_CYCLE    = 2'b10;
    reg [1:0] ct_cstate_q; 
    reg [1:0] ct_nstate_r;
    
    // List Execution State Machine (LESM)
    localparam [2:0] LE_INIT           = 3'b000;
    localparam [2:0] LE_NEW_CYCLE      = 3'b001;
    localparam [2:0] LE_EXECUTE_CYCLE  = 3'b010;
    localparam [2:0] LE_DELAY          = 3'b011;
    localparam [2:0] LE_END_OF_CYCLE   = 3'b100;
    reg [2:0] le_cstate_q; 
    reg [2:0] le_nstate_r;
    
    // List Config State Machine (LCSM)
    localparam [1:0] LC_CONFIG_IDLE    = 2'b00;
    localparam [1:0] LC_CONFIG_PENDING = 2'b01;
    localparam [1:0] LC_UPDATE_CONFIG  = 2'b10;
    reg [1:0] lc_cstate_q; 
    reg [1:0] lc_nstate_r;
    
    // =====================================================
    // State machine shared variables
    // =====================================================
    reg  [79:0]  OperBaseTime_q;
    reg  [ 1:0]  OperCycleTimeNumerator_q;
    reg  [31:0]  OperCycleTime_q,
    reg  [31:0]  OperCycleTimeExtension_q;
    reg  [ 7:0]  OperGateStates_q;
    reg  [ 8:0]  OperControlListLength_q;
    reg  [ 8:0]  ListPointer_q;
    reg  [19:0]  ExitTimer_q;
    reg          CycleStart_q;
    reg          NewConfigCT_q;
    reg          ConfigPending_q;

    // =====================================================
    // Cycle Timer State Machine (CTSM)
    // =====================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            ct_cstate_q <= CT_IDLE;
        else if (!GateEnabled_i || NewConfigCT_q) 
            ct_cstate_q <= CT_IDLE;
        else 
            ct_cstate_q <= ct_nstate_r;
    end
    
    always @(*) begin
        ct_nstate_r = ct_cstate_q;
        
        case (ct_cstate_q)
            CT_IDLE: begin
                ct_nstate_r = CT_SET_START_TIME;
            end
            
            CT_SET_START_TIME: begin
                if (CycleStartTime_q <= CurrentTime_i) begin
                    ct_nstate_r = CT_START_CYCLE;
                end
            end
            
            CT_START_CYCLE: begin
                ct_nstate_r = CT_SET_START_TIME;
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            CycleStart_q <= 0;
        else if (ct_cstate_q == CT_IDLE) 
            CycleStart_q <= 0;
        else if (ct_cstate_q == CT_START_CYCLE) 
            CycleStart_q <= 1;
        else if (le_cstate_q == LE_NEW_CYCLE) 
            CycleStart_q <= 0;
    end 
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            NewConfigCT_q <= 0;
        else if (ct_cstate_q == CT_IDLE) 
             NewConfigCT_q <= 0;
        else if (lc_cstate_q == LC_UPDATE_CONFIG) 
            NewConfigCT_q <= 1;
    end

    // Cycle start time calculation (SetCycleStartTime())
    reg [79:0] CycleStartTime_r;
    reg [79:0] CycleStartTime_q;
    reg        SetCycleStartTime_r;
    reg        SetCycleStartTime_q;

    //AdminCycleTime_i expressed in nanoseconds, corresponds to 1/N second
    //so 1 second is integral times of AdminCycleTime_i, just operate on ns parts is enough 
    reg  [47:0] OperBaseTimeSec_r; 
    reg  [47:0] OperBaseTimeSec_q; 
    reg  [31:0] ct_dividend_r; 
    reg  [31:0] ct_dividend_q; 
    reg         ct_div_start_r; 
    reg         ct_div_start_q; 

    always @(*) begin 
        OperBaseTimeSec_r = OperBaseTimeSec_q;
        ct_dividend_r = ct_dividend_q;

        if (!ConfigPending_q && (OperBaseTime_q < CurrentTime_i) && !lc_div_start_q) begin
            if (OperBaseTime_q[79:32] == CurrentTime_i[79:32]) begin
                OperBaseTimeSec_r = OperBaseTime_q[79:32];
                ct_dividend_r     = CurrentTime_i[31:0] - OperBaseTime_q[31:0];
            end else if (OperBaseTime_q[79:32] < (CurrentTime_i[79:32] - OperCycleTimeNumerator_q)) begin
                OperBaseTimeSec_r = CurrentTime_i[79:32] - OperCycleTimeNumerator_q;
                ct_dividend_r = CurrentTime_i[31:0] - OperBaseTime_q[31:0] 
                                + OperCycleTimeDenominator_q * SC2NS;
            end else begin
                OperBaseTimeSec_r = OperBaseTime_q[79:32];
                ct_dividend_r = CurrentTime_i[31:0] - OperBaseTime_q[31:0]
                                + (CurrentTime_i[79:32] - OperBaseTime_q[79:32]) * SC2NS;
            end
        end else if (ConfigPending_q && !lc_div_start_q && (OperBaseTime_q < CurrentTime_i) &&
                     (ConfigChangeTime_q > (CurrentTime_i + OperCycleTime_q + OperCycleTimeExtension_q))) begin
            if (OperBaseTime_q[79:32] == CurrentTime_i[79:32]) begin
                OperBaseTimeSec_r = OperBaseTime_q[79:32];
                ct_dividend_r     = CurrentTime_i[31:0] - OperBaseTime_q[31:0];
            end else if (OperBaseTime_q[79:32] < (CurrentTime_i[79:32] - OperCycleTimeNumerator_q)) begin
                OperBaseTimeSec_r = CurrentTime_i[79:32] - OperCycleTimeNumerator_q;
                ct_dividend_r = CurrentTime_i[31:0] - OperBaseTime_q[31:0] 
                                + OperCycleTimeDenominator_q * SC2NS;
            end else begin
                OperBaseTimeSec_r = OperBaseTime_q[79:32];
                ct_dividend_r = CurrentTime_i[31:0] - OperBaseTime_q[31:0]
                                + (CurrentTime_i[79:32] - OperBaseTime_q[79:32]) * SC2NS;
            end
        end 
    end

    always @(*) begin
        CycleStartTime_r    = CycleStartTime_q; 
        SetCycleStartTime_r = SetCycleStartTime_q; 
        ct_div_start_r      = ct_div_start_q;
        
        if (ct_cstate_q == CT_SET_START_TIME && SetCycleStartTime_q == 1'b0) begin
            if (!ConfigPending_q && (OperBaseTime_q >= CurrentTime_i)) begin
                //OperBaseTime specifies the current time or a future time
                CycleStartTime_r = OperBaseTime_q;
                SetCycleStartTime_r = 1'b1;
            end else if (!ConfigPending_q && (OperBaseTime_q < CurrentTime_i)) begin
                //OperBaseTime specifies a time in the past
                //Calculate minimum N: (OperBaseTime + N*OperCycleTime) >= CurrentTime
                if (ct_div_complete_d1) begin
                    CycleStartTime_r[79:32] = OperBaseTimeSec_q[47:0] + Nct_mul_CycleTime_sec_q;
                    CycleStartTime_r[31:0]  = Nct_mul_CycleTime_ns_q;
                    ct_div_start_r = 1'b0;
                    SetCycleStartTime_r = 1'b1;
                end else if (!ct_div_start_q) begin
                    ct_div_start_r = 1'b1;
                end else if (ct_div_complete_w) begin
                    ct_div_start_r = 1'b0;
                end
            end else if (ConfigPending_q && 
                         (ConfigChangeTime_q > (CurrentTime_i + OperCycleTime_q + OperCycleTimeExtension_q))) begin
                if (OperBaseTime_q >= CurrentTime_i) begin
                    CycleStartTime_r    = OperBaseTime_q;
                    SetCycleStartTime_r = 1'b1;
                end else begin
                    if (ct_div_complete_d1) begin
                        CycleStartTime_r[79:32] = OperBaseTimeSec_q[47:0] + Nct_mul_CycleTime_sec_q;
                        CycleStartTime_r[31:0]  = Nct_mul_CycleTime_ns_q;
                        ct_div_start_r = 1'b0;
                        SetCycleStartTime_r = 1'b1;
                    end else if (!ct_div_start_q) begin
                        ct_div_start_r = 1'b1;
                    end else if (ct_div_complete_w) begin
                        ct_div_start_r = 1'b0;
                    end
                end
            end else if (ConfigPending_q && 
                         (ConfigChangeTime_q <= (CurrentTime_i + OperCycleTime_q + OperCycleTimeExtension_q))) begin
                CycleStartTime_r    = ConfigChangeTime_q;
                SetCycleStartTime_r = 1'b1;
            end
        end else if (ct_cstate_q != CT_SET_START_TIME ) begin
            CycleStartTime_r    = 80'hff_ffff_ffff_ffff_ffff; // Reset to a large value
            SetCycleStartTime_r = 1'b0;
            ct_div_start_r      = 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            CycleStartTime_q    <= 80'hff_ffff_ffff_ffff_ffff; // Reset to a large value
            SetCycleStartTime_q <= 1'b0;
            ct_div_start_q      <= 1'b0;
            OperBaseTimeSec_q   <= 48'd0;
            ct_dividend_q       <= 32'd0;
        end else begin
            CycleStartTime_q    <= CycleStartTime_r;
            SetCycleStartTime_q <= SetCycleStartTime_r;
            ct_div_start_q      <= ct_div_start_r;
            OperBaseTimeSec_q   <= OperBaseTimeSec_r;
            ct_dividend_q       <= ct_dividend_r;
        end
    end

    // Instantiate qbv_divider for CycleStartTime calculation
    wire [31:0] ct_div_quotient_w;
    wire [31:0] ct_remainder_w;
    wire [31:0] Nct_w;
    wire        ct_div_complete_w;

    qbv_divider u_qbv_ct_divider (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (ct_div_start_q),
        .dividend   (ct_dividend_q),
        .divisor    (OperCycleTime_q),
        .complete   (ct_div_complete_w),
        .quotient   (ct_div_quotient_w),
        .remainder  (ct_remainder_w)
    );

    assign Nct_w = (|ct_remainder_w) ? ct_div_quotient_w + 1 : ct_div_quotient_w;

    // Generate 1-cycle and 2-cycle delayed versions of ct_div_complete_w
    reg ct_div_complete_d1, ct_div_complete_d2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ct_div_complete_d1 <= 1'b0;
            ct_div_complete_d2 <= 1'b0;
        end else begin
            ct_div_complete_d1 <= ct_div_complete_w;
            ct_div_complete_d2 <= ct_div_complete_d1;
        end
    end

    // Calculate Nct_w * OperCycleTime_q 
    // Separate seconds part and nanoseconds part
    // two stage pipline registers to hold the results
    reg [63:0] Nct_mul_CycleTime_r;
    reg [47:0] Nct_mul_CycleTime_sec_r;
    reg [31:0] Nct_mul_CycleTime_ns_r;
    reg [63:0] Nct_mul_CycleTime_q;
    reg [47:0] Nct_mul_CycleTime_sec_q;
    reg [31:0] Nct_mul_CycleTime_ns_q;

    //Admin cycle time numerator, supported values: 1, 2, 3
    always @(*) begin
        Nct_mul_CycleTime_r     = Nct_w * OperCycleTime_q;
        if (Nct_mul_CycleTime_q >= (3*SC2NS)) begin
            Nct_mul_CycleTime_sec_r = 48'd3; 
            Nct_mul_CycleTime_ns_r  = Nct_mul_CycleTime_q[31:0] - (3*SC2NS); 
        end else if (Nct_mul_CycleTime_q >= (SC2NS << 1)) begin
            Nct_mul_CycleTime_sec_r = 48'd2;
            Nct_mul_CycleTime_ns_r  = Nct_mul_CycleTime_q[31:0] - (SC2NS << 1);
        end else if (Nct_mul_CycleTime_q >= SC2NS) begin
            Nct_mul_CycleTime_sec_r = 48'd1;
            Nct_mul_CycleTime_ns_r  = Nct_mul_CycleTime_q[31:0] - SC2NS;
        end else begin
            Nct_mul_CycleTime_sec_r = 48'd0;
            Nct_mul_CycleTime_ns_r  = Nct_mul_CycleTime_q[31:0]; // all in nanoseconds
        end
    end

    // Register the results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Nct_mul_CycleTime_q     <= 64'd0;
            Nct_mul_CycleTime_sec_q <= 48'd0;
            Nct_mul_CycleTime_ns_q  <= 32'd0;
        end else begin
            Nct_mul_CycleTime_q     <= Nct_mul_CycleTime_r;
            Nct_mul_CycleTime_sec_q <= Nct_mul_CycleTime_sec_r;
            Nct_mul_CycleTime_ns_q  <= Nct_mul_CycleTime_ns_r;
        end
    end

    // =====================================================
    // List Execution State Machine (LESM)
    // =====================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            le_cstate_q <= LE_INIT;
        else if (!GateEnabled_i) 
            le_cstate_q <= LE_INIT;
        else if (CycleStart_q) 
            le_cstate_q <= LE_NEW_CYCLE;
        else 
            le_cstate_q <= le_nstate_r;
    end

    always @(*) begin
        le_nstate_r = le_cstate_q;

        case (le_cstate_q)
            LE_INIT: begin
                le_nstate_r = LE_END_OF_CYCLE;
            end

            LE_NEW_CYCLE: begin
                le_nstate_r = LE_EXECUTE_CYCLE;
            end

            LE_EXECUTE_CYCLE: begin
                if (ListPointer_q >= OperControlListLength_q) begin
                    le_nstate_r = LE_END_OF_CYCLE;
                end else if (ExitTimer_q > 0 && ListPointer_q < OperControlListLength_q) begin
                    le_nstate_r = LE_DELAY;
                end
            end

            LE_DELAY: begin
                if (ExitTimer_q == 0) begin
                    le_nstate_r = LE_EXECUTE_CYCLE;
                end 
            end

            LE_END_OF_CYCLE: begin //wait for next CycleStart
                le_nstate_r = LE_END_OF_CYCLE; 
            end
        endcase
    end

    // ExecuteOperation(ListPointer)/SetGateStates()
    reg [ 3:0] op_r;
    reg [ 7:0] OperGateStates_r;
    reg [19:0] TimeInterval_r;
    reg [19:0] ExitTimer_r;
    reg [ 8:0] ListPointer_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            OperGateStates_q <= AdminGateStates_i;
            ExitTimer_q      <= 20'd0;
            ListPointer_q    <= 9'd0;
        end else begin
            OperGateStates_q <= OperGateStates_r;
            ExitTimer_q      <= ExitTimer_r;
            ListPointer_q    <= ListPointer_r;
        end
    end

    always @(*) begin : ExecuteOperation
        op_r = oper_data_i[31:28];
        OperGateStates_r = OperGateStates_q;
        TimeInterval_r = 20'd0;
        ExitTimer_r = ExitTimer_q;
        ListPointer_r = ListPointer_q;

        if (le_cstate_q == LE_INIT) begin
            OperGateStates_r = AdminGateStates_i;
            ExitTimer_r = 20'd0; 
            ListPointer_r = 9'd0; 
        end else if (le_cstate_q == LE_NEW_CYCLE) begin
            ListPointer_r = 9'd0; 
        end else if (le_cstate_q == LE_EXECUTE_CYCLE) begin
            case (op_r)
                4'h1: begin // Set Gate States
                    OperGateStates_r = oper_data_i[27:20]; 
                    TimeInterval_r = oper_data_i[19:0]; 
                    if (TimeInterval_r == 0) begin
                        TimeInterval_r = 20'd1;
                    end
                end
                default: begin
                    ListPointer_r = OperControlListLength_q; 
                    TimeInterval_r = 0;
                end
            endcase

            ExitTimer_r   = TimeInterval_r; 
            ListPointer_r = ListPointer_r + 1;
        end else if (le_cstate_q == LE_DELAY && ExitTimer_q > 0) begin
            ExitTimer_r = ExitTimer_q - 1; 
        end
    end

    assign oper_addr_o      = ListPointer_q;
    assign ExitTimer_o      = ExitTimer_q;
    assign OperGateStates_o = OperGateStates_q[2:0]; // Only 3 bits are used for gate states

    // =====================================================
    // List Config State Machine (LCSM)
    // =====================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lc_cstate_q <= LC_CONFIG_IDLE;
        end else if (!GateEnabled_i) begin
            lc_cstate_q <= LC_CONFIG_IDLE;
        end else if (ConfigChange_i) begin
            lc_cstate_q <= LC_CONFIG_PENDING;
        end else begin
            lc_cstate_q <= lc_nstate_r;
        end
    end

    always @(*) begin 
        lc_nstate_r = lc_cstate_q;

        case (lc_cstate_q)
            LC_CONFIG_PENDING: begin
                if (ConfigChangeTime_q <= CurrentTime_i) begin
                    lc_nstate_r = LC_UPDATE_CONFIG;
                end
            end

            LC_UPDATE_CONFIG: begin
                lc_nstate_r = LC_CONFIG_IDLE;
            end
        endcase
    end
    
    // Config Change Time calculation SetConfigChangeTime()
    reg  [79:0] ConfigChangeTime_r;
    reg  [79:0] ConfigChangeTime_q;
    reg         SetConfigChangeTime_r;
    reg         SetConfigChangeTime_q;

    //AdminCycleTime_i expressed in nanoseconds, corresponds to 1/N second
    //so 1 second is integral times of AdminCycleTime_i, just operate on ns parts is enough
    reg  [47:0] ConfigChangeTimeSec_r;
    reg  [47:0] ConfigChangeTimeSec_q;
    reg  [31:0] lc_dividend_r;
    reg  [31:0] lc_dividend_q;
    reg         lc_div_start_r;
    reg         lc_div_start_q;

    always @(*) begin 
        ConfigChangeTimeSec_r = ConfigChangeTimeSec_q;
        lc_dividend_r = lc_dividend_q;

        if (AdminBaseTime_i < CurrentTime_i && lc_div_start_q == 1'b0) begin
            if (AdminBaseTime_i[79:32] == CurrentTime_i[79:32]) begin
                ConfigChangeTimeSec_r = AdminBaseTime_i[79:32];
                lc_dividend_r     = CurrentTime_i[31:0] - AdminBaseTime_i[31:0];
            end else if (AdminBaseTime_i[79:32] < (CurrentTime_i[79:32] - AdminCycleTimeNumerator_i)) begin
                ConfigChangeTimeSec_r = CurrentTime_i[79:32] - AdminCycleTimeNumerator_i;
                lc_dividend_r = CurrentTime_i[31:0] - AdminBaseTime_i[31:0] 
                                + AdminCycleTimeDenominator_i * SC2NS;
            end else begin
                ConfigChangeTimeSec_r = AdminBaseTime_i[79:32];
                lc_dividend_r = CurrentTime_i[31:0] - AdminBaseTime_i[31:0]
                                + (CurrentTime_i[79:32] - AdminBaseTime_i[79:32]) * SC2NS;
            end
        end 
    end

    always @(*) begin
        ConfigChangeTime_r    = ConfigChangeTime_q;
        SetConfigChangeTime_r = SetConfigChangeTime_q;

        if (lc_cstate_q == LC_CONFIG_PENDING && SetConfigChangeTime_q == 1'b0) begin
            if (AdminBaseTime_i >= CurrentTime_i) begin
                ConfigChangeTime_r = AdminBaseTime_i;
                SetConfigChangeTime_r = 1'b1;
            end else begin
                if (lc_div_complete_d1) begin
                    ConfigChangeTime_r[79:32] = ConfigChangeTimeSec_q[47:0] + Nlc_mul_CycleTime_sec_q;
                    ConfigChangeTime_r[31:0]  = Nlc_mul_CycleTime_ns_q;
                    lc_div_start_r = 1'b0;
                    SetConfigChangeTime_r = 1'b1;
                end else if (!lc_div_start_q) begin
                    lc_div_start_r = 1'b1;
                end else if (lc_div_complete_w) begin
                    lc_div_start_r = 1'b0;
                end
            end
        end else if (!ConfigPending_q) begin
            ConfigChangeTime_r    = 80'hff_ffff_ffff_ffff_ffff; // Reset to a large value
            SetConfigChangeTime_r = 1'b0;
            lc_div_start_r        = 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ConfigChangeTime_q    <= 80'hff_ffff_ffff_ffff_ffff; // Reset to a large value
            SetConfigChangeTime_q <= 1'b0;
            lc_div_start_q        <= 1'b0;
            ConfigChangeTimeSec_q <= 48'd0;
            lc_dividend_q         <= 32'd0;
        end else begin
            ConfigChangeTime_q    <= ConfigChangeTime_r;
            SetConfigChangeTime_q <= SetConfigChangeTime_r;
            lc_div_start_q        <= lc_div_start_r;
            ConfigChangeTimeSec_q <= ConfigChangeTimeSec_r;
            lc_dividend_q         <= lc_dividend_r;
        end
    end

    // Instantiate qbv_divider for ConfigChangeTime calculation
    wire [31:0] lc_div_quotient_w;
    wire [31:0] lc_remainder_w;
    wire [31:0] Nlc_w;
    wire        lc_div_complete_w;

    qbv_divider u_qbv_lc_divider (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (lc_div_start_q),
        .dividend   (lc_dividend_q),
        .divisor    (AdminCycleTime_i),
        .complete   (lc_div_complete_w),
        .quotient   (lc_div_quotient_w),
        .remainder  (lc_remainder_w)
    );

    assign Nlc_w = (|lc_remainder_w) ? lc_div_quotient_w + 1 : lc_div_quotient_w;

    // Generate 1-cycle and 2-cycle delayed versions of lc_div_complete_w
    reg lc_div_complete_d1, lc_div_complete_d2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lc_div_complete_d1 <= 1'b0;
            lc_div_complete_d2 <= 1'b0;
        end else begin
            lc_div_complete_d1 <= lc_div_complete_w;
            lc_div_complete_d2 <= lc_div_complete_d1;
        end
    end

    // Calculate Nlc_w * AdminCycleTime_i
    // Separate seconds part and nanoseconds part
    // two stage pipline registers to hold the results
    reg [63:0] Nlc_mul_CycleTime_r;
    reg [47:0] Nlc_mul_CycleTime_sec_r;
    reg [31:0] Nlc_mul_CycleTime_ns_r;
    reg [63:0] Nlc_mul_CycleTime_q;
    reg [47:0] Nlc_mul_CycleTime_sec_q;
    reg [31:0] Nlc_mul_CycleTime_ns_q;

    //Admin cycle time numerator, supported values: 1, 2, 3
    always @(*) begin
        Nlc_mul_CycleTime_r     = Nlc_w * AdminCycleTime_i;
        if (Nlc_mul_CycleTime_q >= (3*SC2NS)) begin
            Nlc_mul_CycleTime_sec_r = 48'd3; 
            Nlc_mul_CycleTime_ns_r  = Nlc_mul_CycleTime_q[31:0] - (3*SC2NS); 
        end else if (Nlc_mul_CycleTime_q >= (SC2NS << 1)) begin
            Nlc_mul_CycleTime_sec_r = 48'd2;
            Nlc_mul_CycleTime_ns_r  = Nlc_mul_CycleTime_q[31:0] - (SC2NS << 1);
        end else if (Nlc_mul_CycleTime_q >= SC2NS) begin
            Nlc_mul_CycleTime_sec_r = 48'd1;
            Nlc_mul_CycleTime_ns_r  = Nlc_mul_CycleTime_q[31:0] - SC2NS;
        end else begin
            Nlc_mul_CycleTime_sec_r = 48'd0;
            Nlc_mul_CycleTime_ns_r  = Nlc_mul_CycleTime_q[31:0]; // all in nanoseconds
        end
    end

    // Register the results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Nlc_mul_CycleTime_q     <= 64'd0;
            Nlc_mul_CycleTime_sec_q <= 48'd0;
            Nlc_mul_CycleTime_ns_q  <= 32'd0;
        end else begin
            Nlc_mul_CycleTime_q     <= Nlc_mul_CycleTime_r;
            Nlc_mul_CycleTime_sec_q <= Nlc_mul_CycleTime_sec_r;
            Nlc_mul_CycleTime_ns_q  <= Nlc_mul_CycleTime_ns_r;
        end
    end

    // =====================================================
    // Misc. Outputs
    // =====================================================
    reg ConfigChange_d1, ConfigChange_d2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ConfigChange_d1 <= 1'b0;
            ConfigChange_d2 <= 1'b0;
        end else begin
            ConfigChange_d1 <= ConfigChange_i;
            ConfigChange_d2 <= ConfigChange_d1;
        end
    end

    reg    cc_process_q;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cc_process_q <= 1'b0;
        end else if (lc_cstate_q == LC_CONFIG_PENDING && ConfigChange_d2) begin
            cc_process_q <= 1'b1;
        end else if (!ConfigChange_d2) begin
            cc_process_q <= 1'b0;
        end
    end

    assign cc_process_o = cc_process_q;

    reg    OperControlListPopulated_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            OperControlListPopulated_q <= 1'b0;
        end else if (lc_cstate_q == LC_UPDATE_CONFIG) begin
            OperControlListPopulated_q <= 1'b1;
        end else if (lc_cstate_q == LC_CONFIG_PENDING && ConfigChange_d2) begin
            OperControlListPopulated_q <= 1'b0;
        end
    end

    assign OperControlListPopulated_o = OperControlListPopulated_q;

    reg         ConfigPending_r;

    always @(*) begin 
        ConfigPending_r    = ConfigPending_q;

        if (lc_cstate_q == LC_CONFIG_PENDING && SetConfigChangeTime_q == 1'b1) begin
            ConfigPending_r    = 1'b1;
        end else if (lc_cstate_q == LC_CONFIG_IDLE) begin
            ConfigPending_r    = 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ConfigPending_q    <= 1'b0;
        end else begin
            ConfigPending_q    <= ConfigPending_r;
        end
    end
    assign ConfigPending_o = ConfigPending_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            OperBaseTime_q           <= 80'h0;
            OperControlListLength_q  <= 9'd0;
            OperCycleTime_q          <= 32'd0;
            OperCycleTimeNumerator_q <= 2'd0;
            OperCycleTimeExtension_q <= 32'd0;
        end else if (lc_cstate_q == LC_UPDATE_CONFIG) begin
            OperBaseTime_q           <= AdminBaseTime_i;
            OperControlListLength_q  <= AdminControlListLength_i;
            OperCycleTime_q          <= AdminCycleTime_i;
            OperCycleTimeNumerator_q <= AdminCycleTimeNumerator_i;
            OperCycleTimeExtension_q <= AdminCycleTimeExtension_i;
        end
    end

    assign OperBaseTime_o             = OperBaseTime_q;
    assign OperControlListLength_o    = OperControlListLength_q;
    assign OperCycleTime_o            = OperCycleTime_q;
    assign OperCycleTimeNumerator_o   = OperCycleTimeNumerator_q;
    assign OperCycleTimeExtension_o   = OperCycleTimeExtension_q;
    assign ConfigChangeTime_o         = ConfigChangeTime_q;

endmodule
