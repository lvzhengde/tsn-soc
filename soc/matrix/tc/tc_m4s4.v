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
 * AXI4 protocol test
 * MST 0-3 to SLV 1-4
-*/

//`timescale 1ns/1ns

module tc_m4s4;
    parameter NUM_MST = 4;
    parameter NUM_SLV = 6;

    tb_top
    #(
        .NUM_MST    (NUM_MST),
        .NUM_SLV    (NUM_SLV)
    )
    tb_top();


    generate
    genvar idx;

    for (idx = 0; idx < NUM_MST; idx = idx + 1) begin : BLK_STIM
        //stimulus
        reg  [31:0] saddr;
        reg         delay;
        reg  [15:0] blen ;
        integer     random;

        initial
        begin 
            saddr  = 0;
            delay  = 0;
            blen   = 0;
            random = 0;

            tb_top.reset;
            tb_top.BLK_MST[idx].u_axi4_master.busy_o = 1;

            repeat (50) @ (posedge tb_top.clk);

            //Burst tests
            saddr  = {{4'h9, idx[3:0]}, 24'h0} + 32'h100;  //align to 4-bytes boundary
            delay  = 0;
            random = 0;
            for (blen = 1; blen <= 16; blen = blen+1) begin
                tb_top.BLK_MST[idx].u_axi4_master.test_burst(saddr, blen, 2'b01, delay, random);
            end

            repeat (50) @ (posedge tb_top.clk);

            saddr  = {{4'h9, idx[3:0]}, 24'h0} + 32'h200;  //align to 4-bytes boundary
            delay  = 1;
            random = 1+idx;
            for (blen = 1; blen <= 16; blen = blen+1) begin
                random = random + 1;
                tb_top.BLK_MST[idx].u_axi4_master.test_burst(saddr, blen, 2'b01, delay, random);
            end

            repeat (50) @ (posedge tb_top.clk);

            //Finish stimulus
            tb_top.BLK_MST[idx].u_axi4_master.busy_o = 0;

            repeat (50) @(posedge tb_top.clk);

            while (tb_top.BLK_MST[idx].u_axi4_master.busy_i == 1'b1) @(posedge tb_top.clk);
        end
    end //for
    endgenerate

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

        $display("MST 0-3 to SLV 1-4 Test Finished!!!");
        $finish;
    end

    //dump waveform to vcd file
    initial
    begin
        $dumpfile("m4s4.vcd");
        $dumpvars(0, tc_m4s4);
        $dumpon;
        //$dumpoff;
    end

endmodule
