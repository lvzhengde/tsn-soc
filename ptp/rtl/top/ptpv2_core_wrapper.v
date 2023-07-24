/*++
//  ptpv2 core ip wrapper, includes apb-like on-chip-bus  slave interface and core ip.
--*/
`include "ptpv2_defines.v"

module ptpv2_core_wrapper (
  input               rtc_clk,
  input               rtc_rst_n,              //async. reset, active low

  //rx interface
  input               rx_clk,
  input               rx_rst_n,
    
`ifdef GFE_DESIGN 
  //rx gmii/mii
  input               rx_en_i, 
  input               rx_er_i,
  input  [7:0]        rxd_i,
  
  output              rx_en_o,
  output              rx_er_o,
  output [7:0]        rxd_o,   
`else
  //rx xgmii-like
  input  [63:0]       xge_rxd_i,
  input  [7:0]        xge_rxc_i,
  
  output  [63:0]      xge_rxd_o,
  output  [7:0]       xge_rxc_o,
`endif
    
  //tx interface
  input               tx_clk,
  input               tx_rst_n,
  
`ifdef GFE_DESIGN
  //tx gmii/mii
  input               tx_en_i, 
  input               tx_er_i,
  input  [7:0]        txd_i,  
  
  output              tx_en_o,
  output              tx_er_o,
  output [7:0]        txd_o,
`else
  //tx xgmii-like
  input  [63:0]       xge_txd_i,
  input  [7:0]        xge_txc_i,
  
  output [63:0]       xge_txd_o,
  output [7:0]        xge_txc_o,
`endif  

  //apb-like bus slave interface
  input               pbus_clk,
  input               pbus_rst_n,
  input  [31:0]       pbus_addr_i,
  input               pbus_write_i,
  input               pbus_sel_i,
  input               pbus_enable_i,
  input  [31:0]       pbus_wdata_i,
  output [31:0]       pbus_rdata_o,
  output              pbus_ready_o,
  output              pbus_slverr_o,

  //control i/o
`ifdef GFE_DESIGN                                                                                                    
  input               mii_mode_hw_i,          //0:ge, 1: 100m/10m ethernet
`endif
  input               dis_ptpv2_i,
  
  //interrupt signals 
  output              intxms_o,
  output              int_rx_ptp_o,
  output              int_tx_ptp_o,

  output              pps_o,                  //pps output
  input               pps_i                   //pps input
);

  //interconnect signals.
  wire                bus2ip_clk   ;
  wire                bus2ip_rst_n ;
  wire  [31:0]        bus2ip_addr  ;
  wire  [31:0]        bus2ip_data  ;
  wire                bus2ip_rd_ce ;       //active high
  wire                bus2ip_wr_ce ;       //active high
  wire  [31:0]        ip2bus_data  ;

  //apb-like bus slave bridge 
  pbus_bridge pbus_bridge_inst (
    //apb-like bus register access interface
    .pbus_clk          (pbus_clk     ),
    .pbus_rst_n        (pbus_rst_n   ),
    .pbus_addr_i       (pbus_addr_i  ),
    .pbus_write_i      (pbus_write_i ),
    .pbus_sel_i        (pbus_sel_i   ),
    .pbus_enable_i     (pbus_enable_i),
    .pbus_wdata_i      (pbus_wdata_i ),
    .pbus_rdata_o      (pbus_rdata_o ),
    .pbus_ready_o      (pbus_ready_o ),
    .pbus_slverr_o     (pbus_slverr_o),

    //standard ip register access bus interface
    .bus2ip_clk        (bus2ip_clk    ),
    .bus2ip_rst_n      (bus2ip_rst_n  ),
    .bus2ip_addr_o     (bus2ip_addr   ),
    .bus2ip_data_o     (bus2ip_data   ),
    .bus2ip_rd_ce_o    (bus2ip_rd_ce  ),         //active high
    .bus2ip_wr_ce_o    (bus2ip_wr_ce  ),         //active high
    .ip2bus_data_i     (ip2bus_data   )  
  );

  //++
  //instantiate ptpv2_core
  //--
  wire  rx_clk_en;
  wire [63:0]      xge_rxd_in;
  wire [7:0]       xge_rxc_in;
  wire [63:0]      xge_rxd_out;
  wire [7:0]       xge_rxc_out;

  wire  tx_clk_en;
  wire [63:0]      xge_txd_in;
  wire [7:0]       xge_txc_in;
  wire [63:0]      xge_txd_out;
  wire [7:0]       xge_txc_out;

`ifdef GFE_DESIGN   //ge/fe
  wire           rx_en_out;
  wire           rx_er_out;
  wire [7:0]     rxd_out;   

  assign rx_en_o = (dis_ptpv2_i == 1'b1) ? rx_en_i : rx_en_out;
  assign rx_er_o = (dis_ptpv2_i == 1'b1) ? rx_er_i : rx_er_out;
  assign rxd_o   = (dis_ptpv2_i == 1'b1) ? rxd_i   : rxd_out  ;   

  gfe_cvt rx_gfe_cvt (
    .clk         (rx_clk),
    .rst_n       (rx_rst_n),

    .mii_mode_i  (mii_mode_hw_i),
    .clk_en_o    (rx_clk_en),

    .en_i        (rx_en_i), 
    .er_i        (rx_er_i),
    .d_i         (rxd_i),
  
    .en_o        (rx_en_out),
    .er_o        (rx_er_out),
    .d_o         (rxd_out),   

    .xd_i        (xge_rxd_out),
    .xc_i        (xge_rxc_out),
  
    .xd_o        (xge_rxd_in),
    .xc_o        (xge_rxc_in)
  );

  wire           tx_en_out;
  wire           tx_er_out;
  wire [7:0]     txd_out;   

  assign tx_en_o = (dis_ptpv2_i == 1'b1) ? tx_en_i : tx_en_out;
  assign tx_er_o = (dis_ptpv2_i == 1'b1) ? tx_er_i : tx_er_out;
  assign txd_o   = (dis_ptpv2_i == 1'b1) ? txd_i   : txd_out  ;   
  
  gfe_cvt_tx_gfe_cvt (
    .clk         (tx_clk),
    .rst_n       (tx_rst_n),

    .mii_mode_i  (mii_mode_hw_i),
    .clk_en_o    (tx_clk_en),

    .en_i        (tx_en_i), 
    .er_i        (tx_er_i),
    .d_i         (txd_i),
  
    .en_o        (tx_en_out),
    .er_o        (tx_er_out),
    .d_o         (txd_out),   

    .xd_i        (xge_txd_out),
    .xc_i        (xge_txc_out),
  
    .xd_o        (xge_txd_in),
    .xc_o        (xge_txc_in)
  );
`else               //xge
  assign rx_clk_en = 1'b1;
  assign tx_clk_en = 1'b1;

  assign xge_rxd_in = xge_rxd_i;
  assign xge_rxc_in = xge_rxc_i;

  assign xge_rxd_o = (dis_ptpv2_i == 1'b1) ? xge_rxd_i : xge_rxd_out;
  assign xge_rxc_o = (dis_ptpv2_i == 1'b1) ? xge_rxc_i : xge_rxc_out;
  
  assign xge_txd_in = xge_txd_i;
  assign xge_txc_in = xge_txc_i;
  
  assign xge_txd_o = (dis_ptpv2_i == 1'b1) ? xge_txd_i : xge_txd_out;
  assign xge_txc_o = (dis_ptpv2_i == 1'b1) ? xge_txc_i : xge_txc_out;
`endif  

  ptpv2_core ptpv2_core_inst (
    .rtc_clk          (rtc_clk    ),    
    .rtc_rst_n        (rtc_rst_n  ),   
                      
    .dis_ptpv2_i      (dis_ptpv2_i),    
  
    //rx interface
    .rx_clk           (rx_clk  ),
    .rx_rst_n         (rx_rst_n),
    .rx_clk_en_i      (rx_clk_en),       
    .xge_rxd_i        (xge_rxd_in ),
    .xge_rxc_i        (xge_rxc_in ),
    .xge_rxd_o        (xge_rxd_out),
    .xge_rxc_o        (xge_rxc_out),
      
    //tx interface
    .tx_clk           (tx_clk  ),
    .tx_rst_n         (tx_rst_n),
    .tx_clk_en_i      (tx_clk_en), 
    .xge_txd_i        (xge_txd_in ),
    .xge_txc_i        (xge_txc_in ),
    .xge_txd_o        (xge_txd_out),
    .xge_txc_o        (xge_txc_out),
  
    //32 bits on chip bus access interface
    .bus2ip_clk       (bus2ip_clk    ),
    .bus2ip_rst_n     (bus2ip_rst_n  ),
    .bus2ip_addr_i    (bus2ip_addr   ),
    .bus2ip_data_i    (bus2ip_data   ),
    .bus2ip_rd_ce_i   (bus2ip_rd_ce  ),         
    .bus2ip_wr_ce_i   (bus2ip_wr_ce  ),         
    .ip2bus_data_o    (ip2bus_data   ),  

    //interrupt signals generated from ptpv2 core
    .intxms_o         (intxms_o    ),
    .int_rx_ptp_o     (int_rx_ptp_o),
    .int_tx_ptp_o     (int_tx_ptp_o),
                                   
    .pps_i            (pps_i   ),        
    .pps_o            (pps_o   )   
  );

endmodule

