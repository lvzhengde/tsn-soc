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
 *  Description : test case for uart axi slave, host transmit / device receive
 *  File        : tc_slvh2d.v
-*/

module tc_slvh2d;

    tb_top tb_top();

    integer  tx_len;
    integer  rx_len;
    integer  random;
    integer  idx;

    reg  [ 7:0] tx_data;
    reg  [ 7:0] rx_data;
    
    initial begin
        tb_top.uart_mst = 0; //configured as AXI slave
        tx_len = 0;
        rx_len = 0;
        random = 0;
    
        #10;
        $display($time,, "UART Configured As AXI Slave, Simulation Start!");

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

        //Host transmit
        fork
            begin
                tx_len = 17;
                random = 5;
                $display($time,, "Host transmit data to UART..., tx_len = %d, rand seed = %d", tx_len, random);
                tb_top.uart_host.test_transmit(tx_len, random);
                #200;
                tb_top.uart_device.rx_terminate = tb_top.uart_host.tx_done;
            end

            //Device receive
            begin
                #100;
                $display($time,, "Device receive data from UART...");
                tb_top.uart_device.axi_uart_receive(rx_len);
            end
        join

        //Scoreboard
        if (rx_len != tx_len) begin
            $display("ERROR: rx_len = %d, not equal to tx_len = %d", rx_len, tx_len);
            $finish(2);
        end
        else begin
            for (idx = 0; idx < tx_len; idx = idx+1) begin
                tx_data = tb_top.uart_host.wr_buffer[idx][7:0];
                rx_data = tb_top.uart_device.rd_buffer[idx][7:0];
                $display("idx = %d, transmitted data = %x, received data = %x", idx, tx_data, rx_data);

                if (rx_data != tx_data) begin
                    $display("ERROR: received data not equal to transmitted data!");
                    $finish(2);
                end
            end
        end

        #5000;
        $display("SIMULATION PASS!!!");
        $finish;
    end
    
    initial
    begin
        $dumpfile("slvh2d.fst");
        $dumpvars(0, tc_slvh2d);
        $dumpon;
        //$dumpoff;
    end
 
endmodule
