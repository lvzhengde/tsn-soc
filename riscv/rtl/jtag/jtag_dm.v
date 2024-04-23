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
 * Only support abstract command debugging
 * Not support system bus and program buffe
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
    localparam DMSTATUS_A   = 7'h11;
    localparam DMCONTROL_A  = 7'h10;
    localparam HARTINFO_A   = 7'h12;
    localparam ABSTRACTCS_A = 7'h16;
    localparam DATA0_A      = 7'h04;
    localparam SBCS_A       = 7'h38;
    localparam SBADDRESS0_A = 7'h39;
    localparam SBDATA0_A    = 7'h3C;
    localparam COMMAND_A    = 7'h17;

    //RISC-V Debug Mode CSR address
    localparam DCSR_A       = 12'h7b0;
    localparam DPC_A        = 12'h7b1;




endmodule

