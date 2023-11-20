/*+
 * Copyright (c) 2022-2023 Zhengde
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

`ifndef EMAC_DEFINES
`define EMAC_DEFINES

`define EMAC_BLK_ADR           (24'h00_0003)    //EMAC block address

`define EMAC_CONFIG_ADR        (8'h00)       //EMAC configuration {LoopEn, speed[2:0]}
`define EMAC_INT_SOURCE_ADR    (8'h04)       //EMAC Interrupt source register
`define EMAC_INT_MASK_ADR      (8'h08)       //EMAC Interrupt mask register

`define EMAC_MDIOMODE_ADR      (8'h30)       //MDIO mode {23'h0, MiiNoPre, ClkDiv[7:0]}
`define EMAC_MDIOCOMMAND_ADR   (8'h34)       //MDIO command {29'h0, WCtrlData, RStat, ScanStat}
`define EMAC_MDIOADDRESS_ADR   (8'h38)       //MDIO address {19'h0, RGAD[4:0], 3'b0, FIAD[4:0]}
`define EMAC_MDIOTX_DATA_ADR   (8'h3c)       //MDIO transmit data {16'h0, CtrlData[15:0]}
`define EMAC_MDIORX_DATA_ADR   (8'h40)       //MDIO receive data {16'h0, Prsd[15:0]}
`define EMAC_MDIOSTATUS_ADR    (8'h44)       //MDIO status {29'b0, NValid_stat, Busy_stat, LinkFail}

`define EMAC_TXFF_AWIDTH       (9)           //TX FIFO address width
`define EMAC_RXFF_AWIDTH       (9)           //RX FIFO address width

`timescale 1ns / 1ns
`endif
