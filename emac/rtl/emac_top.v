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
    input               sys_rst_n,               //async. reset, active low
    input               clk_125m ,
    input               clk_user ,
    output [2:0]        speed_o  ,

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
    output [31:0]       rx_mac_data_o   ,
    output [1:0]        rx_mac_be_o     ,
    output              rx_mac_pa_o     ,
    output              rx_mac_sop_o    ,
    output              rx_mac_eop_o    ,

    //TX FIFO user interface 
    output              tx_mac_wa_o     ,
    input               tx_mac_wr_i     ,
    input  [31:0]       tx_mac_data_i   ,
    input  [1:0]        tx_mac_be_i     ,
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
    //miim related signals
    wire  [7:0]     r_ClkDiv;
    wire            r_MiiNoPre;
    wire  [15:0]    r_CtrlData;
    wire  [4:0]     r_FIAD;
    wire  [4:0]     r_RGAD;
    wire            r_WCtrlData;
    wire            r_RStat;
    wire            r_ScanStat;
    wire            NValid_stat;
    wire            Busy_stat;
    wire            LinkFail;
    wire  [15:0]    Prsd;             // Read Status Data (data read from the PHY)
    wire            WCtrlDataStart;
    wire            RStatStart;
    wire            UpdateMIIRX_DATAReg;

    //signals for connections
    wire  [2:0]     r_speed;
    wire            r_line_loop_en;
    wire            mac_tx_clk    ;
    wire            mac_rx_clk    ;
    wire            mac_tx_clk_div;
    wire            mac_rx_clk_div; 
    //RX interface from PHY to MAC core
    wire            MRxDv  ;       
    wire  [7:0]     MRxD   ;       
    wire            MRxErr ;       
    wire            MCRS   ;
    //TX interface from MAC core to PHY
    wire  [7:0]      MTxD  ;
    wire             MTxEn ;   
    wire             MTxErr;

    // Connecting EMAC clock control module
    emac_clk_ctrl u_clk_ctrl
    (   
        .rst_n                 (sys_rst_n),
        .clk_125m              (clk_125m ),
    
        //registers interface
        .speed_i               (r_speed),       
    
        //clock signals between PHY/MAC interface
        .gtx_clk               (gtx_clk),
        .rx_clk                (rx_clk ),
        .tx_clk                (tx_clk ),
    
        //internal clock signals for TX/RX data processing
        .mac_tx_clk            (mac_tx_clk    ),
        .mac_rx_clk            (mac_rx_clk    ),
        .mac_tx_clk_div        (mac_tx_clk_div),
        .mac_rx_clk_div        (mac_rx_clk_div)  
    );

    emac_phy_intf u_phy_intf (
        .rst_n                 (sys_rst_n ),
        .mac_rx_clk            (mac_rx_clk),
        .mac_tx_clk            (mac_tx_clk),
        //RX interface to MAC core
        .MRxDv_o               (MRxDv ),       
        .MRxD_o                (MRxD  ),       
        .MRxErr_o              (MRxErr),       
        .MCRS_o                (MCRS  ),
        //TX interface from MAC core
        .MTxD_i                (MTxD  ),
        .MTxEn_i               (MTxEn ),   
        .MTxErr_i              (MTxErr),
        //PHY interface
        .tx_er_o               (tx_er_o),
        .tx_en_o               (tx_en_o),
        .txd_o                 (txd_o  ),
        .rx_er_i               (rx_er_i),
        .rx_dv_i               (rx_dv_i),
        .rxd_i                 (rxd_i  ),
        .crs_i                 (crs_i  ),
        .col_i                 (col_i  ),
        //registers interface
        .line_loop_en_i        (r_line_loop_en),
        .speed_i               (r_speed       ) 
    );

    // Connecting miim module
    eth_miim u_eth_miim
    (
        .Clk                   (bus2ip_clk),
        .rst_n                 (bus2ip_rst_n),

        .Mdi_i                 (mdi_i),
        .Mdo_o                 (mdo_o),
        .MdoEn_o               (mdo_en_o),
        .Mdc_o                 (mdc_o),

        .Divider_i             (r_ClkDiv),
        .NoPre_i               (r_MiiNoPre),
        .CtrlData_i            (r_CtrlData),
        .Rgad_i                (r_RGAD),
        .Fiad_i                (r_FIAD),
        .WCtrlData_i           (r_WCtrlData),
        .RStat_i               (r_RStat),
        .ScanStat_i            (r_ScanStat),
        .Busy_o                (Busy_stat),
        .Prsd_o                (Prsd),
        .LinkFail_o            (LinkFail),
        .Nvalid_o              (NValid_stat),
        .WCtrlDataStart_o      (WCtrlDataStart),
        .RStatStart_o          (RStatStart),
        .UpdateMIIRX_DATAReg_o (UpdateMIIRX_DATAReg)
    );

    // Connecting Ethernet registers
    emac_registers u_emac_registers
    (
        .bus2ip_clk            (bus2ip_clk    ),         
        .bus2ip_rst_n          (bus2ip_rst_n  ),
        .bus2ip_addr_i         (bus2ip_addr_i ),
        .bus2ip_data_i         (bus2ip_data_i ),
        .bus2ip_rd_ce_i        (bus2ip_rd_ce_i),         
        .bus2ip_wr_ce_i        (bus2ip_wr_ce_i),        
        .ip2bus_data_o         (ip2bus_data_o ), 

        //EMAC control and status registers
        .r_speed_o             (r_speed       ),
        .r_line_loop_en_o      (r_line_loop_en),

        // EMAC MIIM registers
        .r_ClkDiv_o            (r_ClkDiv),
        .r_MiiNoPre_o          (r_MiiNoPre),
        .r_CtrlData_o          (r_CtrlData),
        .r_RGAD_o              (r_RGAD),
        .r_FIAD_o              (r_FIAD),
        .r_WCtrlData_o         (r_WCtrlData),
        .r_RStat_o             (r_RStat),
        .r_ScanStat_o          (r_ScanStat),
        .Busy_stat_i           (Busy_stat),
        .Prsd_i                (Prsd),
        .LinkFail_i            (LinkFail),
        .NValid_stat_i         (NValid_stat),
        .WCtrlDataStart_i      (WCtrlDataStart),
        .RStatStart_i          (RStatStart),
        .UpdateMIIRX_DATAReg_i (UpdateMIIRX_DATAReg)
    );
    assign speed_o = r_speed;

endmodule
