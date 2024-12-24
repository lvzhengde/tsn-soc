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
 *  Description : Simple test case for write/read of SDRAM
 *  File        : tc_simple.v
-*/

module tc_simple;

    tb_top tb();
    defparam tb.SDRAM_MHZ          = 50;
    defparam tb.SDRAM_ADDR_W       = 24;
    defparam tb.SDRAM_COL_W        = 9;
    defparam tb.SDRAM_READ_LATENCY = 2;

    integer  seed = 20;
    integer  len  = 16; 
    integer  idx ;

    reg  [31:0] wr_data[0:255];
    reg  [31:0] rd_data[0:255];
    reg  [31:0] temp      ;
    reg  [31:0] addr      ; 
    reg  [31:0] begin_addr = 0; 

    initial begin
        temp    = 0;   
        addr    = begin_addr; 
    
        #10;
        $display($time,, "SDRAM Write/Read Test, Simulation Start!");

        $display($time,, "Reset testbench...");
        tb.reset;
        #10;

        //-----------------------------------------------------------------
        // Prepare Test Data
        //-----------------------------------------------------------------        
        for (idx = 0; idx < len; idx = idx+1) begin
            wr_data[idx] = $random(seed);
            $display($time,, "%m idx = %d, prepare test data = 0x%08x", idx, wr_data[idx]);
        end

        #1000_000;  //wait 1ms

        //-----------------------------------------------------------------
        // Write Data to SDRAM
        //-----------------------------------------------------------------        
        $display($time,, "\n Write Data to SDRAM...\n");
        for (idx = 0; idx < len; idx = idx+1) begin
            temp = wr_data[idx];
            tb.u_axi4_master.wdata[0] = temp;
            tb.u_axi4_master.axi_master_write(addr, 1, 1, 0);  
            addr = addr + 4;
        end

        #100;
        addr = begin_addr;

        //-----------------------------------------------------------------
        // Read Data from SDRAM
        //-----------------------------------------------------------------        
        $display($time,, "\n Read Data from SDRAM...\n");
        for (idx = 0; idx < len; idx = idx+1) begin
            tb.u_axi4_master.axi_master_read (addr, 1, 1, 0);
            rd_data[idx] = tb.u_axi4_master.rdata[0];
            $display($time,, "%m idx = %d, SDRAM read data = 0x%02x", idx, rd_data[idx]);
            addr = addr + 4;
        end

        //Enable AXI statistics
        tb.test_busy = 1'b0;
        #200;

        //Scoreboard
        $display("\n\n SCOREBOARD...");
        for (idx = 0; idx < len; idx = idx+1) begin
            $display("idx = %d, prepared test data = 0x%08x, SDRAM read data = 0x%08x", idx, wr_data[idx], rd_data[idx]);
            if (rd_data[idx] !== wr_data[idx]) begin
                    $display("ERROR: SDRAM read data not equal to prepared test data!");
                    $finish(2);                
            end
        end

        #5000;
        $display("SIMULATION PASS!!!");
        $finish;
    end


    initial
    begin
        $dumpfile("simple.fst");
        $dumpvars(0, tc_simple);
        $dumpon;
        //$dumpoff;
    end
endmodule
