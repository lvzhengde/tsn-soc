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
    reg  [CMD_W-1:0] new_cmd;

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
        for (i = 0; i < 3; i = i+1)
            resp_data[i] = 0;

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

        end // forever
    end //initial

endmodule

