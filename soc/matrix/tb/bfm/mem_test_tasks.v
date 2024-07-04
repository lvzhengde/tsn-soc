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

`ifndef MEM_TEST_TASKS_V_
`define MEM_TEST_TASKS_V_

reg  error_flag = 0;

always @(*) begin
    if (error_flag == 1) begin
         repeat (50) @ (posedge clk);
         $finish(2);
    end
end

integer seed_mread  = 9;
integer seed_mwrite = 11;


task test_single;
    input [31:0]  addr;
    input         delay;
begin
     wdata[0] = $random; //{(16){ID[1:0]}} + 1;
     axi_master_write(addr, 1, 1, delay);
     axi_master_read (addr, 1, 1, delay);
     axi_master_rmw  (addr,       delay);
end
endtask


task test_burst;
    input [31:0]   addr;
    input [15:0]   blen;  // burst length: 1 ~ 16
    input [ 1:0]   burst; // burst type
    input          delay;
    input integer  random;

    integer offset, ind, seed, w, error;
    reg [31:0] loc;
    reg [31:0] patt, mask;
begin
    loc  = addr;
    seed = random;
    
    for (ind = 0; ind < blen; ind = ind+1) begin
        wdata[ind] = 'hX; // make unknown
        offset     = loc[1:0];

        if (random == 0) begin
            wdata[ind] = {(16){ID[1:0]}} + ind;
        end 
        else begin
            for (w =0; w < 4; w = w+1) begin
                 wdata[ind][8*w+:8] = $random(seed) & 'hFF;
            end
        end

        if (offset > 0) wdata[ind] = wdata[ind] << (8*offset);
        loc = loc + 4;
    end

    axi_master_write(addr, blen, burst, delay);
    axi_master_read (addr, blen, burst, delay);

    patt  = (1<<(8*4))-1;
    loc   = addr;
    error = 0;

    for (ind = 0; ind < blen; ind = ind+1) begin
        offset = loc[1:0];
        mask   = patt << (8*offset);
        if ((wdata[ind] & mask) !== (rdata[ind] & mask)) begin
            $display("%0t %m mismatch A:0x%x D:0x%x, but 0x%x expected %0d-byte width: %0d-length",
            $time, addr, rdata[ind]&mask, wdata[ind]&mask, 4, blen);
            error = error + 1;
        end
        loc = loc + 4;
    end
    if (error==0) $display($time,,"%m test_burst %0d-byte width: %0d-length OK", 4, blen);
    else          $display($time,,"%m test_burst %0d-byte width: %0d-length error %0d", 4, blen, error);
end
endtask


task mem_test;
    input [31:0]  start_addr;
    input [31:0]  end_addr;
    input         delay; // 1 for delay added
    
    reg   [31:0]  addr;
    reg   [31:0]  data;
    reg   [31:0]  store[0:1023];
    integer  idx, error;
begin
    if ((end_addr - start_addr) > 1023) begin
        $display($time,,"%m out-of-range 0x%x: should be smaller than 1024",
                         (end_addr - start_addr));
    end

    idx = 0;
    for (addr = start_addr; (addr+4-1) <= end_addr; addr = addr+4) begin
        wdata[0]   = get_data(0) & get_mask(addr);
        store[idx] = wdata[0];
        axi_master_write(addr, 1, 1, delay);
        idx = idx + 1;
    end

    idx   = 0;
    error = 0;

    for (addr = start_addr; (addr+4-1) <= end_addr; addr = addr+4) begin
        axi_master_read(addr, 1, 1, delay);
        data = rdata[0] & get_mask(addr);
        if (data !== store[idx]) begin
            error = error + 1;
            $display($time,,"%m mismatch A:0x%x D:0x%x, but 0x%x expected",
                             addr, data, store[idx]);
            error_flag = 1;
        end
        idx = idx + 1;
    end

    if (error == 0)
    $display($time,,"%m mem_test OK for %02d-byte from 0x%x to 0x%x",
                     4, start_addr, end_addr);
end
endtask


task mem_test_burst;
    input [31:0]  start_addr;
    input [31:0]  end_addr;
    input [15:0]  blen; // burst len: 1-16
    input         delay;

    reg   [31:0]  addr;
    reg   [31:0]  data;
    reg   [31:0]  store[0:1023];
    integer idy;
    integer error, a, b;
begin
    if ((end_addr - start_addr) > 1023) begin
        $display($time,,"%m out-of-range 0x%x: should be smaller than 1024",
                         (end_addr-start_addr));
    end

    idy = 0;
    for (addr = start_addr; (addr+4*blen-1) <= end_addr; addr = addr+4*blen) begin
        a = addr;
        for (b =0; b < blen; b = b+1) begin
            if (0) begin
                wdata[b] = get_data(0) & get_mask(a);
            end 
            else begin
                wdata[b] = addr & get_mask(a);
            end

            store[idy+b] = wdata[b];
            a = get_next_addr_mem(a);
        end
        axi_master_write(addr, blen, 1, delay);
        idy = idy + blen;
    end

    error = 0;
    idy   = 0;

    for (addr = start_addr; (addr+4*blen-1) <= end_addr; addr = addr+4*blen) begin
        axi_master_read(addr, blen, 1, delay);
        a = addr;
        for (b = 0; b < blen; b = b+1) begin
            data = rdata[b] & get_mask(a);
            if (data !== store[idy+b]) begin
                error = error + 1;
                $display($time,,"%m mismatch A:0x%x D:0x%x, but 0x%x expected",
                                 addr, data, store[idy+b]);
                error_flag = 1;
            end
            a = get_next_addr_mem(a);
        end
        idy = idy + blen;
    end

    if (error == 0)
    $display($time,,"%m mem_test_burst OK for %02d-byte %02d-length from 0x%x to 0x%x",
                     4, blen, start_addr, end_addr);
end
endtask


function  [31:0] get_data;
    input [31:0] dummy;
begin
    get_data = {$random(seed_mwrite)};
end
endfunction

function  [31:0]  get_mask;
    input [31:0]  addr;

    reg   [31:0]  mask; 
    reg   [ 1:0]  offset;
begin
    mask     = 32'hFFFF_FFFF;
    offset   = addr[1:0];
    get_mask = mask << (offset*8);
end
endfunction

function  [31:0] get_next_addr_mem;
    input [31:0] addr;
begin
    get_next_addr_mem[ 1:0] = 0;
    get_next_addr_mem[31:2] = addr[31:2] + 1;
end
endfunction

`endif

