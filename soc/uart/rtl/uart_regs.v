/*++
//  Description : uart configuration and status registers.
//  File        : uart_regs.v
--*/

`timescale 1ns/10fs

module uart_regs(
  //on-chip bus interface
  input                bus2ip_clk      ,
  input                bus2ip_rst_n    ,
  input  [15:0]        bus2ip_addr_i   ,
  input  [15:0]        bus2ip_data_i   ,
  input                bus2ip_rd_ce_i  ,    //active high
  input                bus2ip_wr_ce_i  ,    //active high
  output reg [15:0]    ip2bus_data_o   ,

  //fifo status signals
  input                rx_buffer_data_present_i ,
  input                rx_buffer_full_i         ,
  input                rx_buffer_hfull_i    ,
  input                rx_buffer_afull_i  ,
  input                rx_buffer_aempty_i ,

  input                tx_buffer_full_i       ,
  input                tx_buffer_hfull_i  ,
  input                tx_buffer_afull_i,
  input                tx_buffer_aempty_i,

  //configurations
  output reg           parity_en_o         ,      //0: no parity; 1: has parity
  output reg           msb_first_o         ,      //0: lsb first; 1: msb first           
  output reg           start_polarity_o    ,      //0: low level start bit, high level stop bit; 1: high level start bit, low level stop bit;
  output reg           reset_buffer_o      ,      //reset uart fifo, active high
  output reg [15:0]    baud_config_o
);
  parameter BASEADDR = 4'h0;

  reg    reset_buffer, reset_buffer_d1, reset_buffer_d2;

  //bus read operation
  always @(*) begin
    ip2bus_data_o[15:0] = 16'h0;

    if(bus2ip_rd_ce_i == 1'b1 && bus2ip_addr_i[15:12] == BASEADDR) begin
      case(bus2ip_addr_i[11:0])
        12'h000:    ip2bus_data_o[15:0] = baud_config_o[15:0]; 
        12'h001:    ip2bus_data_o[15:0] = {14'b0, parity_en_o, msb_first_o};
        
        12'h003:    ip2bus_data_o[15:0] = {7'b0, rx_buffer_data_present_i, rx_buffer_full_i, rx_buffer_hfull_i,
	               rx_buffer_afull_i, rx_buffer_aempty_i,	tx_buffer_full_i, tx_buffer_hfull_i, 
		       tx_buffer_afull_i, tx_buffer_aempty_i};
        default:    ip2bus_data_o = 16'h0;
      endcase
    end
  end

  always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
    if(!bus2ip_rst_n) begin
      baud_config_o[15:0] <= 16'd68;         //125MHz system clock, 115200 baud rate
      parity_en_o         <= 1'b0;
      msb_first_o         <= 1'b0;
      start_polarity_o    <= 1'b0;
      reset_buffer        <= 1'b0;
    end
    else if(bus2ip_wr_ce_i == 1'b1 && bus2ip_addr_i[15:12] == BASEADDR) begin
      case(bus2ip_addr_i[11:0])
        12'h000:   baud_config_o[15:0]        <= bus2ip_data_i[15:0];
        12'h001:   {parity_en_o, msb_first_o, start_polarity_o} <= bus2ip_data_i[2:0] ;
        12'h002:   reset_buffer               <= bus2ip_data_i[0]   ;
      endcase
    end
    else
      reset_buffer       <= 1'b0;
  end

  always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
    if(!bus2ip_rst_n) begin
      {reset_buffer_d1, reset_buffer_d2} <= 2'b0;
      reset_buffer_o  <= 1'b0;
    end
    else begin
      {reset_buffer_d1, reset_buffer_d2} <= {reset_buffer, reset_buffer_d1};
      reset_buffer_o  <= (reset_buffer | reset_buffer_d1) & (~reset_buffer_d2);
    end
  end

endmodule
