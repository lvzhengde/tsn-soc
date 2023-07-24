/*++
//  emulated ptpv2 endpoint 
//  including functions on sw and hw
--*/
`include "ptpv2_defines.v"

module ptpv2_endpoint (
  input           rx_clk ,
  output          tx_clk ,

`ifdef GFE_DESIGN
  input           rx_en_i   ,
  input           rx_er_i   ,
  input  [7:0]    rxd_i    ,    
  
  output          tx_en_o   ,
  output          tx_er_o   ,
  output [7:0]    txd_o    , 
`else
  input  [63:0]   xge_rxd_i,
  input  [7:0]    xge_rxc_i,

  output [63:0]   xge_txd_o,
  output [7:0]    xge_txc_o,
`endif

`ifdef GFE_DESIGN  
  output          mii_mode_o,
`endif
  
  output          pps_o
);
  parameter    CLOCK_MS = 0;     //0: slave, none-0: master;
  parameter    T_PBUS_CLK    = 40,
               T_RTC_CLK     = 8,
               T_XGE_RTC_CLK = 6.4,
               T_GE_TX_CLK   = 8,
               T_FE_TX_CLK   = 40,
               T_XGE_TX_CLK  = 6.4;   
  
  wire        pbus_clk;
  wire        rtc_clk;
  wire        rst_sys_n;
  
`ifdef GFE_DESIGN
  wire        mii_mode_hw;
`endif
  wire        dis_ptpv2 = 1'b0;

`ifdef GFE_DESIGN
  wire        rx_en_out;
  wire        rx_er_out;
  wire [7:0]  rxd_out;

  wire        tx_en_in;
  wire        tx_er_in;
  wire [7:0]  txd_in;
`else
  wire [7:0]  xge_rxc_out;
  wire [63:0] xge_rxd_out;

  wire [7:0]  xge_txc_in;
  wire [63:0] xge_txd_in;
`endif

  //++
  // ptpv2_core_wrapper glue logics
  //--
  //apb-like bus
  wire              pbus_rst_n = rst_sys_n;
  wire   [31:0]     pbus_addr = 32'b0;  
  wire              pbus_write = 1'b0;
  wire              pbus_sel = 1'b1;
  wire              pbus_enable = 1'b1;
  wire   [31:0]     pbus_wdata = 32'b0;
  wire   [31:0]     pbus_rdata;
  wire              pbus_ready;
  wire              pbus_slverr;

  wire   pps_out; 
  wire   pps_in = 1'b0;
  wire   intxms; 
  wire   int_rx_ptp; 
  wire   int_tx_ptp;
  
  assign pps_o = pps_out;

`ifdef GFE_DESIGN
  assign       mii_mode_o = mii_mode_hw;
`endif

  wire              bus2ip_clk   ;
  wire              bus2ip_rst_n ;
  wire  [31:0]      bus2ip_addr  ;
  wire  [31:0]      bus2ip_data  ;
  wire              bus2ip_rd_ce ;       //active high
  wire              bus2ip_wr_ce ;       //active high
  wire  [31:0]      ip2bus_data  ;

  //++
  //instantiate ptpv2_agent the mac and software simulator
  //
  assign bus2ip_clk = pbus_clk;
  assign bus2ip_rst_n = pbus_rst_n;

  initial begin
    force ptpv2_core_wrapper.bus2ip_addr  = bus2ip_addr;
    force ptpv2_core_wrapper.bus2ip_data  = bus2ip_data;
    force ptpv2_core_wrapper.bus2ip_rd_ce = bus2ip_rd_ce;
    force ptpv2_core_wrapper.bus2ip_wr_ce = bus2ip_wr_ce;
    force ip2bus_data = ptpv2_core_wrapper.ip2bus_data;
  end

  //instantiate clock/reset model
  clkgen clkgen (
`ifdef GFE_DESIGN
    .mii_mode_i       (mii_mode_hw),
`endif

    .pbus_clk         (pbus_clk),
    .rtc_clk          (rtc_clk),
    .tx_clk           (tx_clk),
    .rst_sys_n        (rst_sys_n )
  );
  defparam clkgen.T_PBUS_CLK = T_PBUS_CLK  ;
  defparam clkgen.T_RTC_CLK = T_RTC_CLK  ;
  defparam clkgen.T_XGE_RTC_CLK = T_XGE_RTC_CLK;
  defparam clkgen.T_GE_TX_CLK = T_GE_TX_CLK;
  defparam clkgen.T_FE_TX_CLK = T_FE_TX_CLK;
  defparam clkgen.T_XGE_TX_CLK = T_XGE_TX_CLK;

  ptp_agent ptp_agent (
    //rtc and sw register interface
    .rtc_clk                 (rtc_clk   ),
    .rst_sys_n               (rst_sys_n ),
  
    .intxms_i                (intxms   ),
    .int_rx_ptp_i            (int_rx_ptp ),
    .int_tx_ptp_i            (int_tx_ptp ),
    
    //xgmii/gmii/mii interface
    .rx_clk                  (rx_clk    ), 
    .tx_clk                  (tx_clk  ),

`ifdef GFE_DESIGN
    .rx_en_i                 (rx_en_out ),
    .rx_er_i                 (rx_er_out ),
    .rxd_i                   (rxd_out   ),
  
    .tx_en_o                 (tx_en_in ),
    .tx_er_o                 (tx_er_in ),
    .txd_o                   (txd_in   ),
`else
    .xge_rxc_i               (xge_rxc_out),
    .xge_rxd_i               (xge_rxd_out),

    .xge_txc_o               (xge_txc_in),
    .xge_txd_o               (xge_txd_in),
`endif

     //on chip bus interface
    .bus2ip_clk              (bus2ip_clk    ),
    .bus2ip_rst_n            (bus2ip_rst_n  ),
    .bus2ip_addr_o           (bus2ip_addr   ),
    .bus2ip_data_o           (bus2ip_data   ),
    .bus2ip_rd_ce_o          (bus2ip_rd_ce  ),         //active high
    .bus2ip_wr_ce_o          (bus2ip_wr_ce  ),         //active high
    .ip2bus_data_i           (ip2bus_data   )  
  );  
  defparam ptp_agent.CLOCK_MS = CLOCK_MS;

  //++
  //instantiate ptpv2 core wrapper 
  //--
  ptpv2_core_wrapper ptpv2_core_wrapper (
    .rtc_clk                 (rtc_clk  ),
    .rtc_rst_n               (rst_sys_n),             //async. reset, active low
                                                
    //rx interface
    .rx_clk                  (rx_clk   ),
    .rx_rst_n                (rst_sys_n ),
    
`ifdef GFE_DESIGN
    .rx_en_i                 (rx_en_i   ), 
    .rx_er_i                 (rx_er_i   ),
    .rxd_i                   (rxd_i     ),

    .rx_en_o                 (rx_en_out ),
    .rx_er_o                 (rx_er_out ),
    .rxd_o                   (rxd_out   ),   
`else
    .xge_rxc_i               (xge_rxc_i),
    .xge_rxd_i               (xge_rxd_i),

    .xge_rxc_o               (xge_rxc_out),
    .xge_rxd_o               (xge_rxd_out),
`endif
      
    //tx interface
    .tx_clk                  (tx_clk   ),
    .tx_rst_n                (rst_sys_n ),

`ifdef GFE_DESIGN 
    .tx_en_i                 (tx_en_in  ), 
    .tx_er_i                 (tx_er_in  ),
    .txd_i                   (txd_in    ),  
    
    .tx_en_o                 (tx_en_o),
    .tx_er_o                 (tx_er_o),
    .txd_o                   (txd_o  ),
`else
    .xge_txc_i               (xge_txc_in),
    .xge_txd_i               (xge_txd_in),

    .xge_txc_o               (xge_txc_o),
    .xge_txd_o               (xge_txd_o),
`endif
    
    //apb-like bus register access interface
    .pbus_clk                (pbus_clk),
    .pbus_rst_n              (pbus_rst_n),

    .pbus_addr_i             (pbus_addr  ),
    .pbus_write_i            (pbus_write ),
    .pbus_sel_i              (pbus_sel   ),
    .pbus_enable_i           (pbus_enable),
    .pbus_wdata_i            (pbus_wdata ),
    .pbus_rdata_o            (pbus_rdata ),
    .pbus_ready_o            (pbus_ready ),
    .pbus_slverr_o           (pbus_slverr),

    //control i/o
`ifdef GFE_DESIGN
    .mii_mode_hw_i           (mii_mode_hw),  
`endif
    .dis_ptpv2_i             (dis_ptpv2   ),   


    //interrupts
    .intxms_o                (intxms   ),
    .int_rx_ptp_o            (int_rx_ptp ),
    .int_tx_ptp_o            (int_tx_ptp ),

    .pps_o                   (pps_out  ), 
    .pps_i                   (pps_in)           
  );

endmodule

