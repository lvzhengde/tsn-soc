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
    output                   reset_req_o    ,
    output                   halt_req_o     ,
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
    localparam DATA0_A         = 7'h04;
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
    reg   [31:0]            dmstatus_q ;
    reg   [31:0]            dmcontrol_q;

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

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dm_ack_q <= 1'b0;
        else
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
            dmcontrol_q    <= data_w & DMCONTROL_MASK;
            haltreq_q      <= data_w[31];
            ackhavereset_q <= data_w[28]

            if (data_w[31] & (!data_w[31]))  //Spec error?? FIXME
                resumereq_q <= 1'b1;
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
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            dmstatus_q        <= 32'h4f0c82;
        else if(!dmactive_w)   //reset DM
            dmstatus_q        <= 32'h4f0c82;
        else if(reset_req_o)   //reset hart
            dmstatus_q[19:18] <= 2'b11
        else if (haltreq_q)   
            //clear allrunning/anyrunning, set allhalted/anyhalted
            dmstatus_q[11:8]  <= 4'h3;
        else if (!haltreq_q)   
            //set allrunning/anyrunning, clear allhalted/anyhalted
            dmstatus_q[11:8]  <= 4'hc;
        else if (resumereq_q)
            dmstatus_q[17:16] <= 2'b0
        else if (ackhavereset_q)
            dmstatus_q[19:18] <= 2'b0
    end    

endmodule

