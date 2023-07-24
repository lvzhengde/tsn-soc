/*++
// ptp top module
// including ptp_nic, ptpv2_core
--*/

`include "ptpv2_defines.v"

module ptp_top (
  //tx interface
  input               tx_clk,
  input               tx_rst_n,
  
  output [63:0]       xge_txd_o,
  output [7:0]        xge_txc_o,

  //rx interface
  input               rx_clk,
  input               rx_rst_n,

  input  [63:0]       xge_rxd_i,
  input  [7:0]        xge_rxc_i,

  //32 bits on chip bus access interface
  input               bus2ip_clk   ,
  input               bus2ip_rst_n  ,
  input  [31:0]       bus2ip_addr_i ,
  input  [31:0]       bus2ip_data_i ,
  input               bus2ip_rd_ce_i ,   //active high
  input               bus2ip_wr_ce_i ,   //active high
  output [31:0]       ip2bus_data_o,   

  //combined interrupt output
  output              int_ptp_o,

  //rtc related
  input               rtc_clk,
  input               rtc_rst_n,    //async. reset, active low
  input               pps_i,        //1 pulse per second input
  output              pps_o         //1 pulse per second output
);
  wire  [63:0]   txd;
  wire  [7:0]    txc;

  wire  [63:0]   rxd;
  wire  [7:0]    rxc;

  wire           intxms;
  wire           int_rx_ptp;
  wire           int_tx_ptp;

  wire  [31:0]   nic_ip2bus_data;   
  wire  [31:0]   core_ip2bus_data;   

  assign ip2bus_data_o = nic_ip2bus_data | core_ip2bus_data; 

  ptp_nic ptp_nic(
    //tx interface
    .tx_clk             (tx_clk   ),
    .tx_rst_n           (tx_rst_n ),
                                  
    .xge_txd_o          (txd),
    .xge_txc_o          (txc),
  
    //rx interface
    .rx_clk             (rx_clk   ),
    .rx_rst_n           (rx_rst_n ),
                                  
    .xge_rxd_i          (rxd),
    .xge_rxc_i          (rxc),
  
    //32 bits on chip bus access interface
    .bus2ip_clk         (bus2ip_clk    ),
    .bus2ip_rst_n       (bus2ip_rst_n  ),
    .bus2ip_addr_i      (bus2ip_addr_i ),
    .bus2ip_data_i      (bus2ip_data_i ),
    .bus2ip_rd_ce_i     (bus2ip_rd_ce_i),      
    .bus2ip_wr_ce_i     (bus2ip_wr_ce_i),      
    .ip2bus_data_o      (nic_ip2bus_data ),   
  
    //interrupt inputs
    .intxms_i           (intxms    ),
    .int_rx_ptp_i       (int_rx_ptp),
    .int_tx_ptp_i       (int_tx_ptp),
  
    //combined interrupt output
    .int_ptp_o          (int_ptp_o)
  );

  ptpv2_core ptpv2_core(
    .rtc_clk            (rtc_clk    ),
    .rtc_rst_n          (rtc_rst_n  ), 
    .dis_ptpv2_i        (1'b0),
  
    //rx interface
    .rx_clk             (rx_clk     ),
    .rx_rst_n           (rx_rst_n   ),
    .rx_clk_en_i        (1'b1),
    .xge_rxd_i          (xge_rxd_i  ),
    .xge_rxc_i          (xge_rxc_i  ),
    .xge_rxd_o          (rxd  ),
    .xge_rxc_o          (rxc  ),
      
    //tx interface
    .tx_clk             (tx_clk     ),
    .tx_rst_n           (tx_rst_n   ),
    .tx_clk_en_i        (1'b1),         
    .xge_txd_i          (txd  ),
    .xge_txc_i          (txc  ),
    .xge_txd_o          (xge_txd_o  ),
    .xge_txc_o          (xge_txc_o  ),
  
    //32 bits on chip bus access interface
    .bus2ip_clk         (bus2ip_clk    ),
    .bus2ip_rst_n       (bus2ip_rst_n  ),
    .bus2ip_addr_i      (bus2ip_addr_i ),
    .bus2ip_data_i      (bus2ip_data_i ),
    .bus2ip_rd_ce_i     (bus2ip_rd_ce_i),    
    .bus2ip_wr_ce_i     (bus2ip_wr_ce_i),   
    .ip2bus_data_o      (core_ip2bus_data ),  
  
    //interrupt signals generated from ptpv2 core
    .intxms_o           (intxms    ),
    .int_rx_ptp_o       (int_rx_ptp),
    .int_tx_ptp_o       (int_tx_ptp),
  
    .pps_i              (pps_i),      
    .pps_o              (pps_o)     
  );

endmodule
