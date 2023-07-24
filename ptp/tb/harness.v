/*++
//   ptpv2 ip core test harness
--*/
`include "ptpv2_defines.v"

module harness;  
  //signal definition for local device
  wire          rx_clk; 
  wire          tx_clk; 

`ifdef GFE_DESIGN
  wire          rx_en_i; 
  wire          rx_er_i; 
  wire [7:0]    rxd_i ;                

  wire          tx_en_o; 
  wire          tx_er_o; 
  wire [7:0]    txd_o ;             
`else
  wire [63:0]   xge_rxd_i;
  wire [7:0]    xge_rxc_i;
                       
  wire [63:0]   xge_txd_o;
  wire [7:0]    xge_txc_o;
`endif

  wire          pps_o ; 
`ifdef GFE_DESIGN
  wire          mii_mode_o ;
`endif
  
  //signal definition for link partner device
  wire          lp_rx_clk; 
  wire          lp_tx_clk; 

`ifdef GFE_DESIGN
  wire          lp_rx_en_i; 
  wire          lp_rx_er_i; 
  wire [7:0]    lp_rxd_i ;                

  wire          lp_tx_en_o; 
  wire          lp_tx_er_o; 
  wire [7:0]    lp_txd_o ;             
`else
  wire [63:0]   lp_xge_rxd_i;
  wire [7:0]    lp_xge_rxc_i;

  wire [63:0]   lp_xge_txd_o;
  wire [7:0]    lp_xge_txc_o;
`endif

  wire          lp_pps_o ; 
`ifdef GFE_DESIGN
  wire          lp_mii_mode_o ;
`endif

  //++
  // channel model for link partner tx 
  //--
  wire   lp_channel_clk;
  assign lp_channel_clk = lp_tx_clk;
  
  channel_model lp_channel_model (
    .clk              (lp_channel_clk),

`ifdef GFE_DESIGN
    .rx_en_i          (lp_tx_en_o),
    .rx_er_i          (lp_tx_er_o),
    .rxd_i            (lp_txd_o ),
    
    .tx_en_o          (rx_en_i  ),
    .tx_er_o          (rx_er_i  ),
    .txd_o            (rxd_i   )
`else
    .xge_rxd_i        (lp_xge_txd_o ),
    .xge_rxc_i        (lp_xge_txc_o ),

    .xge_txd_o        (xge_rxd_i ),
    .xge_txc_o        (xge_rxc_i )
`endif
  ); 
  defparam lp_channel_model.DELAY_LEN = 8;
  
  //++
  // channel model for local device tx 
  //--
  wire    channel_clk;
  assign  channel_clk = tx_clk;
  
  channel_model channel_model (
    .clk              (channel_clk),

`ifdef GFE_DESIGN 
    .rx_en_i          (tx_en_o),
    .rx_er_i          (tx_er_o),
    .rxd_i            (txd_o ),
    
    .tx_en_o          (lp_rx_en_i),
    .tx_er_o          (lp_rx_er_i),
    .txd_o            (lp_rxd_i )
`else
    .xge_rxd_i        (xge_txd_o),
    .xge_rxc_i        (xge_txc_o),

    .xge_txd_o        (lp_xge_rxd_i),
    .xge_txc_o        (lp_xge_rxc_i)
`endif

  );
  defparam channel_model.DELAY_LEN = 8;       

  ptpv2_endpoint ptpv2_endpoint (
    .rx_clk         (lp_channel_clk ),
    .tx_clk         (tx_clk ),

`ifdef GFE_DESIGN
    .rx_en_i        (rx_en_i),
    .rx_er_i        (rx_er_i),
    .rxd_i          (rxd_i ),    
  
    .tx_en_o        (tx_en_o),
    .tx_er_o        (tx_er_o),
    .txd_o          (txd_o ),
`else
    .xge_rxd_i      (xge_rxd_i),
    .xge_rxc_i      (xge_rxc_i),
                          
    .xge_txd_o      (xge_txd_o),
    .xge_txc_o      (xge_txc_o),
`endif
    
`ifdef GFE_DESIGN
    .mii_mode_o     (mii_mode_o),
`endif
    .pps_o          (pps_o)
  );
  //local device is slave
  defparam  ptpv2_endpoint.CLOCK_MS = 0;
  
  ptpv2_endpoint lp_ptpv2_endpoint (
    .rx_clk         (channel_clk ),
    .tx_clk         (lp_tx_clk ),

`ifdef GFE_DESIGN
    .rx_en_i        (lp_rx_en_i),
    .rx_er_i        (lp_rx_er_i),
    .rxd_i          (lp_rxd_i ),    
  
    .tx_en_o        (lp_tx_en_o),
    .tx_er_o        (lp_tx_er_o),
    .txd_o          (lp_txd_o ),
`else
    .xge_rxd_i      (lp_xge_rxd_i ),
    .xge_rxc_i      (lp_xge_rxc_i ),
                         
    .xge_txd_o      (lp_xge_txd_o ),
    .xge_txc_o      (lp_xge_txc_o ),
`endif

`ifdef GFE_DESIGN      
    .mii_mode_o     (lp_mii_mode_o),
`endif
  
    .pps_o          (lp_pps_o)
  );
  //link parter is master
  defparam lp_ptpv2_endpoint.CLOCK_MS = 1;

endmodule

