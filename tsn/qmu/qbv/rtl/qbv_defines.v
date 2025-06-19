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

`ifndef QBV_DEFINES
`define QBV_DEFINES

// Base address for QBV control/status registers
`define QBV_REG_BASEADDR             (32'ha1000000)
`define QBV_ADDR_MASK                (32'hffff0000)

// Register offsets
`define QBV_CFG       (8'h00)  // QBV Configuration Register
`define QBV_STATE     (8'h08)  // QBV State Register
`define QBV_ACTD      (8'h18)  // QBV Admin Cycle Time Denominator Register
`define QBV_ACTE      (8'h1C)  // QBV Admin Cycle Time Extension Register
`define QBV_ABTN      (8'h20)  // QBV Admin Base Time Nano-second Register
`define QBV_ABTSL     (8'h24)  // QBV Admin Base Time Second LSB Register
`define QBV_ABTSH     (8'h28)  // QBV Admin Base Time Second MSB Register
`define QBV_ISR       (8'h30)  // QBV Interrupt Status Register
`define QBV_IER       (8'h34)  // QBV Interrupt Enable Register
`define QBV_ICR       (8'h38)  // QBV Interrupt Clear Register
`define QBV_STATUS    (8'h3C)  // QBV Status Register
`define QBV_CCTN      (8'h40)  // QBV Config Change Time Nano-second Register
`define QBV_CCTSL     (8'h44)  // QBV Config Change Time Second LSB Register
`define QBV_CCTSH     (8'h48)  // QBV Config Change Time Second MSB Register
`define QBV_OCTD      (8'h58)  // QBV Operative Cycle Time Denominator Register
`define QBV_OCTE      (8'h5C)  // QBV Operative Cycle Time Extension Register
`define QBV_OBTN      (8'h60)  // QBV Operative Base Time Nano-second Register
`define QBV_OBTSL     (8'h64)  // QBV Operative Base Time Second LSB Register
`define QBV_OBTSH     (8'h68)  // QBV Operative Base Time Second MSB Register
`define QBV_BETC      (8'h6C)  // QBV BE Transmission Overrun Count Register
`define QBV_RSTC      (8'h70)  // QBV RES Transmission Overrun Count Register
`define QBV_STTC      (8'h74)  // QBV ST Transmission Overrun Count Register

`define QBV_ACLE_BASE (8'h1000)  // QBV Admin Control List Entry Base Address (dual port ram)
`define QBV_OCLE_BASE (8'h2000)  // QBV Operative Control List Entry Base Address (dual port ram)

// Default values
`define QBV_CFG_DEFAULT            (32'h00000001)
`define QBV_STATE_DEFAULT          (32'h00000000)
`define QBV_ACTD_DEFAULT           (32'h00000000)
`define QBV_ACTE_DEFAULT           (32'h00000000)
`define QBV_IER_DEFAULT            (32'h00000000)

`endif
