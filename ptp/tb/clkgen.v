/*++
//  clock and reset generation
--*/
`include "ptpv2_defines.v"

module clkgen (
`ifdef GFE_DESIGN
  input        mii_mode_i,
`endif

  output       rtc_clk,
  output       tx_clk,
  output reg   pbus_clk,
  output reg   rst_sys_n
);
  parameter    T_PBUS_CLK     = 40,
               T_RTC_CLK     = 8,
               T_XGE_RTC_CLK = 6.4,
               T_GE_TX_CLK   = 8,
               T_FE_TX_CLK   = 40,
               T_XGE_TX_CLK  = 6.4;   

  reg ge_tx_clk, fe_tx_clk, xge_tx_clk;
  reg gfe_rtc_clk, xge_rtc_clk;
  
  //clock and reset initialization
  initial begin
    ge_tx_clk   = 0;
    fe_tx_clk   = 0;
    xge_tx_clk  = 0;
    gfe_rtc_clk = 0;
    xge_rtc_clk = 0;

    pbus_clk     = 0;
    rst_sys_n   = 1;
  end
  
  // clock generation
  always #(T_PBUS_CLK/2) pbus_clk = ~pbus_clk;

  always #(T_RTC_CLK/2) gfe_rtc_clk = ~gfe_rtc_clk;

  always #(T_XGE_RTC_CLK/2) xge_rtc_clk = ~xge_rtc_clk;

  always #(T_GE_TX_CLK/2) ge_tx_clk = ~ge_tx_clk;         
  
  always #(T_FE_TX_CLK/2) fe_tx_clk = ~fe_tx_clk;         

  always #(T_XGE_TX_CLK/2) xge_tx_clk = ~xge_tx_clk;         

`ifdef GFE_DESIGN 
  assign rtc_clk = gfe_rtc_clk;
  assign tx_clk  = (mii_mode_i == 1'b0) ? ge_tx_clk : fe_tx_clk;
`else
  assign rtc_clk = xge_rtc_clk;
  assign tx_clk  = xge_tx_clk;
`endif

  // task for reset operation
  task reset;
  begin
      #55
      rst_sys_n    = 0;
      
      #(40*5000);
 
      #355 
      rst_sys_n    = 1;
  end
  endtask 
  
endmodule

