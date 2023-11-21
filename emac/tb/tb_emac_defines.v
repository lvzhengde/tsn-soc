/*+
 * Copyright (c) 2022-2023 Zhengde
 *
 * Copyright (c) 2002 Tadej Markovic, tadej@opencores.org 
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
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHEMACER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-*/

`ifndef TB_EMAC_DEFINES
`define TB_EMAC_DEFINES


`define MULTICAST_XFR          0
`define UNICAST_XFR            1
`define BROADCAST_XFR          2
`define UNICAST_WRONG_XFR      3

//++
//Note:
//for simulation correctly 
//If the address in file emac_defines.v changed, the corresponding address in
//file tb_emac_defines.v should be changed also.
//--

`define EMAC_BASE              (32'h0000_0300)

/* Register space */
`define EMAC_CONFIG      `EMAC_BASE + 32'h00 /* EMAC configuration  */
`define EMAC_INT_SOURCE  `EMAC_BASE + 32'h04 /* EMAC Interrupt source register  */
`define EMAC_INT_MASK    `EMAC_BASE + 32'h08 /* EMAC Interrupt mask register  */

`define EMAC_MDIOMODE    `EMAC_BASE + 32'h90 /* MDIO Mode Register */
`define EMAC_MDIOCOMMAND `EMAC_BASE + 32'h94 /* MDIO Command Register */
`define EMAC_MDIOADDRESS `EMAC_BASE + 32'h98 /* MDIO Address Register */
`define EMAC_MDIOTX_DATA `EMAC_BASE + 32'h9C /* MDIO Transmit Data Register */
`define EMAC_MDIORX_DATA `EMAC_BASE + 32'ha0 /* MDIO Receive Data Register */
`define EMAC_MDIOSTATUS  `EMAC_BASE + 32'ha4 /* MDIO Status Register */

/* MDIO Mode Register */
`define EMAC_MDIOMODE_CLKDIV   32'h000000FF /* Clock Divider */
`define EMAC_MDIOMODE_NOPRE    32'h00000100 /* No Preamble */
`define EMAC_MDIOMODE_RST      32'h00000200 /* MIIM Reset */

/* MDIO Command Register */
`define EMAC_MDIOCOMMAND_SCANSTAT  32'h00000001 /* Scan Status */
`define EMAC_MDIOCOMMAND_RSTAT     32'h00000002 /* Read Status */
`define EMAC_MDIOCOMMAND_WCTRLDATA 32'h00000004 /* Write Control Data */

/* MDIO Address Register */
`define EMAC_MDIOADDRESS_FIAD 32'h0000001F /* PHY Address */
`define EMAC_MDIOADDRESS_RGAD 32'h00001F00 /* RGAD Address */

/* MDIO Status Register */
`define EMAC_MDIOSTATUS_LINKFAIL    0 /* Link Fail bit */
`define EMAC_MDIOSTATUS_BUSY        1 /* MDIO Busy bit */
`define EMAC_MDIOSTATUS_NVALID      2 /* Data in MDIO Status Register is invalid bit */

/*Ethernet Speed */
`define EMAC_SPEED                  3'b100 //3'b100: 1000Mbps, 3'b010: 100Mbps, 3'b001: 10Mbps

`define TIME $display("  Time: %0t", $time)

`endif //TB_EMAC_DEFINES
