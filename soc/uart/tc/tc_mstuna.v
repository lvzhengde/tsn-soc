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
 *  Description : test case for uart axi master, 
 *                unaligned address access.
 *  File        : tc_mstuna.v
-*/

module tc_mstuna;

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

        $display("\n", $time,, "Test for Write/Read Multiple Bytes and Unaligned Address...");
        //write multiple 32-bit words to AXI memory
        #200;
        addr   = 32'h102;
        len    = 7*4 + 1;
        $display($time,, "addr = 0x%08x, len = %02d", addr, len);
        random = 11;
        tb_top.uart_host.write_mem(addr, len, random);

        //read multiple 32-bit words from AXI memory 
        tb_top.uart_host.read_mem(addr, len);
        #200;

        //scoreboard
        for (idx = 0; idx < len; idx = idx+4) begin
            tx_data = tb_top.uart_host.wr_buffer[idx/4];
            rx_data = tb_top.uart_host.rd_buffer[idx/4];
            if ((len-idx) < 4) begin
                case (len-idx)
                    1:
                    begin
                        tx_data = tx_data & 'hff;
                        rx_data = rx_data & 'hff;
                    end
                    2:
                    begin
                        tx_data = tx_data & 'hff_ff;
                        rx_data = rx_data & 'hff_ff;
                    end
                    3:
                    begin
                        tx_data = tx_data & 'hff_ff_ff;
                        rx_data = rx_data & 'hff_ff_ff;
                    end
                    default
                        ;
                endcase
            end

            $display("idx = %03d, transmitted data = %08x, received data = %08x", idx/4, tx_data, rx_data);

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
        $dumpfile("mstuna.fst");
        $dumpvars(0, tc_mstuna);
        $dumpon;
        //$dumpoff;
    end
 
endmodule


