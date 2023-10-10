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
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-*/

`ifndef TB_EMAC_DEFINES
`define TB_EMAC_DEFINES


//`define VERBOSE                       // if log files of device modules are written

`define MULTICAST_XFR          0
`define UNICAST_XFR            1
`define BROADCAST_XFR          2
`define UNICAST_WRONG_XFR      3

`define ETH_BASE              32'hd0000000
`define ETH_WIDTH             32'h800
`define MEMORY_BASE           32'h2000
`define MEMORY_WIDTH          32'h10000
`define TX_BUF_BASE           `MEMORY_BASE
`define RX_BUF_BASE           `MEMORY_BASE + 32'h8000
`define TX_BD_BASE            `ETH_BASE + 32'h00000400
`define RX_BD_BASE            `ETH_BASE + 32'h00000600

/* Register space */
`define ETH_MODER      `ETH_BASE + 32'h00	/* Mode Register */
`define ETH_INT        `ETH_BASE + 32'h04	/* Interrupt Source Register */
`define ETH_INT_MASK   `ETH_BASE + 32'h08 /* Interrupt Mask Register */
`define ETH_IPGT       `ETH_BASE + 32'h0C /* Back to Bak Inter Packet Gap Register */
`define ETH_IPGR1      `ETH_BASE + 32'h10 /* Non Back to Back Inter Packet Gap Register 1 */
`define ETH_IPGR2      `ETH_BASE + 32'h14 /* Non Back to Back Inter Packet Gap Register 2 */
`define ETH_PACKETLEN  `ETH_BASE + 32'h18 /* Packet Length Register (min. and max.) */
`define ETH_COLLCONF   `ETH_BASE + 32'h1C /* Collision and Retry Configuration Register */
`define ETH_TX_BD_NUM  `ETH_BASE + 32'h20 /* Transmit Buffer Descriptor Number Register */
`define ETH_CTRLMODER  `ETH_BASE + 32'h24 /* Control Module Mode Register */
`define ETH_MIIMODER   `ETH_BASE + 32'h28 /* MII Mode Register */
`define ETH_MIICOMMAND `ETH_BASE + 32'h2C /* MII Command Register */
`define ETH_MIIADDRESS `ETH_BASE + 32'h30 /* MII Address Register */
`define ETH_MIITX_DATA `ETH_BASE + 32'h34 /* MII Transmit Data Register */
`define ETH_MIIRX_DATA `ETH_BASE + 32'h38 /* MII Receive Data Register */
`define ETH_MIISTATUS  `ETH_BASE + 32'h3C /* MII Status Register */
`define ETH_MAC_ADDR0  `ETH_BASE + 32'h40 /* MAC Individual Address Register 0 */
`define ETH_MAC_ADDR1  `ETH_BASE + 32'h44 /* MAC Individual Address Register 1 */
`define ETH_HASH_ADDR0 `ETH_BASE + 32'h48 /* Hash Register 0 */
`define ETH_HASH_ADDR1 `ETH_BASE + 32'h4C /* Hash Register 1 */
`define ETH_TX_CTRL    `ETH_BASE + 32'h50 /* Tx Control Register */

/* MODER Register */
`define ETH_MODER_RXEN     32'h00000001 /* Receive Enable  */
`define ETH_MODER_TXEN     32'h00000002 /* Transmit Enable */
`define ETH_MODER_NOPRE    32'h00000004 /* No Preamble  */
`define ETH_MODER_BRO      32'h00000008 /* Reject Broadcast */
`define ETH_MODER_IAM      32'h00000010 /* Use Individual Hash */
`define ETH_MODER_PRO      32'h00000020 /* Promiscuous (receive all) */
`define ETH_MODER_IFG      32'h00000040 /* Min. IFG not required */
`define ETH_MODER_LOOPBCK  32'h00000080 /* Loop Back */
`define ETH_MODER_NOBCKOF  32'h00000100 /* No Backoff */
`define ETH_MODER_EXDFREN  32'h00000200 /* Excess Defer */
`define ETH_MODER_FULLD    32'h00000400 /* Full Duplex */
`define ETH_MODER_RST      32'h00000800 /* Reset MAC */
`define ETH_MODER_DLYCRCEN 32'h00001000 /* Delayed CRC Enable */
`define ETH_MODER_CRCEN    32'h00002000 /* CRC Enable */
`define ETH_MODER_HUGEN    32'h00004000 /* Huge Enable */
`define ETH_MODER_PAD      32'h00008000 /* Pad Enable */
`define ETH_MODER_RECSMALL 32'h00010000 /* Receive Small */

/* Interrupt Source Register */
`define ETH_INT_TXB        32'h00000001 /* Transmit Buffer IRQ */
`define ETH_INT_TXE        32'h00000002 /* Transmit Error IRQ */
`define ETH_INT_RXB        32'h00000004 /* Receive Buffer IRQ */
`define ETH_INT_RXE        32'h00000008 /* Receive Error IRQ */
`define ETH_INT_BUSY       32'h00000010 /* Busy IRQ */
`define ETH_INT_TXC        32'h00000020 /* Transmit Control Frame IRQ */
`define ETH_INT_RXC        32'h00000040 /* Received Control Frame IRQ */

/* Interrupt Mask Register */
`define ETH_INT_MASK_TXB   32'h00000001 /* Transmit Buffer IRQ Mask */
`define ETH_INT_MASK_TXE   32'h00000002 /* Transmit Error IRQ Mask */
`define ETH_INT_MASK_RXF   32'h00000004 /* Receive Frame IRQ Mask */
`define ETH_INT_MASK_RXE   32'h00000008 /* Receive Error IRQ Mask */
`define ETH_INT_MASK_BUSY  32'h00000010 /* Busy IRQ Mask */
`define ETH_INT_MASK_TXC   32'h00000020 /* Transmit Control Frame IRQ Mask */
`define ETH_INT_MASK_RXC   32'h00000040 /* Received Control Frame IRQ Mask */

/* Control Module Mode Register */
`define ETH_CTRLMODER_PASSALL 32'h00000001 /* Pass Control Frames */
`define ETH_CTRLMODER_RXFLOW  32'h00000002 /* Receive Control Flow Enable */
`define ETH_CTRLMODER_TXFLOW  32'h00000004 /* Transmit Control Flow Enable */

/* MII Mode Register */
`define ETH_MIIMODER_CLKDIV   32'h000000FF /* Clock Divider */
`define ETH_MIIMODER_NOPRE    32'h00000100 /* No Preamble */
`define ETH_MIIMODER_RST      32'h00000200 /* MIIM Reset */

/* MII Command Register */
`define ETH_MIICOMMAND_SCANSTAT  32'h00000001 /* Scan Status */
`define ETH_MIICOMMAND_RSTAT     32'h00000002 /* Read Status */
`define ETH_MIICOMMAND_WCTRLDATA 32'h00000004 /* Write Control Data */

/* MII Address Register */
`define ETH_MIIADDRESS_FIAD 32'h0000001F /* PHY Address */
`define ETH_MIIADDRESS_RGAD 32'h00001F00 /* RGAD Address */

/* MII Status Register */
`define ETH_MIISTATUS_LINKFAIL    0 /* Link Fail bit */
`define ETH_MIISTATUS_BUSY        1 /* MII Busy bit */
`define ETH_MIISTATUS_NVALID      2 /* Data in MII Status Register is invalid bit */

/* TX Control Register */
`define ETH_TX_CTRL_TXPAUSERQ     32'h10000 /* Send PAUSE request */


`define TIME $display("  Time: %0t", $time)

`endif //TB_EMAC_DEFINES
