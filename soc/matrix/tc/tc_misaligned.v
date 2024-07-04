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
 * AXI4 protocol test, 1 master communicate with 1 slave
 * Address misaligned
-*/

//`timescale 1ns/1ns

module tc_misaligned;
    parameter NUM_MST = 4;
    parameter NUM_SLV = 6;

    tb_top
    #(
        .NUM_MST    (NUM_MST),
        .NUM_SLV    (NUM_SLV)
    )
    tb_top();

    //stimulus
    //MST 0 to SLV 1
    reg  [31:0] saddr;
    reg         delay;
    reg  [15:0] blen ;
    integer     random;
    integer     i;

    initial
    begin
        saddr  = 0;
        delay  = 0;
        blen   = 0;
        random = 0;

        tb_top.reset;
        tb_top.BLK_MST[0].u_axi4_master.busy_o = 1;

        repeat (5) @(posedge tb_top.clk);

        //Misaligend burst tests
        saddr  = 32'h90000000 + 32'h100;  
        delay  = 0;
        random = 0;
        for (i = 0; i < 4; i = i+1) begin
            for (blen = 1; blen <= 16; blen = blen+1) begin
                tb_top.BLK_MST[0].u_axi4_master.test_burst(saddr+i, blen, 2'b01, delay, random);
            end
        end

        repeat (50) @ (posedge tb_top.clk);

        saddr  = 32'h90000000 + 32'h200;  
        delay  = 1;
        random = 1;
        for (i = 0; i < 4; i = i+1) begin
            for (blen = 1; blen <= 16; blen = blen+1) begin
                random = random + 1;
                tb_top.BLK_MST[0].u_axi4_master.test_burst(saddr+i, blen, 2'b01, delay, random);
            end
        end

        repeat (50) @ (posedge tb_top.clk);

        //Finish stimulus
        tb_top.BLK_MST[0].u_axi4_master.busy_o = 0;

        repeat (50) @(posedge tb_top.clk);

        while (tb_top.BLK_MST[0].u_axi4_master.busy_i == 1'b1) @(posedge tb_top.clk);
    end

    //wait done signals 
    integer idz;

    initial 
    begin
        wait(tb_top.rst_n == 1'b0);
        wait(tb_top.rst_n == 1'b1);

        for (idz = 0; idz < NUM_MST; idz = idz+1) begin
            wait(tb_top.done[idz] == 1'b1);
        end

        repeat (50) @ (posedge tb_top.clk);

        $display("MST 0 to SLV 1 Misaligned Test Finished!!!");
        $finish;
    end

    //dump waveform to vcd file
    initial
    begin
        $dumpfile("misaligned.vcd");
        $dumpvars(0, tc_misaligned);
        $dumpon;
        //$dumpoff;
    end

endmodule
