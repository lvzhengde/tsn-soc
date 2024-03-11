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
 * riscv core with jtag debug support
-*/


module riscv_core_jtag
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter SUPPORT_BRANCH_PREDICTION = 1     ,
    parameter SUPPORT_MULDIV   = 1              ,
    parameter SUPPORT_SUPER    = 0              ,
    parameter SUPPORT_MMU      = 0              , 
    parameter SUPPORT_DUAL_ISSUE = 1            , 
    parameter SUPPORT_LOAD_BYPASS = 1           ,  
    parameter SUPPORT_MUL_BYPASS = 1            ,
    parameter EXTRA_DECODE_STAGE = 0            ,
    parameter MEM_CACHE_ADDR_MIN = 32'h80000000 ,
    parameter MEM_CACHE_ADDR_MAX = 32'h8fffffff ,
    parameter NUM_BTB_ENTRIES  = 32             ,
    parameter NUM_BTB_ENTRIES_W = 5             ,
    parameter NUM_BHT_ENTRIES  = 512            ,
    parameter NUM_BHT_ENTRIES_W = 9             ,
    parameter RAS_ENABLE       = 1              ,
    parameter GSHARE_ENABLE    = 0              ,
    parameter BHT_ENABLE       = 1              ,
    parameter NUM_RAS_ENTRIES  = 8              ,
    parameter NUM_RAS_ENTRIES_W = 3
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    //Inputs
    input           clk                ,
    input           rst_n              ,
    input  [ 31:0]  mem_d_data_rd_i    ,
    input           mem_d_accept_i     ,
    input           mem_d_ack_i        ,
    input           mem_d_error_i      ,
    input  [ 10:0]  mem_d_resp_tag_i   ,
    input           mem_i_accept_i     ,
    input           mem_i_valid_i      ,
    input           mem_i_error_i      ,
    input  [ 63:0]  mem_i_inst_i       ,
    input           intr_i             ,
    input  [ 31:0]  reset_vector_i     ,
    input  [ 31:0]  cpu_id_i           ,

    //Outputs
    output [ 31:0]  mem_d_addr_o       ,
    output [ 31:0]  mem_d_data_wr_o    ,
    output          mem_d_rd_o         ,
    output [  3:0]  mem_d_wr_o         ,
    output          mem_d_cacheable_o  ,
    output [ 10:0]  mem_d_req_tag_o    ,
    output          mem_d_invalidate_o ,
    output          mem_d_writeback_o  ,
    output          mem_d_flush_o      ,
    output          mem_i_rd_o         ,
    output          mem_i_flush_o      ,
    output          mem_i_invalidate_o ,
    output [ 31:0]  mem_i_pc_o         ,

    //JTAG pins
    input           tck_i              , 
    input           tms_i              , 
    input           tdi_i              , 
    output          tdo_o               
);

    riscv_core
    #(
        .MEM_CACHE_ADDR_MIN        (MEM_CACHE_ADDR_MIN)       ,
        .MEM_CACHE_ADDR_MAX        (MEM_CACHE_ADDR_MAX)       ,
        .SUPPORT_BRANCH_PREDICTION (SUPPORT_BRANCH_PREDICTION),
        .SUPPORT_MULDIV            (SUPPORT_MULDIV)           ,
        .SUPPORT_SUPER             (SUPPORT_SUPER)            ,
        .SUPPORT_MMU               (SUPPORT_MMU)              ,
        .SUPPORT_DUAL_ISSUE        (SUPPORT_DUAL_ISSUE)       ,
        .SUPPORT_LOAD_BYPASS       (SUPPORT_LOAD_BYPASS)      ,
        .SUPPORT_MUL_BYPASS        (SUPPORT_MUL_BYPASS)       ,
        .EXTRA_DECODE_STAGE        (EXTRA_DECODE_STAGE)       ,
        .NUM_BTB_ENTRIES           (NUM_BTB_ENTRIES)          ,
        .NUM_BTB_ENTRIES_W         (NUM_BTB_ENTRIES_W)        ,
        .NUM_BHT_ENTRIES           (NUM_BHT_ENTRIES)          ,
        .NUM_BHT_ENTRIES_W         (NUM_BHT_ENTRIES_W)        ,
        .RAS_ENABLE                (RAS_ENABLE)               ,
        .GSHARE_ENABLE             (GSHARE_ENABLE)            ,
        .BHT_ENABLE                (BHT_ENABLE)               ,
        .NUM_RAS_ENTRIES           (NUM_RAS_ENTRIES)          ,
        .NUM_RAS_ENTRIES_W         (NUM_RAS_ENTRIES_W)
    )
    u_riscv_core
    (
        //Inputs
        .clk_i                     (clk             ) ,
        .rst_i                     (~rst_n          ) ,
        .mem_d_data_rd_i           (mem_d_data_rd_i ) ,
        .mem_d_accept_i            (mem_d_accept_i  ) ,
        .mem_d_ack_i               (mem_d_ack_i     ) ,
        .mem_d_error_i             (mem_d_error_i   ) ,
        .mem_d_resp_tag_i          (mem_d_resp_tag_i) ,
        .mem_i_accept_i            (mem_i_accept_i  ) ,
        .mem_i_valid_i             (mem_i_valid_i   ) ,
        .mem_i_error_i             (mem_i_error_i   ) ,
        .mem_i_inst_i              (mem_i_inst_i    ) ,
        .intr_i                    (intr_i          ) ,
        .reset_vector_i            (reset_vector_i  ) ,
        .cpu_id_i                  (cpu_id_i        ) ,
    
        //Outputs
        .mem_d_addr_o              (mem_d_addr_o      ) ,
        .mem_d_data_wr_o           (mem_d_data_wr_o   ) ,
        .mem_d_rd_o                (mem_d_rd_o        ) ,
        .mem_d_wr_o                (mem_d_wr_o        ) ,
        .mem_d_cacheable_o         (mem_d_cacheable_o ) ,
        .mem_d_req_tag_o           (mem_d_req_tag_o   ) ,
        .mem_d_invalidate_o        (mem_d_invalidate_o) ,
        .mem_d_writeback_o         (mem_d_writeback_o ) ,
        .mem_d_flush_o             (mem_d_flush_o     ) ,
        .mem_i_rd_o                (mem_i_rd_o        ) ,
        .mem_i_flush_o             (mem_i_flush_o     ) ,
        .mem_i_invalidate_o        (mem_i_invalidate_o) ,
        .mem_i_pc_o                (mem_i_pc_o        ) 
    );


endmodule

