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

`define DPRINTF  //$display

module sdram_model
(
    input          clk     ,
    input          cke_i   ,
    input          csb_i   ,
    input          rasb_i  ,
    input          casb_i  ,
    input          web_i   ,
    input [  1:0]  dqm_i   ,
    input [ 12:0]  addr_i  ,
    input [  1:0]  ba_i    ,
    inout [ 15:0]  dq_io   
);

    //-----------------------------------------------------------------
    // Key Params
    //-----------------------------------------------------------------
    parameter SDRAM_MHZ             = 50;
    parameter SDRAM_ADDR_W          = 24;
    parameter SDRAM_COL_W           = 9;
    parameter SDRAM_READ_LATENCY    = 2;

    //-----------------------------------------------------------------
    // Defines / Local params
    //-----------------------------------------------------------------
    localparam SDRAM_BANK_W          = 2;
    localparam SDRAM_DQM_W           = 2;
    localparam SDRAM_BANKS           = 2 ** SDRAM_BANK_W;
    localparam SDRAM_ROW_W           = SDRAM_ADDR_W - SDRAM_COL_W - SDRAM_BANK_W;
    localparam SDRAM_REFRESH_CNT     = 2 ** SDRAM_ROW_W;
    localparam SDRAM_START_DELAY     = 100000 / (1000 / SDRAM_MHZ); // 100uS
    localparam SDRAM_REFRESH_CYCLES  = (64000*SDRAM_MHZ) / SDRAM_REFRESH_CNT-1;
    localparam NUM_ROWS              = (1 << SDRAM_ROW_W);

    localparam MAX_ROW_OPEN_TIME     = 35 * 1000; // 35 us 
    localparam MIN_ACTIVE_TO_ACTIVE  = 60;        // 60 ns 
    localparam MIN_ACTIVE_TO_ACCESS  = 15;        // 15 ns 
    localparam MAX_ROW_REFRESH_TIME  = (64 * 1000 * 1000) / NUM_ROWS + 200; // Add some slack (FIXME) 

    localparam CMD_W             = 4;
    localparam CMD_INHIBIT       = 4'b1000;
    localparam CMD_NOP           = 4'b0111;
    localparam CMD_ACTIVE        = 4'b0011;
    localparam CMD_READ          = 4'b0101;
    localparam CMD_WRITE         = 4'b0100;
    localparam CMD_TERMINATE     = 4'b0110;
    localparam CMD_PRECHARGE     = 4'b0010;
    localparam CMD_REFRESH       = 4'b0001;
    localparam CMD_LOAD_MODE     = 4'b0000;

    localparam T_QDELAY          = 0.5;

    //-----------------------------------------------------------------
    // Registers / Wires
    //-----------------------------------------------------------------
    integer      i;

    reg          enable_delays;
    reg          configured   ;
    integer      burst_type   ;
    integer      burst_length ;

    reg          write_burst_en;
    integer      cas_latency;

    integer      active_row[0:SDRAM_BANKS-1];
    time         activate_time[0:SDRAM_BANKS-1];

    time         last_refresh;
    reg  [31:0]  refresh_cnt;

    integer      burst_write;
    integer      burst_read;
    reg          burst_close_row[0:SDRAM_BANKS-1];
    integer      burst_offset;    

    reg  [SDRAM_COL_W-1:0]  col  = 0;
    reg  [SDRAM_ROW_W-1:0]  row  = 0;
    reg  [SDRAM_BANK_W-1:0] bank = 0;
    reg  [31:0]             addr = 0;

    reg  [15:0]      resp_data[0:2];
    reg              resp_enable[0:2];
    reg  [CMD_W-1:0] new_cmd;
    reg  [15:0]      dq_reg;   

    reg         en_ap = 0;
    reg  [31:0] data;
    reg  [ 7:0] mask;

    //sdram process
    initial 
    begin
        enable_delays = 1'b1;
        configured    = 1'b0;
        burst_write   = 0;
        burst_read    = 0;

        for (i = 0; i < SDRAM_BANKS; i = i+1)
            active_row[i] = -1;

        // Clear response pipeline
        for (i = 0; i < 3; i = i+1) begin
            resp_data  [i] = 0;
            resp_enable[i] = 0;
        end
        dq_reg = 16'bz;

        for (i = 0; i < SDRAM_BANKS; i = i+1)
            activate_time[i] = $time;

        refresh_cnt = 0;

        forever @(posedge clk) 
        begin
            // Command decoder
            if (csb_i)
                new_cmd = CMD_INHIBIT;
            else
                new_cmd = {csb_i, rasb_i, casb_i, web_i};

            // Check row open time...
            for (i = 0; i < SDRAM_BANKS; i = i+1) begin
                if (active_row[i] != -1 && ($time - activate_time[i]) > MAX_ROW_OPEN_TIME)
                begin
                    $display("Row open too long...");
                    $finish;
                end
            end

            resp_enable[cas_latency-2] = 1'b0;

            // Configure SDRAM
            if (new_cmd == CMD_LOAD_MODE) begin
                configured      = 1'b1;
                burst_type      = addr_i[3]; 
                write_burst_en  = addr_i[9];
                burst_length    = addr_i[2:0]; 
                cas_latency     = addr_i[6:4]; 

                $display("SDRAM: MODE - write burst %d, burst len %d, CAS latency %d\n", write_burst_en, burst_length, cas_latency);

                if (burst_type != 1'b0) begin
                    $display("Assertion failed: burst_type is not SEQUENTIAL!");
                    $finish;
                end
            end
            // Auto refresh
            else if (new_cmd == CMD_REFRESH) begin

                // Check no rows open..
                for (i = 0; i < SDRAM_BANKS; i = i+1) begin
                    if (active_row[i] != -1) begin
                        $display("Refresh failed, Row %d opened!", i);
                        $finish;
                    end
                end                

                // Once init sequence complete, check for auto-refresh period...
                if (refresh_cnt > 2) begin
                    if (($time -  last_refresh) >= MAX_ROW_OPEN_TIME) begin
                        $display("Refresh failed, refresh interval exceeds MAX_ROW_OPEN_TIME!");
                        $finish;
                    end
                end

                last_refresh = $time;

                if (refresh_cnt < 32'hFFFFFFFF) begin
                    refresh_cnt = refresh_cnt + 1;
                end
            end
            // Row is activated and copied into the row buffer of the bank
            else if (new_cmd == CMD_ACTIVE) begin
                if (!configured) begin
                    $display("Activate failed, SDRAM mode register is not configured!");
                    $finish;
                end
                if (refresh_cnt < 2) begin
                    $display("Activate failed, refresh_cnt < 2!");
                    $finish;
                end

                bank = ba_i  ;
                row  = addr_i;

                DPRINTF("SDRAM: ACTIVATE Row = 0x%h, Bank = 0x%h\n", row, bank);

                // A row should not be open
                if (active_row[bank] != -1) begin
                    $display("Activate failed, a row should not be open!");
                    $finish;
                end

                // ACTIVATE periods long enough...
                if (($time - activate_time[bank]) <= MIN_ACTIVE_TO_ACTIVE) begin
                    $display("Activate failed, activate periods <= MIN_ACTIVE_TO_ACTIVE!");
                    $finish;
                end

                // Mark row as open
                active_row[bank]    = row;
                activate_time[bank] = $time;
            end
            // Read command
            else if (new_cmd == CMD_READ) begin
                if (!configured) begin
                    $display("Read failed, SDRAM mode register is not configured!");
                    $finish;
                end

                en_ap = addr_i[10];   
                col   = addr_i[SDRAM_COL_W-1:0]; 
                bank  = ba_i; 
                row   = active_row[bank];

                // A row should be open
                if (active_row[bank] == -1) begin
                    $display("Read failed, a row should be open!");
                    $finish;
                end

                // DQM expected to be low
                if (dqm_i != 2'b0) begin
                    $display("Read failed, DQM expected to be low!");
                    $finish;
                end

                // Check row activate timing
                if (($time - activate_time[bank]) <= MIN_ACTIVE_TO_ACCESS) begin
                    $display("Read failed, row activate time <= MIN_ACTIVE_TO_ACCESS!");
                    $finish;
                end

                // Address = RBC
                addr[SDRAM_COL_W:2]                                        = col[SDRAM_COL_W-1: 1];
                addr[SDRAM_COL_W+SDRAM_BANK_W: SDRAM_COL_W+SDRAM_BANK_W-1] = bank;
                addr[31: SDRAM_COL_W+SDRAM_BANK_W+1]                       = row ;

                burst_offset = 0;

                data = read32(addr);
                DPRINTF("SDRAM: READ 0x%08h = 0x%08h [Row=0x%h, Bank=0x%h, Col=0x%h]\n", addr, data, row, bank, col);

                resp_data  [cas_latency-2] = data >> (burst_offset * 8);
                resp_enable[cas_latency-2] = 1'b1;
                burst_offset = burst_offset + 2;

                case (burst_length)
                    0:       burst_read = 1-1;
                    1:       burst_read = 2-1;
                    2:       burst_read = 4-1;
                    3:       burst_read = 8-1;
                    default: burst_read = 1-1;
                endcase

                burst_close_row[bank] = en_ap;
            end // Read command
            // Write command
            else if (new_cmd == CMD_WRITE) begin
                if (!configured) begin
                    $display("Write failed, SDRAM mode register is not configured!");
                    $finish;
                end

                en_ap = addr_i[10];   
                col   = addr_i[SDRAM_COL_W-1:0]; 
                bank  = ba_i; 
                row   = active_row[bank];

                // A row should be open
                if (active_row[bank] == -1) begin
                    $display("Write failed, a row should be open!");
                    $finish;
                end

                // Check row activate timing
                if (($time - activate_time[bank]) <= MIN_ACTIVE_TO_ACCESS) begin
                    $display("Write failed, row activate time <= MIN_ACTIVE_TO_ACCESS!");
                    $finish;
                end

                // Address = RBC
                addr[SDRAM_COL_W:2]                                        = col[SDRAM_COL_W-1: 1];
                addr[SDRAM_COL_W+SDRAM_BANK_W: SDRAM_COL_W+SDRAM_BANK_W-1] = bank;
                addr[31: SDRAM_COL_W+SDRAM_BANK_W+1]                       = row ;

                data = dq_io; 
                mask = 0;
                
                burst_offset = 0;

                data = data << (burst_offset * 8); 
                mask = 'h3  << (burst_offset);

                // Lower byte - disabled
                if (dqm_i[0]) begin
                    data = data & (~('hff << ((burst_offset + 0) * 8)));
                    mask = mask & (~(1 << (burst_offset + 0)));
                end

                // Upper byte disabled
                if (dqm_i[1]) begin
                    data = data & (~('hff << ((burst_offset + 1) * 8)));
                    mask = mask & (~(1 << (burst_offset + 1))); 
                end
 
                DPRINTF("SDRAM: WRITE 0x%08h = 0x%08h MASK=0x%h [Row=0x%h, Bank=0x%h, Col=0x%h]\n", addr, data, mask, row, bank, col);
                write32(addr, (data) << 0, mask);
                burst_offset = burst_offset + 2;

                // Configure remaining burst length
                if (write_burst_en) begin
                    case (burst_length)
                        0:       burst_write = 1-1;
                        1:       burst_write = 2-1;
                        2:       burst_write = 4-1;
                        3:       burst_write = 8-1;
                        default: burst_write = 1-1;
                    endcase
                end 
                else begin
                    burst_write = 0;
                end

                burst_close_row[bank] = en_ap;
            end // Write command
            // Row is precharged and stored back into the memory array
            else if (new_cmd == CMD_PRECHARGE) begin
                if (!configured) begin
                    $display("Precharge failed, SDRAM mode register is not configured!");
                    $finish;
                end

                // All banks
                if (addr_i[10]) begin
                    // Close rows
                    for (i = 0; i < SDRAM_BANKS; i = i+1)
                        active_row[i] = -1;
                    DPRINTF("SDRAM: PRECHARGE - all banks\n");
                end
                // Specified bank
                else begin
                    bank  = ba_i; 

                    DPRINTF("SDRAM: PRECHARGE Bank=0x%h, Active Row=0x%h\n", bank, active_row[bank]);

                    // Close specific row
                    active_row[bank] = -1;
                end
            end //Precharge Command
            // Terminate read or write burst
            else if (new_cmd == CMD_TERMINATE) begin
                burst_write = 0;
                burst_read  = 0;

                DPRINTF("SDRAM: Burst terminate\n");
            end
            // WRITE: Burst continuation...
            if (burst_write > 0 && new_cmd == CMD_NOP) begin
                data = dq_io; 
                mask = 0;

                data = data << (burst_offset * 8); 
                mask = 'h3  << (burst_offset);

                // Lower byte - disabled
                if (dqm_i[0]) begin
                    data = data & (~('hff << ((burst_offset + 0) * 8)));
                    mask = mask & (~(1 << (burst_offset + 0)));
                end

                // Upper byte disabled
                if (dqm_i[1]) begin
                    data = data & (~('hff << ((burst_offset + 1) * 8)));
                    mask = mask & (~(1 << (burst_offset + 1))); 
                end

                DPRINTF("SDRAM: WRITE 0x%08h = 0x%08h MASK=0x%h [Row=0x%h, Bank=0x%h, Col=0x%h]\n", addr, data, mask, row, bank, col);
                write32(addr, (data) << 0, mask);
                burst_offset = burst_offset + 2;

                // Continue...
                if (burst_offset == 4) begin
                    burst_offset = 0;
                    addr = addr + 4;
                end

                burst_write = burst_write - 1;

                if (burst_write == 0 && burst_close_row[bank]) begin
                    // Close specific row
                    active_row[bank] = -1;
                end
            end // WRITE: Burst continuation...
            // READ: Burst continuation
            else if (burst_read > 0 && new_cmd == CMD_NOP) begin
                data = read32(addr);
                DPRINTF("SDRAM: READ 0x%08h = 0x%08h [Row=0x%h, Bank=0x%h, Col=0x%h]\n", addr, data, row, bank, col);

                resp_data  [cas_latency-2] = data >> (burst_offset * 8);
                resp_enable[cas_latency-2] = 1'b1;
                burst_offset = burst_offset + 2;

                // Continue...
                if (burst_offset == 4) begin
                    burst_offset = 0;
                    addr = addr + 4;
                end

                burst_read = burst_read - 1;

                if (burst_read == 0 && burst_close_row[bank]) begin
                    // Close specific row
                    active_row[bank] = -1;
                end
            end // READ: Burst continuation

            #T_QDELAY;
            dq_reg = (resp_enable[0]) ? resp_data[0] : 16'bz;

            // Shuffle read data
            for (i = 1; i < 3; i = i+1) begin
                resp_data  [i-1] = resp_data  [i];
                resp_enable[i-1] = resp_enable[i];
            end
        end // forever
    end //initial

    assign dq_io = dq_reg;

    // iverilog does not support large arrays...
    // Each array is 4M x 8-bit
    localparam ARRAY_SIZE = 4*1024 * 1024;

    // Generate 16 arrays--512M bit
    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : array_gen
            reg [7:0] mem_array [0:ARRAY_SIZE-1];    
        end
    endgenerate

    //-----------------------------------------------------------------
    // write32: Write a 32-bit word to memory
    //-----------------------------------------------------------------
    task write32;
        input [31:0] addr;
        input [31:0] data;
        input [ 7:0] strb;

        integer i;
        reg [31:0] byte_addr;
        reg [31:0] byte_data;

        begin
            for (i = 0; i < 4; i = i+1) begin
                if (strb & (1 << i)) begin
                    byte_addr = addr + i;
                    byte_data = data >> (i*8);

                    case (byte_addr[31:22])
                        0 : array_gen[0 ].mem_array[byte_addr[21:0]] = byte_data[7:0];
                        1 : array_gen[1 ].mem_array[byte_addr[21:0]] = byte_data[7:0];
                        2 : array_gen[2 ].mem_array[byte_addr[21:0]] = byte_data[7:0];
                        3 : array_gen[3 ].mem_array[byte_addr[21:0]] = byte_data[7:0];
                        4 : array_gen[4 ].mem_array[byte_addr[21:0]] = byte_data[7:0];
                        5 : array_gen[5 ].mem_array[byte_addr[21:0]] = byte_data[7:0];
                        6 : array_gen[6 ].mem_array[byte_addr[21:0]] = byte_data[7:0];
                        7 : array_gen[7 ].mem_array[byte_addr[21:0]] = byte_data[7:0];
                        8 : array_gen[8 ].mem_array[byte_addr[21:0]] = byte_data[7:0];
                        9 : array_gen[9 ].mem_array[byte_addr[21:0]] = byte_data[7:0];
                        10: array_gen[10].mem_array[byte_addr[21:0]] = byte_data[7:0];
                        11: array_gen[11].mem_array[byte_addr[21:0]] = byte_data[7:0];
                        12: array_gen[12].mem_array[byte_addr[21:0]] = byte_data[7:0];
                        13: array_gen[13].mem_array[byte_addr[21:0]] = byte_data[7:0];
                        14: array_gen[14].mem_array[byte_addr[21:0]] = byte_data[7:0];
                        15: array_gen[15].mem_array[byte_addr[21:0]] = byte_data[7:0];
                        default: ;
                    endcase
                end //if
            end //for
        end
    endtask

    //-----------------------------------------------------------------
    // read32: Read a 32-bit word from memory
    //-----------------------------------------------------------------
    function [31:0] read32;
        input [31:0] addr;
        integer i;
        reg   [31:0] byte_addr;
        reg   [31:0] byte_data;
        begin
            read32 = 0;

            for (i = 0; i < 4; i = i+1) begin
                byte_addr = addr + i;
                byte_data = 0;

                case (byte_addr[31:22])
                    0 : byte_data[7:0] = array_gen[0 ].mem_array[byte_addr[21:0]];
                    1 : byte_data[7:0] = array_gen[1 ].mem_array[byte_addr[21:0]];
                    2 : byte_data[7:0] = array_gen[2 ].mem_array[byte_addr[21:0]];
                    3 : byte_data[7:0] = array_gen[3 ].mem_array[byte_addr[21:0]];
                    4 : byte_data[7:0] = array_gen[4 ].mem_array[byte_addr[21:0]];
                    5 : byte_data[7:0] = array_gen[5 ].mem_array[byte_addr[21:0]];
                    6 : byte_data[7:0] = array_gen[6 ].mem_array[byte_addr[21:0]];
                    7 : byte_data[7:0] = array_gen[7 ].mem_array[byte_addr[21:0]];
                    8 : byte_data[7:0] = array_gen[8 ].mem_array[byte_addr[21:0]];
                    9 : byte_data[7:0] = array_gen[9 ].mem_array[byte_addr[21:0]];
                    10: byte_data[7:0] = array_gen[10].mem_array[byte_addr[21:0]];
                    11: byte_data[7:0] = array_gen[11].mem_array[byte_addr[21:0]];
                    12: byte_data[7:0] = array_gen[12].mem_array[byte_addr[21:0]];
                    13: byte_data[7:0] = array_gen[13].mem_array[byte_addr[21:0]];
                    14: byte_data[7:0] = array_gen[14].mem_array[byte_addr[21:0]];
                    15: byte_data[7:0] = array_gen[15].mem_array[byte_addr[21:0]];
                    default: ;
                endcase

                read32 = read32 | byte_data;
            end //for
        end
    endfunction

endmodule

