/*++
//  bridge from apb-like bus to standard ip access bus
--*/

`include "ptpv2_defines.v"

module pbus_bridge (
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

  //standard ip access bus interface
  output              bus2ip_clk   ,
  output              bus2ip_rst_n  ,
  output [31:0]       bus2ip_addr_o ,
  output [31:0]       bus2ip_data_o ,
  output              bus2ip_rd_ce_o ,         //active high
  output              bus2ip_wr_ce_o ,         //active high
  input  [31:0]       ip2bus_data_i   
);

  //generate bus control signals
  assign bus2ip_wr_ce_o = pbus_sel_i & pbus_enable_i & pbus_write_i;
  assign bus2ip_rd_ce_o = pbus_sel_i & (~pbus_write_i);

  //pass through signals
  assign bus2ip_clk    = pbus_clk;
  assign bus2ip_rst_n  = pbus_rst_n;
  assign bus2ip_addr_o = pbus_addr_i;
  assign bus2ip_data_o = pbus_wdata_i;

  assign pbus_rdata_o  = ip2bus_data_i;

  //wire to constant
  assign pbus_ready_o  = 1'b1;
  assign pbus_slverr_o = 1'b0;

endmodule

