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
 * AXI4 bus master behavioral model
-*/

module axi4_master
#(
    parameter ID = 0
)
(
    input wire           clk             ,
    input wire           rst_n           ,

    input wire           axi_awready_i   ,
    input wire           axi_wready_i    ,
    input wire           axi_bvalid_i    ,
    input wire  [  1:0]  axi_bresp_i     ,
    input wire  [  3:0]  axi_bid_i       ,
    input wire           axi_arready_i   ,
    input wire           axi_rvalid_i    ,
    input wire  [ 31:0]  axi_rdata_i     ,
    input wire  [  1:0]  axi_rresp_i     ,
    input wire  [  3:0]  axi_rid_i       ,
    input wire           axi_rlast_i     ,

    output reg           axi_awvalid_o   ,
    output reg  [ 31:0]  axi_awaddr_o    ,
    output reg  [  3:0]  axi_awid_o      ,
    output reg  [  7:0]  axi_awlen_o     ,
    output reg  [  1:0]  axi_awburst_o   ,
    output reg           axi_wvalid_o    ,
    output reg  [ 31:0]  axi_wdata_o     ,
    output reg  [  3:0]  axi_wstrb_o     ,
    output reg           axi_wlast_o     ,
    output reg           axi_bready_o    ,
    output reg           axi_arvalid_o   ,
    output reg  [ 31:0]  axi_araddr_o    ,
    output reg  [  3:0]  axi_arid_o      ,
    output reg  [  7:0]  axi_arlen_o     ,
    output reg  [  1:0]  axi_arburst_o   ,
    output reg           axi_rready_o    ,

    input wire           busy_i          
);
    parameter AXI_ID  = ID << 2;
    parameter T_QDELAY = 0.1;

    reg  [ 31:0]  rdata[0:1023]; 
    reg  [ 31:0]  wdata[0:1023]; 

    reg  done = 1'b0;

    initial begin
        axi_awvalid_o = 0 ;
        axi_awaddr_o  = ~0 ;
        axi_awid_o    = 0 ;
        axi_awlen_o   = 0 ;
        axi_awburst_o = 0 ;
        axi_wvalid_o  = 0 ;
        axi_wdata_o   = ~0 ;
        axi_wstrb_o   = 0 ;
        axi_wlast_o   = 0 ;
        axi_bready_o  = 0 ;
        axi_arvalid_o = 0 ;
        axi_araddr_o  = ~0 ;
        axi_arid_o    = 0 ;
        axi_arlen_o   = 0 ;
        axi_arburst_o = 0 ;
        axi_rready_o  = 0 ;

        wait (rst_n == 1'b0);
        wait (rst_n == 1'b1);
        repeat (5) @ (posedge clk);

        #100;

        while (busy_i == 1'b1) @(posedge clk);

        repeat (5) @(posedge clk);

        done = 1'b1;
        axi_statistics(ID);
    end


    //----------------------------------------------------------------
    // Tasks and functions
    //----------------------------------------------------------------

    integer seed_tread  = 5;
    integer seed_twrite = 5;
    
    integer num_of_reads ; initial num_of_reads  = 0;
    integer num_of_writes; initial num_of_writes = 0;
    
    task axi_statistics;
        input integer id;
    begin
        $display("Master[%2d] reads =%5d,  writes =%5d", id, num_of_reads, num_of_writes);
    end
    endtask
    
    //----------------------------------------------------------------
    // reads blen words from addr and store the data input to rdata[]
    // read(addr+0);
    // read(addr+4);
    // read(addr+8);
    //  ... ...
    // read(addr+4*(blen-1));
    //----------------------------------------------------------------
    task axi_master_read;
        input [31:0]  addr ;
        input [15:0]  blen ; // burst length: 1, 2, ...
        input [ 1:0]  burst; // 0:fixed, 1:incr, 2:wrap
        input         delay; // 0:don't use delay
        
        reg   [ 3:0]  arid;
    begin
        arid = AXI_ID;
    
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
        #(T_QDELAY);

        axi_arid_o    = arid;
        axi_araddr_o  = addr; 
        /* verilator lint_off WIDTH */
        axi_arlen_o   = (blen - 1);
        /* verilator lint_on WIDTH */
        axi_arburst_o = burst; 
        axi_arvalid_o = 1'b1;  
    
        @ (posedge clk);
        while (axi_arready_i == 1'b0) @ (posedge clk);
        #(T_QDELAY);
    
        axi_arid_o    = 0;
        axi_araddr_o  = ~0; 
        axi_arlen_o   = 0;
        axi_arburst_o = 0; 
        axi_arvalid_o = 1'b0;  
    end
    endtask
    
    task axi_master_read_r;
        input [ 3:0]  arid ;
        input [15:0]  blen ; // burst length: 1, 2, ...
        input         delay; // 0:don't use delay
        
        integer idx;
        integer rdelay;
    begin
        #(T_QDELAY);
        axi_rready_o = 1;    
    
        for (idx = 0; idx < blen; idx = idx+1) begin
            @ (posedge clk); 
            while (axi_rvalid_i == 1'b0) @ (posedge clk);
    
            rdata[idx] = axi_rdata_i; 
            if (axi_rresp_i != 2'b00) begin
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
                        axi_rready_o = 0;    
                        repeat (rdelay) @ (posedge clk); 
                        axi_rready_o = 1;    
                    end
                end
            end
        end

        #(T_QDELAY);
        axi_rready_o = 0;    
    end
    endtask
    

    //----------------------------------------------------------------
    // write blen words to addr.
    // write(addr+0);
    // write(addr+4);
    // write(addr+8);
    //  ... ...
    // write(addr+4*(blen-1));
    //----------------------------------------------------------------
    task axi_master_write;
        input [31:0]  addr ;
        input [15:0]  blen ; // burst length: 1, 2, ...
        input [ 1:0]  burst; // 0:fixed, 1:incr, 2:wrap
        input         delay; // 0:don't use delay
        
        reg   [ 3:0]  awid;
    begin
        awid = AXI_ID;
        
        @ (posedge clk); 
        fork 
            axi_master_write_aw(awid, addr, blen, burst);
            axi_master_write_w(awid, addr, blen, burst, delay);
            axi_master_write_b(awid);
        join
    
        num_of_writes = num_of_writes + 1;
    end
    endtask
    
    task axi_master_write_aw;
        input [ 3:0]  awid ;
        input [31:0]  addr ;
        input [15:0]  blen ; // burst length: 1, 2, ...
        input [ 1:0]  burst; // 0:fixed, 1:incr, 2:wrap
    begin
        #(T_QDELAY);

        axi_awid_o    = awid ;
        axi_awaddr_o  = addr;
        /* verilator lint_off WIDTH */
        axi_awlen_o   = blen - 1;
        /* verilator lint_on WIDTH */
        axi_awburst_o = burst;
        axi_awvalid_o = 1'b1;
    
        @ (posedge clk); 
        while (axi_awready_i == 1'b0) @ (posedge clk);
        #(T_QDELAY);
    
        axi_awid_o    = 0 ;
        axi_awaddr_o  = ~0;
        axi_awlen_o   = 0;
        axi_awburst_o = 0;
        axi_awvalid_o = 1'b0;
    end
    endtask
    
    task axi_master_write_w;
        input [ 3:0]  awid ;
        input [31:0]  addr ;
        input [15:0]  blen ; // burst length: 1, 2, ...
        input [ 1:0]  burst; // 0:fixed, 1:incr, 2:wrap
        input         delay; // 0:don't use delay
        
        reg   [31:0]  addr_reg;
        integer idx;
        integer wdelay;
    begin
        #(T_QDELAY);
        addr_reg = addr;

        for (idx = 0; idx < blen; idx = idx+1) begin
            axi_wdata_o = wdata[idx];
            axi_wstrb_o = get_strb(addr_reg);
         
            if (idx == (blen-1))
                axi_wlast_o = 1'b1;
            else  
                axi_wlast_o = 1'b0;
    
            axi_wvalid_o = 1'b1;
    
            @ (posedge clk); 
            while (axi_wready_i == 1'b0) @ (posedge clk);
            #(T_QDELAY);
            addr_reg = get_next_addr(addr_reg, blen, burst);
    
            if (delay) begin
                wdelay = {$random(seed_twrite)}%5;
                if (wdelay > 0) begin
                    axi_wdata_o  = ~0;
                    axi_wlast_o  = 1'b0;
                    axi_wvalid_o = 1'b0;
                    repeat (wdelay) @ (posedge clk);
                end
            end
        end
    
        axi_wdata_o  = ~0;
        axi_wlast_o  = 1'b0;
        axi_wvalid_o = 1'b0;
    end
    endtask
    
    task axi_master_write_b;
        input [3:0] awid ;
    begin
        #(T_QDELAY);
        axi_bready_o = 1'b1;
        @ (posedge clk); 
        while (axi_bvalid_i == 1'b0) @ (posedge clk);
        #(T_QDELAY);
        axi_bready_o = 1'b0;
        if (axi_bresp_i != 2'b00) begin
            $display($time,,"%m ERROR WR BRESP no-ok 0x%02x", axi_bresp_i);
        end
        if (axi_bid_i != awid) begin
            $display($time,,"%m ERROR WR BID mis-match 0x%4x:0x%04x", axi_bid_i, awid);
        end
    end
    endtask


    function  [ 3:0] get_strb;
        input [31:0] addr ;
    
        reg   [ 3:0] offset;
    begin
        offset   = addr[1:0]; //offset = addr%4;
        get_strb = {4{1'b1}} << offset;
    end
    endfunction
    
    function  [31:0] get_next_addr;
        input [31:0]  addr ;
        input [15:0]  blen ; // burst length
        input [ 1:0]  burst; // burst type
    
        reg   [31:0] mask ;
    begin
        case (burst)
        2'b00: get_next_addr = addr;
        2'b01:
            get_next_addr = addr + 4;
        2'b10: 
        begin
            mask          = 4*blen-1;  //note: axlen = blen-1
            get_next_addr = (addr & ~mask) | ((addr + 4) & mask);
        end
        2'b11: 
        begin
            get_next_addr = addr + 4;
            // synopsys translate_off
            $display($time,,"%m ERROR un-defined BURST %01x", burst);
            // synopsys translate_on
            end
        endcase
    end
    endfunction


endmodule

