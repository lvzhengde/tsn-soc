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
 * JTAG Debug Module
 * Only one hart supported
 * Only support abstract command debugging
 * Not support system bus and program buffer
-*/

module jtag_dm
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter DMI_ADDR_W = 7
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    //Inputs
    input                    clk            ,
    input                    rst_n          ,
    input  [ 31:0]           cpu_id_i       ,

    // DMI interface
    output                   dm_resp_o      ,
    output [DMI_ADDR_W+33:0] dm_resp_data_o ,
    input                    dtm_ack_i      ,

    output                   dm_ack_o       ,
    input                    dtm_req_i      ,
    input  [DMI_ADDR_W+33:0] dtm_req_data_i ,

    //JTAG control outputs
    output                   reset_hart_o   ,
    output                   halt_hart_o    ,
    output                   bus_req_o      ,

    //JTAG GPR access interface
    output [  4:0]           gpr_waddr_o    ,
    output [ 31:0]           gpr_data_wr_o  ,
    output [  4:0]           gpr_raddr_o    ,
    input  [ 31:0]           gpr_data_rd_i  ,

    //JTAG CSR access interface
    output                   csr_write_o    ,
    output [ 11:0]           csr_waddr_o    ,
    output [ 31:0]           csr_data_wr_o  ,
    output [ 11:0]           csr_raddr_o    ,
    input  [ 31:0]           csr_data_rd_i  ,

    //JTAG memory access interface
    //Inputs
    input  [ 31:0]           mem_d_data_rd_i    ,
    input                    mem_d_accept_i     ,
    input                    mem_d_ack_i        ,
    input                    mem_d_error_i      ,
    input  [ 10:0]           mem_d_resp_tag_i   ,
    input                    mem_load_fault_i   ,
    input                    mem_store_fault_i  ,

    //Outputs
    output [ 31:0]           mem_d_addr_o       ,
    output [ 31:0]           mem_d_data_wr_o    ,
    output                   mem_d_rd_o         ,
    output [  3:0]           mem_d_wr_o         ,
    output                   mem_d_cacheable_o  ,
    output [ 10:0]           mem_d_req_tag_o    ,
    output                   mem_d_invalidate_o ,
    output                   mem_d_writeback_o  ,
    output                   mem_d_flush_o       

);

    //--------------------------------------------
    // local parameters
    //--------------------------------------------
    localparam DTM_OP_NOP   = 2'b00;
    localparam DTM_OP_READ  = 2'b01;
    localparam DTM_OP_WRITE = 2'b10;
    localparam OP_SUCCESS   = 2'b00;

    //DM register address
    localparam DMSTATUS_A      = 7'h11;
    localparam DMCONTROL_A     = 7'h10;
    localparam DMCONTROL_MASK  = 32'h20010003;
    localparam HARTINFO_A      = 7'h12;
    localparam ABSTRACTCS_A    = 7'h16;
    localparam ABSTRACTCS_MASK = 32'h1F00170F;
    localparam DATA0_A         = 7'h04;
    localparam DATA1_A         = 7'h05;
    localparam DATA2_A         = 7'h06;
    localparam SBCS_A          = 7'h38;
    localparam SBADDRESS0_A    = 7'h39;
    localparam SBDATA0_A       = 7'h3C;
    localparam COMMAND_A       = 7'h17;

    //RISC-V Debug Mode CSR address
    localparam DCSR_A       = 12'h7b0;
    localparam DPC_A        = 12'h7b1;

    //-------------------------------------
    // Registers / Wires
    // ------------------------------------
    wire  [31:0]            dmstatus_w ;
    reg   [31:0]            dmcontrol_q;
    reg   [31:0]            command_q;
    reg   [31:0]            abstractcs_w;

    wire  [ 1:0]            op_w  ;
    wire  [31:0]            data_w;
    wire  [DMI_ADDR_W-1:0]  addr_w;


    //-------------------------------------
    // DTM Request / DM Ack --register access
    // ------------------------------------
    reg                     dtm_req_d1, dtm_req_d2;
    reg   [DMI_ADDR_W+33:0] dtm_req_data_q;
    wire                    dm_ack_w;
    reg                     dm_ack_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            {dtm_req_d1, dtm_req_d2} <= 2'b0;
        else
            {dtm_req_d1, dtm_req_d2} <= {dtm_req_i, dtm_req_d1};
    end    

    assign dm_ack_w = (dtm_req_d2 == 1'b1) ? 1'b1 : 1'b0;

    always @(posedge clk) begin
        dm_ack_q <= dm_ack_r;
    end    

    wire dm_ack_pul_w = dm_ack_w & (!dm_ack_q);
    reg  dm_ack_pul_q;

    always @(posedge clk) begin
        dm_ack_pul_q <= dm_ack_pul_w;
    end    

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dtm_req_data_q <= {(DMI_ADDR_W+34){1'b0}};
        else if(dm_ack_pul_w)
            dtm_req_data_q <= dtm_req_data_i;
    end    

    assign op_w   = dtm_req_data_q[1:0];
    assign data_w = dtm_req_data_q[33:2];
    assign addr_w = dtm_req_data_q[DMI_ADDR_W+33:34];

    //-------------------------------------
    // DM control register
    // ------------------------------------
    reg  haltreq_q;
    reg  resumereq_q;
    reg  ackhavereset_q;

    wire hartreset_w       = dmcontrol_q[29];
    wire ndmreset_w        = dmcontrol_q[1];
    wire dmactive_w        = dmcontrol_q[0] ;

    wire dmcontrol_wrsel_w = (op_w == DTM_OP_WRITE && addr_w == DMCONTROL_A && dm_ack_pul_q == 1'b1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dmcontrol_q    <= 32'h1;
            haltreq_q      <= 1'b0;
            resumereq_q    <= 1'b0;
            ackhavereset_q <= 1'b0;
        end
        else if(dmcontrol_wrsel_w) begin
            if (dmactive_w) begin
                dmcontrol_q    <= data_w & DMCONTROL_MASK;
                haltreq_q      <= data_w[31];
                ackhavereset_q <= data_w[28];

                if (data_w[30] & (!data_w[31]) & (!haltreq_q)) 
                    resumereq_q <= 1'b1;
            end
            else begin
                //per spec, the dmactive bit is the only bit which can 
                //be written to something other than its reset value 
                //when dmactive bit is set to 0
                dmcontrol_q[0]     <= data_w[0];
            end
        end
        else if(!dmactive_w) begin  //reset DM
            dmcontrol_q    <= 32'h0;
            haltreq_q      <= 1'b0;
            resumereq_q    <= 1'b0;
            ackhavereset_q <= 1'b0;
        end
        else begin  //clear pulse signals
            resumereq_q    <= 1'b0;
            ackhavereset_q <= 1'b0;
        end
    end    

    //-------------------------------------
    // DM status register
    // ------------------------------------
    reg   hart_halted_q;
    reg   hart_halted_d1;
    reg   resumeack_q;
    reg   havereset_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hart_halted_q <= 1'b0;
            resumeack_q   <= 1'b1;
        end
        else if(!dmactive_w) begin   //reset DM
            hart_halted_q <= 1'b0;
            resumeack_q   <= 1'b1;
        end
        else if (haltreq_q) begin
            hart_halted_q <= 1'b1;
        end
        else if(resumereq_q) begin
            hart_halted_q <= 1'b0;
            resumeack_q   <= 1'b0;
        end
        else if (hart_halted_d1 & (!hart_halted_q)) begin
            resumeack_q   <= 1'b1;
        end
    end

    always @(posedge clk) begin
        hart_halted_d1 <= hart_halted_q;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            havereset_q <= 1'b1;
        else if(!dmactive_w)   //reset DM
            havereset_q <= 1'b1;
        else if (ackhavereset_q)
            havereset_q <= 1'b0;
    end

    assign dmstatus_w[31:20] = 12'h4;
    assign dmstatus_w[15:12] = 4'h0;
    assign dmstatus_w[7:0]   = 8'h82;
    assign dmstatus_w[19:18] = {havereset_q, havereset_q};
    assign dmstatus_w[17:16] = {resumeack_q, resumeack_q};
    assign dmstatus_w[11:10] = {~hart_halted_q, ~hart_halted_q};
    assign dmstatus_w[9:8]   = {hart_halted_q, hart_halted_q};

    //-----------------------------------------
    // DM Abstract Command (command) register
    // ----------------------------------------
    reg          busy_q;
    reg  [ 2:0]  cmderr_q;

    reg          issue_command_q;
    wire [ 7:0]  cmdtype_w = command_q[31:24];
    wire [23:0]  control_w = command_q[23:0];
    wire         write_w    = control_w[16];

    //for abstract register access
    wire [ 2:0]  aarsize_w  = control_w[22:20];
    wire         aarpostincrement_w = control_w[19];
    wire         postexec_w = control_w[18];
    wire         transfer_w = control_w[17];
    wire [15:0]  regno_w    = control_w[15:0];

    //for absctract memory access
    wire         aamvirtual_w = control_w[23];
    wire [ 2:0]  aamsize_w    = control_w[22:20];
    wire         aampostincrement_w = control_w[19];
    wire [ 1:0]  target_specific_w  = control_w[15:14];

    wire command_wrsel_w = (op_w == DTM_OP_WRITE && addr_w == COMMAND_A && dm_ack_pul_q == 1'b1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            issue_command_q <= 1'b0;
            command_q       <= 32'h0;
        end
        else if(!dmactive_w) begin   //reset DM
            issue_command_q <= 1'b0;
            command_q       <= 32'h0;
        end
        else if (command_wrsel_w && cmderr_q == 3'h0) begin
            issue_command_q <= 1'b1;
            command_q       <= data_w;
        end
        else begin
            issue_command_q <= 1'b0;
        end
    end
    
    //-----------------------------------------
    // DM Abstract Control and Status register
    // ----------------------------------------

    wire abstractcs_wrsel_w = (op_w == DTM_OP_WRITE && addr_w == ABSTRACTCS_A && dm_ack_pul_q == 1'b1);
    wire data0_wrsel_w      = (op_w == DTM_OP_WRITE && addr_w == DATA0_A && dm_ack_pul_q == 1'b1);
    wire data1_wrsel_w      = (op_w == DTM_OP_WRITE && addr_w == DATA1_A && dm_ack_pul_q == 1'b1);
    wire data2_wrsel_w      = (op_w == DTM_OP_WRITE && addr_w == DATA2_A && dm_ack_pul_q == 1'b1);
    wire data0_rdsel_w      = (op_w == DTM_OP_READ && addr_w == DATA0_A && dm_ack_pul_q == 1'b1);
    wire data1_rdsel_w      = (op_w == DTM_OP_READ && addr_w == DATA1_A && dm_ack_pul_q == 1'b1);
    wire data2_rdsel_w      = (op_w == DTM_OP_READ && addr_w == DATA2_A && dm_ack_pul_q == 1'b1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            busy_q <= 1'b0 
        else if(!dmactive_w)    //reset DM
            busy_q <= 1'b0 
        else if (issue_command_q) 
            busy_q <= 1'b1;
        //command completed to release busy

    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            cmderr_q <= 3'h0; 
        else if(!dmactive_w)    //reset DM
            cmderr_q <= 3'h0; 
        else if (cmderr_q == 3'h0 && busy_q && (abstractcs_wrsel_w | command_wrsel_w)) 
            cmderr_q <= 3'h1; 
        else if (cmderr_q == 3'h0 && busy_q && (data0_wrsel_w | data1_wrsel_w | data2_wrsel_w | data0_rdsel_w | data1_rdsel_w | data2_rdsel_w)) 
            cmderr_q <= 3'h1; 
        else if (abstractcs_wrsel_w) begin //write 1 to clear
            cmderr_q[0] <= data_w[ 8] ? 0 : cmderr_q[0];
            cmderr_q[1] <= data_w[ 9] ? 0 : cmderr_q[1];
            cmderr_q[2] <= data_w[10] ? 0 : cmderr_q[2];
        end

    end

    assign abstractcs_w[31:13] = 19'h0;
    assign abstractcs_w[12:11] = {busy_q, 1'b0};
    assign abstractcs_w[10: 8] = cmderr_q;
    assign abstractcs_w[ 7: 0] = 8'h3;


endmodule

