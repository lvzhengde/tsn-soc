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

/*+
 * Ethernet MAC user interface agent including driver and monitor
-*/

`include "emac_defines.v"
`include "ephy_defines.v"
`include "tb_emac_defines.v"

module emac_user_agent (
    input               rst_n           ,
    input               clk_user        ,
    input               init_end_i      ,

    //RX FIFO user interface
    input               rx_mac_ra_i     , //RX FIFO read data available
    output              rx_mac_rd_o     , //RX FIFO read enable
    input  [31:0]       rx_mac_data_i   , //Read data output, aligned with rx_mac_pa_o
    input  [1:0]        rx_mac_be_i     , //Byte enable for the last word, little endian
    input               rx_mac_pa_i     , //packet data valid
    input               rx_mac_sop_i    , //start of packet
    input               rx_mac_eop_i    , //end of packet

    //TX FIFO user interface 
    input               tx_mac_wa_i     , //FIFO write data available
    output              tx_mac_wr_o     , //MAC data write enable
    output [31:0]       tx_mac_data_o   , //MAC data input
    output [1:0]        tx_mac_be_o     , //byte enable, little endian
    output              tx_mac_sop_o    , //Start of Packet input
    output              tx_mac_eop_o      //End of Packet input
);
`include "emac_utils.v"

endmodule
