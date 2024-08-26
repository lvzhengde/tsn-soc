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

`ifndef TB_SPI_DEFINES
`define TB_SPI_DEFINES

`define NORD         (8'h03)  //Normal Read Mode
`define NORD4        (8'h13)  //4-byte Address Normal Read Mode
`define FRD          (8'h0B)  //Fast Read Mode
`define FRD4         (8'h0C)  //4-byte Address Fast Read Mode
`define PP           (8'h02)  //Serial Input Page Program
`define PP4          (8'h12)  //4-byte Address Serial Input Page Program
`define SER          (8'h20)  //Sector Erase
`define SER4         (8'h21)  //4-byte Address Sector Erase
`define CER          (8'h60)  //Chip Erase
`define WREN         (8'h06)  //Write Enable
`define WRDI         (8'h04)  //Write Disable
`define RDSR         (8'h05)  //Read Status Register
`define WRSR         (8'h01)  //Write Status Register
`define RDFR         (8'h48)  //Read Function Register
`define WRFR         (8'h42)  //Write Function Register
`define SRPNV        (8'h65)  //Set Read Parameters (Non-Volatile)
`define SRPV         (8'h63)  //Set Read Parameters (Volatile)
`define SERPNV       (8'h85)  //Set Extended Read Parameters (Non-Volatile)
`define SERPV        (8'h83)  //Set Extended Read Parameters (Volatile)
`define RDRP         (8'h61)  //Read Read Parameters (Volatile)
`define RDERP        (8'h81)  //Read Extended Read Parameters (Volatile)
`define CLERP        (8'h82)  //Clear Extended Read Register
`define RDBR         (8'h16)  //Read Bank Address Register (Volatile)
`define WRBRV        (8'h17)  //Write Bank Address Register (Volatile)
`define WRBRNV       (8'h18)  //Write Bank Address Register (Non-Volatile)
`define EN4B         (8'hB7)  //Enter 4-byte Address Mode
`define EX4B         (8'h29)  //Exit 4-byte Address Mode


`endif


