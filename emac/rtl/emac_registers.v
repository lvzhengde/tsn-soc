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
 * Ethernet MAC registers for CPU/SW
-*/

`include "emac_defines.v"

module emac_registers (
    //32 bits on chip host bus access interface
    input               bus2ip_clk     ,         //clock 
    input               bus2ip_rst_n   ,         //active low reset
    input  [31:0]       bus2ip_addr_i  ,
    input  [31:0]       bus2ip_data_i  ,
    input               bus2ip_rd_ce_i ,         //active high
    input               bus2ip_wr_ce_i ,         //active high
    output reg [31:0]   ip2bus_data_o  , 

    //EMAC control and status registers
    output [2:0]        r_speed_o            ,
    output              r_LoopEn_o           ,

    //EMAC MIIM registers
    output [7:0]        r_ClkDiv_o           , 
    output              r_MiiNoPre_o         , 
    output [15:0]       r_CtrlData_o         , 
    output [4:0]        r_RGAD_o             , 
    output [4:0]        r_FIAD_o             , 
    output              r_WCtrlData_o        , 
    output              r_RStat_o            , 
    output              r_ScanStat_o         , 
    input               Busy_stat_i          , 
    input  [15:0]       Prsd_i               , 
    input               LinkFail_i           , 
    input               NValid_stat_i        , 
    input               WCtrlDataStart_i     , 
    input               RStatStart_i         , 
    input               UpdateMIIRX_DATAReg_i 
);
    parameter BLK_ADDR = `EMAC_BLK_ADR;

    wire  emac_blk_sel = (bus2ip_addr_i[31:8] == BLK_ADDR);

    //++
    //instantiate emac registers
    //--

    //EMAC configuration
    wire emac_config_wr = emac_blk_sel & bus2ip_wr_ce_i & (bus2ip_addr_i[7:0] == `EMAC_CONFIG_ADR);
    wire [31:0] emac_config;
    eth_register #(32, 0) u_emac_config
    (
        .clk            (bus2ip_clk),
        .rst_n          (bus2ip_rst_n),  
    
        .sync_reset_i   (1'b0), 
        .write_en_i     (emac_config_wr), 
        .data_i         (bus2ip_data_i[31:0]),
        .data_o         (emac_config[31:0]) 
    );
    assign r_speed_o  = emac_config[2:0];  
    assign r_LoopEn_o = emac_config[3]  ; 
    
    //MDIO MODE register
    wire mdio_mode_wr = emac_blk_sel & bus2ip_wr_ce_i & (bus2ip_addr_i[7:0] == `EMAC_MDIOMODE_ADR);
    wire [31:0] mdio_mode;

    eth_register #(8, 8'h64) u_mdio_mode_0
    (
        .clk            (bus2ip_clk),
        .rst_n          (bus2ip_rst_n),  
    
        .sync_reset_i   (1'b0), 
        .write_en_i     (mdio_mode_wr), 
        .data_i         (bus2ip_data_i[7:0]),
        .data_o         (mdio_mode[7:0]) 
    );
    assign r_ClkDiv_o   = mdio_mode[7:0];

    eth_register #(1, 0) u_mdio_mode_1
    (
        .clk            (bus2ip_clk),
        .rst_n          (bus2ip_rst_n),  
    
        .sync_reset_i   (1'b0), 
        .write_en_i     (mdio_mode_wr), 
        .data_i         (bus2ip_data_i[8]),
        .data_o         (mdio_mode[8]) 
    );
    assign r_MiiNoPre_o = mdio_mode[8];

    assign mdio_mode[31:9] = 0;
    
    //MDIO Command register
    wire mdio_command_wr = emac_blk_sel & bus2ip_wr_ce_i & (bus2ip_addr_i[7:0] == `EMAC_MDIOCOMMAND_ADR);
    wire [31:0] mdio_command;

    eth_register #(1, 0) u_mdio_command_0
    (
        .clk            (bus2ip_clk),
        .rst_n          (bus2ip_rst_n),  
    
        .sync_reset_i   (1'b0), 
        .write_en_i     (mdio_command_wr), 
        .data_i         (bus2ip_data_i[0]),
        .data_o         (mdio_command[0]) 
    );
    assign r_ScanStat_o = mdio_command[0];

    eth_register #(1, 0) u_mdio_command_1
    (
        .clk            (bus2ip_clk),
        .rst_n          (bus2ip_rst_n),  
    
        .sync_reset_i   (RStatStart_i), 
        .write_en_i     (mdio_command_wr), 
        .data_i         (bus2ip_data_i[1]),
        .data_o         (mdio_command[1]) 
    );
    assign r_RStat_o = mdio_command[1];

    eth_register #(1, 0) u_mdio_command_2
    (
        .clk            (bus2ip_clk),
        .rst_n          (bus2ip_rst_n),  
    
        .sync_reset_i   (WCtrlDataStart_i), 
        .write_en_i     (mdio_command_wr), 
        .data_i         (bus2ip_data_i[2]),
        .data_o         (mdio_command[2]) 
    );
    assign r_WCtrlData_o = mdio_command[2];

    assign mdio_command[31:3] = 0;

    //MDIO Address register
    wire mdio_address_wr = emac_blk_sel & bus2ip_wr_ce_i & (bus2ip_addr_i[7:0] == `EMAC_MDIOADDRESS_ADR);
    wire [31:0] mdio_address;

    eth_register #(5, 0) u_mdio_address_0
    (
        .clk            (bus2ip_clk),
        .rst_n          (bus2ip_rst_n),  
    
        .sync_reset_i   (1'b0), 
        .write_en_i     (mdio_address_wr), 
        .data_i         (bus2ip_data_i[4:0]),
        .data_o         (mdio_address[4:0]) 
    );
    assign r_FIAD_o   = mdio_address[4:0];

    eth_register #(5, 0) u_mdio_address_1
    (
        .clk            (bus2ip_clk),
        .rst_n          (bus2ip_rst_n),  
    
        .sync_reset_i   (1'b0), 
        .write_en_i     (mdio_address_wr), 
        .data_i         (bus2ip_data_i[12:8]),
        .data_o         (mdio_address[12:8]) 
    );
    assign r_RGAD_o   = mdio_address[12:8];

    assign mdio_address[31:13] = 0;
    assign mdio_address[7:5]   = 0;

    //MDIO transmit data register
    wire mdio_tx_data_wr = emac_blk_sel & bus2ip_wr_ce_i & (bus2ip_addr_i[7:0] == `EMAC_MDIOTX_DATA_ADR);
    wire [31:0] mdio_tx_data;

    eth_register #(16, 0) u_mdio_tx_data_0
    (
        .clk            (bus2ip_clk),
        .rst_n          (bus2ip_rst_n),  
    
        .sync_reset_i   (1'b0), 
        .write_en_i     (mdio_tx_data_wr), 
        .data_i         (bus2ip_data_i[15:0]),
        .data_o         (mdio_tx_data[15:0]) 
    );
    assign r_CtrlData_o   = mdio_tx_data[15:0];

    assign mdio_tx_data[31:16] = 0;

    //MDIO receive data register
    wire [31:0] mdio_rx_data;

    eth_register #(16, 0) u_mdio_rx_data_0
    (
        .clk            (bus2ip_clk),
        .rst_n          (bus2ip_rst_n),  
    
        .sync_reset_i   (1'b0), 
        .write_en_i     (UpdateMIIRX_DATAReg_i), //not written from bus
        .data_i         (Prsd_i[15:0]),
        .data_o         (mdio_rx_data[15:0]) 
    );
    assign mdio_rx_data[31:16] = 0;

    //++
    //bus read operation
    //--
    reg [31:0] ip2bus_data;

    always @(*) begin
        ip2bus_data = 32'h0;

        if(bus2ip_rd_ce_i == 1'b1 && emac_blk_sel) begin   
            case(bus2ip_addr_i[7:0])    //deal with offset address
                `EMAC_CONFIG_ADR     :  ip2bus_data = emac_config;
                `EMAC_MDIOMODE_ADR   :  ip2bus_data = mdio_mode;  
                `EMAC_MDIOCOMMAND_ADR:  ip2bus_data = mdio_command;
                `EMAC_MDIOADDRESS_ADR:  ip2bus_data = mdio_address;
                `EMAC_MDIOTX_DATA_ADR:  ip2bus_data = mdio_tx_data;
                `EMAC_MDIORX_DATA_ADR:  ip2bus_data = mdio_rx_data;
                `EMAC_MDIOSTATUS_ADR :  ip2bus_data = {29'b0, NValid_stat_i, Busy_stat_i, LinkFail_i};
                default:            ip2bus_data = 32'h0;
            endcase                        
        end   
    end

    //registered output 
    always @(posedge bus2ip_clk) ip2bus_data_o <= ip2bus_data;

endmodule

