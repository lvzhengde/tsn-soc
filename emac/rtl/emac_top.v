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
 * Ethernet MAC RTL top level
-*/

`include "emac_defines.v"

module emac_top (
    //System signals
    input               sys_rst_n,              //async. reset, active low
    input               clk_125m ,
    input               clk_user ,
    output              speed_o  ,

    //32 bits on chip host bus access interface
    input               bus2ip_clk     ,         //clock used for register access and mdio
    input               bus2ip_rst_n   ,
    input  [31:0]       bus2ip_addr_i  ,
    input  [31:0]       bus2ip_data_i  ,
    input               bus2ip_rd_ce_i ,         //active high
    input               bus2ip_wr_ce_i ,         //active high
    output [31:0]       ip2bus_data_o  , 

    //RX FIFO user interface
    output              rx_mac_ra_o     ,
    input               rx_mac_rd_i     ,
    output  [31:0]      rx_mac_data_o   ,
    output  [1:0]       rx_mac_be_o     ,
    output              rx_mac_pa_o     ,
    output              rx_mac_sop_o    ,
    output              rx_mac_eop_o    ,

    //TX FIFO user interface 
    output              tx_mac_wa_o     ,
    input               tx_mac_wr_i     ,
    input   [31:0]      tx_mac_data_i   ,
    input   [1:0]       tx_mac_be_i     ,
    input               tx_mac_sop_i    ,
    input               tx_mac_eop_i    ,

    //PHY GMII/MII rx interface
    input               rx_clk ,
    input               rx_dv_i, 
    input               rx_er_i, 
    input  [7:0]        rxd_i  , 
    input               crs_i  ,                //carrier sense from PHY
    input               col_i  ,                //collision from PHY
      
    //PHY GMII/MII tx interface
    output              gtx_clk,                //used only in GMII mode, from MAC to PHY
    input               tx_clk ,                //used only in MII mode, from PHY to MAc
    output              tx_en_o,
    output              tx_er_o,
    output [7:0]        txd_o  ,

    //PHY mdio interface
    output              mdc_o     ,              //mdio clock
    output              mdo_en_o  ,              //mdio output enable
    output              mdo_o     ,              //mdio serial data output
    input               mdi_i                    //mdio serial data input
);



endmodule
