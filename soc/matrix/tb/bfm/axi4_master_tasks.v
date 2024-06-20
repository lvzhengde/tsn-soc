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

`ifndef AXI4_MASTER_TASKS_V_
`define AXI4_MASTER_TASKS_V_

integer seed_tread  = 5;
integer seed_twrite = 5;

integer num_of_reads ; initial num_of_reads  = 0;
integer num_of_writes; initial num_of_writes = 0;

task axi_statistics;
    input integer id;
begin
    $display("Master[%2d] reads=%5d writes=%5d", id, num_of_reads, num_of_writes);
end
endtask

//----------------------------------------------------------------
// reads blen words from addr and store the data input to rdata[]
// read(addr+0, 4);
// read(addr+4, 4);
// read(addr+8, 4);
//  ... ...
// read(addr+4*(blen-1), 4);
//----------------------------------------------------------------
task axi_master_read;
    input [31:0]  addr ;
    input [15:0]  blen ; // burst length: 1, 2, ...
    input [ 1:0]  burst; // 0:fixed, 1:incr, 2:wrap
    input         delay; // 0:don't use delay
    
    reg   [ 3:0]  arid;
begin
    arid <= AXI_ID;

    @(posedge clk); 
    fork 
       axi_master_read_ar(arid, addr, blen, burst);
       axi_master_read_r(arid, blen, delay);
    join
    
    num_of_reads = num_of_reads + 1;
end
endtask

task axi_master_read_ar;
    input [ 3:0]  arid ;
    input [31:0]  addr ;
    input [15:0]  blen ; // burst length: 1, 2, ...
    input [ 1:0]  burst; // 0:fixed, 1:incr, 2:wrap
begin
    axi_arid_o    <= arid;
    axi_araddr_o  <= addr; 
    /* verilator lint_off WIDTH */
    axi_arlen_o   <= (blen - 1);
    /* verilator lint_on WIDTH */
    axi_arburst_o <= burst; 
    axi_arvalid_o <= 1'b1;  

    @ (posedge clk);
    while (axi_arready_i == 1'b0) @ (posedge clk);

    axi_arvalid_o <= 1'b0;  
end
endtask

task axi_master_read_r;
    input [ 3:0]  arid ;
    input [15:0]  blen ; // burst length: 1, 2, ...
    input         delay; // 0:don't use delay
    
    integer idx;
    integer rdelay;
begin
    axi_rready_o <= 1;    

    for (idx = 0; idx < blen; idx = idx+1) begin
        @ (posedge clk); 
        while (axi_rvalid_i == 1'b0) @ (posedge clk);

        rdata[idx] = axi_rdata_i; // simply store the read-data; should be blocking
        if (axi_rresp_i!=2'b00) begin
            $display($time,,"%m ERROR RD RRESP no-ok 0x%02x", axi_rresp_i);
        end
        if (axi_rid_i != arid) begin
            $display($time,,"%m ERROR RD RID mis-match 0x%4x:0x%04x", axi_rid_i, arid);
        end
        if (idx == (blen-1)) begin
            if (axi_rlast_i == 1'b0) begin
                $display($time,,"%m ERROR RD RLAST not driven");
            end
        end else begin
            if (axi_rlast_i == 1'b1) begin
                $display($time,,"%m ERROR RD RLAST not expected");
            end
            if (delay) begin
                rdelay = {$random(seed_tread)}%5;
                if (rdelay > 0) begin
                    axi_rready_o <= 0;    
                    repeat (rdelay) @ (posedge clk); 
                    axi_rready_o <= 1;    
                end
            end
        end
    end
    axi_rready_o <= 0;    
end
endtask







`endif


