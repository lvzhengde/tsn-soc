/*+
 * Copyright (c) 2022-2025 Zhengde
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
 * Description :
 * IEEE1588-2008 style Real Time Counter (RTC)
 *  - 48-bit seconds field
 *  - 32-bit nanoseconds field
 *
 * Notes:
 *  - The module provides a simple implementation of the RTC
 *    logic suitable for use in TB  where PTP time arithmetic is required.
-*/

module qbv_rtc (
    input           clk,
    input           rst_n,

    // Outputs: current time
    output [79:0]   CurrentTime_o
);
    reg    [47:0]   seconds_q;
    reg    [31:0]   nanoseconds_q;
    reg             set_time_q;

    // Constant: number of nanoseconds per second
    parameter  [63:0] TICK_VALUE = 64'd8;
    parameter         Q_DELAY    = 1;
    localparam [31:0] NS_PER_SEC = 32'd1000000000;

    // Testbench thread: emulate tick_value-ns ticks by calling add_nanoseconds_task(1)
    initial begin
        seconds_q     = 48'd0;
        nanoseconds_q = 32'd0;
        set_time_q    = 1'b0;

        // small delay to align
        @(posedge clk);

        // main loop for RTC
        forever begin
            // add tick value on every rising edge of clk
            if (!rst_n) begin
                seconds_q     = 48'd0;
                nanoseconds_q = 32'd0;
            end else if(set_time_q == 1'b0) begin
                add_nanoseconds_task(TICK_VALUE);
            end
        end
    end

    // Task-based API for testbench/control usage
    // Note: tasks are intended for simulation/testbench use. They perform
    // synchronous updates by sampling on the next rising clock edge.

    // set_time: synchronously set seconds and nanoseconds
    task set_time_task;
        input [47:0] set_seconds;
        input [31:0] set_nanoseconds;
        reg   [31:0] tmp_ns;
        reg   [47:0] carry_sec;
    begin
        set_time_q    = 1'b1;

        // Wait for a clock edge and then update synchronously
        @(posedge clk);
        if (!rst_n) begin
            seconds_q     = 48'd0;
            nanoseconds_q = 32'd0;
            set_time_q    = 1'b0;
        end else begin
            tmp_ns    = (set_nanoseconds >= NS_PER_SEC) ? (set_nanoseconds % NS_PER_SEC) : set_nanoseconds;
            carry_sec = (set_nanoseconds >= NS_PER_SEC) ? (set_nanoseconds / NS_PER_SEC) : 0;
            #(Q_DELAY);
            seconds_q     = set_seconds + carry_sec;
            nanoseconds_q = tmp_ns;
        end

        @(posedge clk);
        set_time_q    = 1'b0;
    end
    endtask

    // add_nanoseconds_task: synchronously add arbitrary nanoseconds value
    task add_nanoseconds_task;
        input [63:0] add_ns; // allow large adds
        reg   [63:0] sum64;
        reg   [47:0] carry_sec;
    begin
        @(posedge clk);
        if (!rst_n) begin
            // ignore while in reset
        end else begin
            sum64         = {32'd0, nanoseconds_q} + add_ns;
            carry_sec     = sum64 / NS_PER_SEC;
            #(Q_DELAY);
            seconds_q     = seconds_q + carry_sec;
            nanoseconds_q = sum64 % NS_PER_SEC;
        end
    end
    endtask

    // capture_time_task: atomic capture of current time
    task capture_time_task;
        output [47:0] out_seconds;
        output [31:0] out_nanoseconds;
    begin
        @(posedge clk);
        out_seconds     = seconds_q;
        out_nanoseconds = nanoseconds_q;
    end
    endtask

    assign CurrentTime_o = {seconds_q, nanoseconds_q};

endmodule
