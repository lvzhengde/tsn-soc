/*++
//  Description  : uart test device
//  File         : uart_device.v  
--*/

`timescale 1ns/10fs

module uart_device(
  input      serial_in_i,
  output     serial_out_o  
);  
  wire          clk;
  wire          rst_n;

  wire          bus2ip_clk ; 
  wire          bus2ip_rst_n; 
  wire  [15:0]  bus2ip_addr  ; 
  wire  [15:0]  bus2ip_data  ; 
  wire          bus2ip_rd_ce ; 
  wire          bus2ip_wr_ce ; 
  wire  [15:0]  ip2bus_data  ; 

  clkgen clkgen (
    .clk                   (clk ),
    .rst_n                 (rst_n )
  );
  
  uart_core uart_core(
    .clk                   ( clk          ),
    .rst_n                 ( rst_n    ),
                                            
    .serial_in_i           ( serial_in_i    ),
    .serial_out_o          ( serial_out_o   ),  
                                            
    .bus2ip_clk            ( bus2ip_clk   ),
    .bus2ip_rst_n          ( bus2ip_rst_n ),
    .bus2ip_addr_o         ( bus2ip_addr  ),
    .bus2ip_data_o         ( bus2ip_data  ),
    .bus2ip_rd_ce_o        ( bus2ip_rd_ce ),
    .bus2ip_wr_ce_o        ( bus2ip_wr_ce ),
    .ip2bus_data_i         ( ip2bus_data  ) 
  );
  
  registers_stub registers_stub(
    .bus2ip_clk            (bus2ip_clk     ) ,
    .bus2ip_rst_n          (bus2ip_rst_n   ) ,
    .bus2ip_addr_i         (bus2ip_addr  ) ,
    .bus2ip_data_i         (bus2ip_data  ) ,
    .bus2ip_rd_ce_i        (bus2ip_rd_ce ) ,
    .bus2ip_wr_ce_i        (bus2ip_wr_ce ) ,
    .ip2bus_data_o         (ip2bus_data  )  
  );

endmodule
