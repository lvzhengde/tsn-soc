/*++
//  Description : uart receiver top level
//  File        : uart_rx.v
--*/

`timescale 1ns/10fs

module uart_rx(
  input          clk      ,
  input          rst_n    ,      //active low reset
                                       
  input          msb_first_i       ,      //0: lsb first; 1: msb first   
  input          parity_en_i       ,      //0: no parity; 1: has parity
  input          start_polarity_i  ,      //0: low start bit, high stop bit; 1: high start bit, low stop bit
                                       
  input          serial_in_i       ,
  output [7:0]   data_out_o        ,
  input          read_buffer_i     ,
  input          reset_buffer_i    ,                     
  input          en_16x_baud_i    ,
                                     
  output         buffer_data_present_o ,
  output         buffer_full_o         ,
  output         buffer_hfull_o    ,
  output         buffer_afull_o,
  output         buffer_aempty_o    
);

  wire  reset_buffer_n = rst_n & (~reset_buffer_i);
  wire  [7:0] rx_data;
  wire  data_strobe;

  bbfifo_16x8 bbfifo_16x8(
    .clk              (clk),
    .rst_n            (reset_buffer_n),      
                      
    .read_i           (read_buffer_i),      
    .write_i          (data_strobe),      
    .data_in_i        (rx_data),
                      
    .data_out_o       (data_out_o ),    
    .data_present_o   (buffer_data_present_o),
    .full_o           (buffer_full_o),
    .hfull_o          (buffer_hfull_o),
    .afull_o          (buffer_afull_o),
    .aempty_o         (buffer_aempty_o)    
  );                                

  kcuart_rx kcuart_rx(
    .clk              (clk)    ,
    .rst_n            (rst_n)  ,    
                   
    .parity_en_i      (parity_en_i),    
    .msb_first_i      (msb_first_i),                          
    .start_polarity_i (start_polarity_i),
                   
    .serial_in_i      (serial_in_i ),
    .en_16x_baud_i    (en_16x_baud_i ),
    
    .data_out_o       (rx_data ),
    .data_strobe_o    (data_strobe )  
  );
    
endmodule
