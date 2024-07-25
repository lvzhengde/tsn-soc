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
 *  Description : test case for uart axi master 
 *  File        : tc_aximst.v
-*/

module tc_aximst;

    tb_top tb_top();

    reg  [31:0]  addr;
    reg  [ 7:0]  len;
    integer      random;
    integer      idx;

    reg  [31:0]  tx_data;
    reg  [31:0]  rx_data;
    
    initial begin
        tb_top.uart_mst = 1'b1; //configured as AXI master
        addr   = 0;
        len    = 0;
        random = 0;
    
        #10;
        $display($time,, "UART Device Configured As AXI Master, Simulation Start!");

        fork
            begin
                $display($time,, "Reset UART device.");
                tb_top.uart_device.reset;
            end
            begin
                $display($time,, "Reset UART host.");
                tb_top.uart_host.reset;
            end
        join

        $display("\n", $time,, "Test for Write/Read one 32-bit Word...");
        //write one 32-bit word to AXI memory
        #200;
        addr   = 32'h50;
        len    = 4;
        random = 11;
        tb_top.uart_host.write_mem(addr, len, random);

        //read one 32-bit word from AXI memory at the same address
        tb_top.uart_host.read_mem(addr, len);
        #200;

        //scoreboard
        tx_data = tb_top.uart_host.wr_buffer[0];
        rx_data = tb_top.uart_host.rd_buffer[0];
        $display("transmitted data = %08x, received data = %08x", tx_data, rx_data);

        if (tx_data != rx_data) begin
            $display("ERROR: received data not equal to transmitted data!");
            $finish(2);
        end


        $display("\n", $time,, "Test for Write/Read Multiple 32-bit Words...");
        //write multiple 32-bit words to AXI memory
        #200;
        addr   = 32'h100;
        len    = 19*4;
        random = 11;
        tb_top.uart_host.write_mem(addr, len, random);

        //read multiple 32-bit words from AXI memory 
        tb_top.uart_host.read_mem(addr, len);
        #200;

        //scoreboard
        for (idx = 0; idx < (len/4); idx = idx+1) begin
            tx_data = tb_top.uart_host.wr_buffer[idx];
            rx_data = tb_top.uart_host.rd_buffer[idx];
            $display("idx = %03d, transmitted data = %08x, received data = %08x", idx, tx_data, rx_data);

            if (rx_data != tx_data) begin
                $display("ERROR: received data not equal to transmitted data!");
                $finish(2);
            end
        end

        #500;
        $display("SIMULATION PASS!!!");
        $finish;
    end
    
    initial
    begin
        $dumpfile("aximst.fst");
        $dumpvars(0, tc_aximst);
        $dumpon;
        //$dumpoff;
    end
 
endmodule

