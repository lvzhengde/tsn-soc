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

`ifndef SPI_DEFINES
`define SPI_DEFINES


`define SPI_FLASH_BASEADDR           (32'h91000000)    //Base address for SPI flash memory in XIP mode
`define SPI_REG_BASEADDR             (32'h91800000)    //Base address for SPI control/status registers
`define SPI_ADDR_MASK                (32'hff800000)

`define SPI_DGIER    (8'h1c)  //Device Global Interrupt Enable Register {gie, 31'b0}
`define SPI_IPISR    (8'h20)  //IP Interrupt Status Register {27'b0, rx_full, 1'b0, tx_empty, 2'b0}
`define SPI_IPIER    (8'h28)  //IP Interrupt Enable Register {27'b0, rx_full, 1'b0, tx_empty, 2'b0}

`define SPI_SRR      (8'h40)  //Software Reset Register {write 32'h0000_000a to reset}
`define SPI_CR       (8'h60)  //SPI Control Register {22'b0, lsb_first, inhibit, msse, rxfifo_rst, txfifo_rst, cpha, cpol, master, spe, loop}
`define SPI_SR       (8'h64)  //SPI Status Register {28'b0, tx_full, tx_empty, rx_full, rx_empty}
`define SPI_DTR      (8'h68)  //SPI Data Transmit Register (A single register or a FIFO) {24'b0, tx_data[7:0]}
`define SPI_DRR      (8'h6c)  //SPI Data Receive Register (A single register or a FIFO)  {24'b0, rx_data[7:0]}
`define SPI_SSR      (8'h70)  //SPI Slave Select Register {31'b0, ss}


`endif

