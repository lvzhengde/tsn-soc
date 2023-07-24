/*++
//  simple channel model for xge-ptpv2 testbench
--*/
`include "ptpv2_defines.v"

module channel_model (
  input               clk,

`ifdef GFE_DESIGN  //mii/gmii 
  input               rx_en_i,
  input               rx_er_i,
  input  [7:0]        rxd_i ,
  
  output              tx_en_o,
  output              tx_er_o,
  output [7:0]        txd_o 
`else   //default to xgmii  
  input  [63:0]       xge_rxd_i,
  input  [7:0]        xge_rxc_i,

  output [63:0]       xge_txd_o,
  output [7:0]        xge_txc_o
`endif
);

  parameter  DELAY_LEN = 8;
  integer    i;

`ifdef GFE_DESIGN
  reg  [9:0] delay_line[DELAY_LEN:0];
  
  always @(*) begin
    delay_line[0] = {rx_en_i, rx_er_i, rxd_i};
  end
  
  always @(posedge clk) begin
    for(i = 0; i < DELAY_LEN; i = i+1) begin
      delay_line[i+1] <= delay_line[i];
    end
  end
  
  assign {tx_en_o, tx_er_o, txd_o} = delay_line[DELAY_LEN];
`else
  reg [71:0] xge_delay_line[DELAY_LEN:0];

  always @(*) begin
    xge_delay_line[0] = {xge_rxc_i, xge_rxd_i};
  end

  always @(posedge clk) begin
    for(i = 0; i < DELAY_LEN; i = i+1) begin
      xge_delay_line[i+1] <= xge_delay_line[i];
    end
  end

  assign {xge_txc_o, xge_txd_o} = xge_delay_line[DELAY_LEN];
`endif
  
endmodule

