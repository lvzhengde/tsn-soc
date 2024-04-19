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
 * JTAG Transport Module
-*/

module jtag_dtm
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter DMI_ADDR_W = 6
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
    input                    rst_n          ,

    // JTAG ports
    input                    tck_i          , 
    input                    tms_i          , 
    input                    tdi_i          , 
    output                   tdo_o          ,

    // DMI interface
    input                    dm_resp_i      ,
    input  [DMI_ADDR_W+33:0] dm_resp_data_i ,
    output                   dtm_ack_o      ,

    input                    dm_ack_i       ,
    output                   dtm_req_o      ,
    output [DMI_ADDR_W+33:0] dtm_req_data_o
);
    //--------------------------------------------
    // local parameters
    //--------------------------------------------
    localparam IDCODE_VERSION     = 4'h1;
    localparam IDCODE_PART_NUMBER = 16'h1588;
    localparam IDCODE_MANUFLD     = 11'h801;

    localparam DTM_VERSION  = 4'h1;
    localparam IR_W         = 5;
    localparam SHIFT_REG_W  = DMI_ADDR_W + 34;

    // DTM TAP register addresses
    localparam BYPASS_A    = 5'h1f;
    localparam IDCODE_A    = 5'h01;
    localparam DMI_A       = 5'h11;
    localparam DTMCS_A     = 5'h10;

    // TAP states
    localparam TEST_LOGIC_RESET  = 4'h0;
    localparam RUN_TEST_IDLE     = 4'h1;
    localparam SELECT_DR_SCAN    = 4'h2;
    localparam CAPTURE_DR        = 4'h3;
    localparam SHIFT_DR          = 4'h4;
    localparam EXIT_1_DR         = 4'h5;
    localparam PAUSE_DR          = 4'h6;
    localparam EXIT_2_DR         = 4'h7;
    localparam UPDATE_DR         = 4'h8;
    localparam SELECT_IR_SCAN    = 4'h9;
    localparam CAPTURE_IR        = 4'hA;
    localparam SHIFT_IR          = 4'hB;
    localparam EXIT_1_IR         = 4'hC;
    localparam PAUSE_IR          = 4'hD;
    localparam EXIT_2_IR         = 4'hE;
    localparam UPDATE_IR         = 4'hF;

    //-------------------------------------
    // Registers / Wires
    // ------------------------------------
    wire                    busy_w;
    wire  [1:0]             dmi_stat_w;
    wire  [SHIFT_REG_W-1:0] busy_resp_w;
    wire  [SHIFT_REG_W-1:0] not_busy_resp_w;

    reg   [DMI_ADDR_W+33:0] dtm_req_data_q;
    reg   [DMI_ADDR_W+33:0] dm_resp_data_q;   

    wire  [5:0]  addr_bits_w = DMI_ADDR_W[5:0];
    wire  [31:0] idcode_w = {IDCODE_VERSION, IDCODE_PART_NUMBER, IDCODE_MANUFLD, 1'h1};
    wire  [31:0] dtmcs_w  = {    14'b0,
                                 1'b0,         // dmihardreset
                                 1'b0,         // dmireset
                                 1'b0,
                                 3'h5,         // idle
                                 dmi_stat_w,   // dmistat
                                 addr_bits_w,  // abits
                                 DTM_VERSION   // version
                             }; 

    assign dmi_stat_w = busy_w ? 2'b01 : 2'b00;
    assign busy_resp_w = {{(DMI_ADDR_W+32){1'b0}}, 2'b11};  // op = 2'b11
    assign not_busy_resp_w = dm_resp_data_q;


    //-----------------------------------------------------------------------------------
    // State machine
    // Regardless of which state TAP is currently in, TAP will definitely return to 
    // the Test-Logic-Reset state as long as TMS remains high and lasts for 5 TCK clocks
    //-----------------------------------------------------------------------------------
    reg   [3:0] next_state_r;
    reg   [3:0] current_state_q;

    // Next state logic
    always @(*) begin
        next_state_r = current_state_q;

        case (jtag_state)
            TEST_LOGIC_RESET  : next_state_r = tms_i ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
            RUN_TEST_IDLE     : next_state_r = tms_i ? SELECT_DR_SCAN   : RUN_TEST_IDLE;
            SELECT_DR_SCAN    : next_state_r = tms_i ? SELECT_IR_SCAN   : CAPTURE_DR;
            CAPTURE_DR        : next_state_r = tms_i ? EXIT_1_DR        : SHIFT_DR;
            SHIFT_DR          : next_state_r = tms_i ? EXIT_1_DR        : SHIFT_DR;
            EXIT_1_DR         : next_state_r = tms_i ? UPDATE_DR        : PAUSE_DR;
            PAUSE_DR          : next_state_r = tms_i ? EXIT_2_DR        : PAUSE_DR;
            EXIT_2_DR         : next_state_r = tms_i ? UPDATE_DR        : SHIFT_DR;
            UPDATE_DR         : next_state_r = tms_i ? SELECT_DR_SCAN   : RUN_TEST_IDLE;
            SELECT_IR_SCAN    : next_state_r = tms_i ? TEST_LOGIC_RESET : CAPTURE_IR;
            CAPTURE_IR        : next_state_r = tms_i ? EXIT_1_IR        : SHIFT_IR;
            SHIFT_IR          : next_state_r = tms_i ? EXIT_1_IR        : SHIFT_IR;
            EXIT_1_IR         : next_state_r = tms_i ? UPDATE_IR        : PAUSE_IR;
            PAUSE_IR          : next_state_r = tms_i ? EXIT_2_IR        : PAUSE_IR;
            EXIT_2_IR         : next_state_r = tms_i ? UPDATE_IR        : SHIFT_IR;
            UPDATE_IR         : next_state_r = tms_i ? SELECT_DR_SCAN   : RUN_TEST_IDLE; 
            default ;
        endcase
    end

    // Update current state
    always @(posedge tck_i or negedge rst_n) begin
        if (!rst_n)
            current_state_q   <= TEST_LOGIC_RESET;
        else
            current_state_q   <= next_state_r;
    end    

    //-----------------------------------------------
    // IR / DR shift register
    //-----------------------------------------------
    reg   [SHIFT_REG_W-1:0] shift_reg_q;
    reg   [IR_W-1:0]        ir_reg_q;

    assign busy_w = ??

    always @(posedge tck_i) begin
        case (current_state_q)
        // IR
        CAPTURE_IR: 
            shift_reg_q <= {{(SHIFT_REG_W-1){1'b0}}, 1'b1}; //It must be b01 per JTAG spec 
        SHIFT_IR  : 
            shift_reg_q <= {{(SHIFT_REG_W-IR_W){1'b0}}, tdi_i, shift_reg[IR_W-1:1]}; // right shift 1 bit, IR_W bit register
        // DR
        CAPTURE_DR: 
            case (ir_reg_q) 
            BYPASS_A : 
                shift_reg_q <= {(SHIFT_REG_W){1'b0}};
            IDCODE_A : 
                shift_reg_q <= {{(SHIFT_REG_W-32){1'b0}}, idcode_w};
            DTMCS_A  : 
                shift_reg_q <= {{(SHIFT_REG_W-32){1'b0}}, dtmcs_w};
            DMI_A    : 
                shift_reg_q <= busy_w ? busy_resp_w : not_busy_resp_w;
            default:
                shift_reg_q <= {(SHIFT_REG_W){1'b0}};
            endcase
        SHIFT_DR  : 
            case (ir_reg_q) 
            BYPASS_A : 
                shift_reg_q <= {{(SHIFT_REG_W-1 ){1'b0}}, tdi_i}; // in = out, bypass
            IDCODE_A : 
                shift_reg_q <= {{(SHIFT_REG_W-32){1'b0}}, tdi_i, shift_reg_q[31:1]}; // right shift 1 bit, 32 bit register
            DTMCS_A  : 
                shift_reg_q <= {{(SHIFT_REG_W-32){1'b0}}, tdi_i, shift_reg_q[31:1]}; // right shift 1 bit, 32 bit register
            DMI_A    : 
                shift_reg_q <= {tdi_i, shift_reg_q[SHIFT_REG_W-1:1]}; // right shift 1 bit, SHIFT_REG_W bit register
            default:
                shift_reg_q <= {{(SHIFT_REG_W-1){1'b0}} , tdi_i}; //bypass
            endcase 
        endcase
    end

endmodule

