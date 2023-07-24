/*++
//  ptpv2 top level
//  with simple XGMII interface
//  32 bits on-chip-bus register I/O interface, 
--*/
`include "ptpv2_defines.v"

module ptpv2_core (
  input               rtc_clk,
  input               rtc_rst_n,              //async. reset, active low
  input               dis_ptpv2_i,            //disable ptpv2

  //rx interface
  input               rx_clk,
  input               rx_rst_n,
  input               rx_clk_en_i,            //for adapting to gmii/mii
  input  [63:0]       xge_rxd_i,
  input  [7:0]        xge_rxc_i,
  output [63:0]       xge_rxd_o,
  output [7:0]        xge_rxc_o,
    
  //tx interface
  input               tx_clk,
  input               tx_rst_n,
  input               tx_clk_en_i,           //for adapting to gmii/mii
  input  [63:0]       xge_txd_i,
  input  [7:0]        xge_txc_i,
  output [63:0]       xge_txd_o,
  output [7:0]        xge_txc_o,

  //32 bits on chip bus access interface
  input               bus2ip_clk   ,
  input               bus2ip_rst_n  ,
  input  [31:0]       bus2ip_addr_i ,
  input  [31:0]       bus2ip_data_i ,
  input               bus2ip_rd_ce_i ,         //active high
  input               bus2ip_wr_ce_i ,         //active high
  output [31:0]       ip2bus_data_o ,  

  //interrupt signals generated from ptpv2 core
  output              intxms_o,
  output              int_rx_ptp_o,
  output              int_tx_ptp_o,

  input               pps_i,        //1 pulse per second input
  output              pps_o         //1 pulse per second output
);
  wire [79:0]         rtc_std;      //48 bits seconds + 32 bits nanoseconds
  wire [15:0]         rtc_fns;      //16 bit fractional nanoseconds of rtc

  wire [31:0]         rtc_ip2bus_data;
  wire [31:0]         tsu_ip2bus_data;

  assign  ip2bus_data_o = rtc_ip2bus_data | tsu_ip2bus_data;
  
  rtc_unit rtc_unit_inst(
    .rtc_clk                  (rtc_clk  ),
    .rtc_rst_n                (rtc_rst_n),              

    //bus interface
    .bus2ip_clk               (bus2ip_clk      ),
    .bus2ip_rst_n             (bus2ip_rst_n    ),
                                                
    .bus2ip_addr_i            (bus2ip_addr_i   ),
    .bus2ip_data_i            (bus2ip_data_i   ),
    .bus2ip_rd_ce_i           (bus2ip_rd_ce_i  ),         
    .bus2ip_wr_ce_i           (bus2ip_wr_ce_i  ),         
    .ip2bus_data_o            (rtc_ip2bus_data ),  

	//time related signals
    .rtc_std_o                (rtc_std),          
    .rtc_fns_o                (rtc_fns),           
	
    .intxms_o                 (intxms_o),
    .pps_i                    (pps_i),        
    .pps_o                    (pps_o)         
  );
  defparam rtc_unit_inst.BLK_ADDR = `RTC_BLK_ADDR;

  timestamp_unit timestamp_unit_inst(
    .rtc_clk                  (rtc_clk),
    .rtc_rst_n                (rtc_rst_n), 
    .dis_ptpv2_i              (dis_ptpv2_i ),         

    //rx interface
    .rx_clk                   (rx_clk     ),
    .rx_rst_n                 (rx_rst_n   ),
    .rx_clk_en_i              (rx_clk_en_i),           
    .xge_rxd_i                (xge_rxd_i  ),
    .xge_rxc_i                (xge_rxc_i  ),
    .xge_rxd_o                (xge_rxd_o  ),
    .xge_rxc_o                (xge_rxc_o  ),
    
    //tx interface
    .tx_clk                   (tx_clk     ),
    .tx_rst_n                 (tx_rst_n   ),
    .tx_clk_en_i              (tx_clk_en_i),          
    .xge_txd_i                (xge_txd_i  ),
    .xge_txc_i                (xge_txc_i  ),
    .xge_txd_o                (xge_txd_o  ),
    .xge_txc_o                (xge_txc_o  ),

	//time input
    .rtc_std_i                (rtc_std),          
    .rtc_fns_i                (rtc_fns),           

    //on chip bus access interface
    .bus2ip_clk               (bus2ip_clk    ),
    .bus2ip_rst_n             (bus2ip_rst_n  ),
    .bus2ip_addr_i            (bus2ip_addr_i ),
    .bus2ip_data_i            (bus2ip_data_i ),
    .bus2ip_rd_ce_i           (bus2ip_rd_ce_i),         
    .bus2ip_wr_ce_i           (bus2ip_wr_ce_i),         
    .ip2bus_data_o            (tsu_ip2bus_data ),  

    //interrupt signals generated from ptpv2 core
    .int_rx_ptp_o             (int_rx_ptp_o),
    .int_tx_ptp_o             (int_tx_ptp_o)
  );
  defparam timestamp_unit_inst.BLK_ADDR = `TSU_BLK_ADDR;

endmodule

