/*++
//  Description : test registers for on chip bus.
//  File        : registers_stub.v
--*/

`timescale 1ns/10fs

module registers_stub(
  //on-chip bus interface
  input                bus2ip_clk      ,
  input                bus2ip_rst_n    ,
  input  [15:0]        bus2ip_addr_i   ,
  input  [15:0]        bus2ip_data_i   ,
  input                bus2ip_rd_ce_i  ,    //active high
  input                bus2ip_wr_ce_i  ,    //active high
  output reg [15:0]    ip2bus_data_o   
);
  parameter BASEADDR = 4'h2;

  reg      [15:0]      reg0;
  reg      [15:0]      reg1;
  reg      [15:0]      reg2;
  reg      [15:0]      reg3;
  reg      [15:0]      reg4;
  reg      [15:0]      reg5;
  reg      [15:0]      reg6;
  reg      [15:0]      reg7;
  reg      [15:0]      reg8;
  reg      [15:0]      reg9;
  reg      [15:0]      reg10;
  reg      [15:0]      reg11;
  reg      [15:0]      reg12;
  reg      [15:0]      reg13;
  reg      [15:0]      reg14;
  reg      [15:0]      reg15;
  reg      [15:0]      reg16;
  reg      [15:0]      reg17;

  //bus read operation
  always @(*) begin
    ip2bus_data_o[15:0] = 16'h0;

    if(bus2ip_rd_ce_i == 1'b1 && bus2ip_addr_i[15:12] == BASEADDR) begin
      case(bus2ip_addr_i[11:0])
        12'd000:    ip2bus_data_o[15:0] = reg0; 
        12'd001:    ip2bus_data_o[15:0] = reg1;
        12'd002:    ip2bus_data_o[15:0] = reg2;
        12'd003:    ip2bus_data_o[15:0] = reg3; 
        12'd004:    ip2bus_data_o[15:0] = reg4;
        12'd005:    ip2bus_data_o[15:0] = reg5;
        12'd006:    ip2bus_data_o[15:0] = reg6; 
        12'd007:    ip2bus_data_o[15:0] = reg7;
        12'd008:    ip2bus_data_o[15:0] = reg8;
        12'd009:    ip2bus_data_o[15:0] = reg9; 
        12'd010:    ip2bus_data_o[15:0] = reg10;
        12'd011:    ip2bus_data_o[15:0] = reg11;
        12'd012:    ip2bus_data_o[15:0] = reg12; 
        12'd013:    ip2bus_data_o[15:0] = reg13;
        12'd014:    ip2bus_data_o[15:0] = reg14;
        12'd015:    ip2bus_data_o[15:0] = reg15; 
        12'd016:    ip2bus_data_o[15:0] = reg16;
        12'd017:    ip2bus_data_o[15:0] = reg17;

        default:    ip2bus_data_o = 16'h0;
      endcase
    end
  end

  //Bus write operation
  always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
    if(!bus2ip_rst_n) begin
      reg0   <= 16'h0; 
      reg1   <= 16'h0;
      reg2   <= 16'h0;
      reg3   <= 16'h0; 
      reg4   <= 16'h0;
      reg5   <= 16'h0;
      reg6   <= 16'h0; 
      reg7   <= 16'h0;
      reg8   <= 16'h0;
      reg9   <= 16'h0; 
      reg10  <= 16'h0;
      reg11  <= 16'h0;
      reg12  <= 16'h0;
      reg13  <= 16'h0;
      reg14  <= 16'h0;
      reg15  <= 16'h0;
      reg16  <= 16'h0;
      reg17  <= 16'h0;
    end
    else if(bus2ip_wr_ce_i == 1'b1 && bus2ip_addr_i[15:12] == BASEADDR) begin
      case(bus2ip_addr_i[11:0])
        12'd000 :  reg0   <= bus2ip_data_i; 
        12'd001 :  reg1   <= bus2ip_data_i; 
        12'd002 :  reg2   <= bus2ip_data_i; 
        12'd003 :  reg3   <= bus2ip_data_i; 
        12'd004 :  reg4   <= bus2ip_data_i; 
        12'd005 :  reg5   <= bus2ip_data_i; 
        12'd006 :  reg6   <= bus2ip_data_i; 
        12'd007 :  reg7   <= bus2ip_data_i; 
        12'd008 :  reg8   <= bus2ip_data_i; 
        12'd009 :  reg9   <= bus2ip_data_i; 
        12'd010 :  reg10  <= bus2ip_data_i; 
        12'd011 :  reg11  <= bus2ip_data_i; 
        12'd012 :  reg12  <= bus2ip_data_i; 
        12'd013 :  reg13  <= bus2ip_data_i; 
        12'd014 :  reg14  <= bus2ip_data_i; 
        12'd015 :  reg15  <= bus2ip_data_i; 
        12'd016 :  reg16  <= bus2ip_data_i; 
        12'd017 :  reg17  <= bus2ip_data_i; 
      endcase
    end
  end

endmodule
