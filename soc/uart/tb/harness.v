/*++
//  Description  : uart test harness
//  File         : harness.v  
--*/

`timescale 1ns/10fs

module harness;  

  wire          ser_host2device;
  wire          ser_device2host;

  uart_device uart_device(
    .serial_in_i  (ser_host2device  ),
    .serial_out_o (ser_device2host )   
  ); 

  uart_host uart_host(
    .serial_in_i  (ser_device2host ),
    .serial_out_o (ser_host2device )  
  );  

endmodule
