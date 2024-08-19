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

`ifndef UART_DEFINES
`define UART_DEFINES


`define UART_BASEADDR                 (32'h91000000)    //Base address for UART registers
`define UART_ADDR_MASK                (32'hffffff00)

`define UART_BAUD      (8'h00)  //Baud Rate Configuration Register {16'b0, baud_config[15:0]}
`define UART_CONTROL   (8'h04)  //UART Control Register {29'b0, parity_en, msb_first, start_polarity}
`define UART_STATUS    (8'h08)  //UART Status Register {23'b0, rx_buffer_data_present, rx_buffer_full, rx_buffer_hfull,
                                // rx_buffer_afull, rx_buffer_aempty, tx_buffer_full, 
                                // tx_buffer_hfull, tx_buffer_afull, tx_buffer_aempty}
`define UART_TXDATA    (8'h0c)  //AXI Slave Transmit Data (to UART TX FIFO) register {24'h0, slv_wdata[7:0]}
`define UART_RXDATA    (8'h10)  //UART RX Data (with status info, to AXI Slave) Register {19'h0, rx_buffer_data_present, 
                                // rx_buffer_full, rx_buffer_hfull, rx_buffer_afull, rx_buffer_aempty, slv_rdata_i[7:0]}
`define UART_RSTCPU    (8'h14)  //UART Reset CPU register (in AXI Master Mode) {30'h0, uart_mst, reset_cpu};
`define UART_RSTBUF    (8'h20)  //UART Reset RX/TX Buffer Register {31'h0, reset_buffer}

`define UART_IER       (8'h24)  //UART Interrupt Enable Register {30'b0, tx_empty, rx_present}
`define UART_ISR       (8'h28)  //UART Interrupt Status Register (write 1 to clear) {30'b0, tx_empty, rx_present}

`endif


