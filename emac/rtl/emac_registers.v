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

    // miim registers
    output reg [7:0]    r_ClkDiv_o           , 
    output reg          r_MiiNoPre_o         , 
    output reg [15:0]   r_CtrlData_o         , 
    output reg [4:0]    r_RGAD_o             , 
    output reg [4:0]    r_FIAD_o             , 
    output reg          r_WCtrlData_o        , 
    output reg          r_RStat_o            , 
    output reg          r_ScanStat_o         , 
    input               Busy_stat_i          , 
    input  [15:0]       Prsd_i               , 
    input               LinkFail_i           , 
    input               NValid_stat_i        , 
    input               WCtrlDataStart_i     , 
    input               RStatStart_i         , 
    input               UpdateMIIRX_DATAReg_i 
);

endmodule

