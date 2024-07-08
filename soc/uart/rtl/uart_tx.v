/*++
//  Description : uart transmitter top level
//  File        : uart_tx.v
--*/

`timescale 1ns/10fs

module uart_tx(
  input          clk      ,
  input          rst_n    ,      //active low reset
                                     
  input          msb_first_i       ,   //0: lsb first; 1: msb first                        
  input          parity_en_i       ,   //0: no parity; 1: has parity
  input          start_polarity_i  ,   //0: low start bit, high stop bit; 1: high start bit, low stop bit 
                                     
  input  [7:0]   data_in_i         ,
  input          write_buffer_i    ,      //active high
  input          reset_buffer_i    ,      //active high
  input          en_16x_baud_i    ,
                                     
  output         serial_out_o        ,
  output         buffer_full_o       ,
  output         buffer_hfull_o  ,
  output         buffer_afull_o,
  output         buffer_aempty_o  
);

  wire  reset_buffer_n = rst_n & (~reset_buffer_i);
  wire  tx_complete;
  wire  data_present;
  wire  [7:0] fifo_dout;

  bbfifo_16x8 bbfifo_16x8(
    .clk              (clk),
    .rst_n            (reset_buffer_n),      
                      
    .read_i           (tx_complete),      
    .write_i          (write_buffer_i),      
    .data_in_i        (data_in_i),
                      
    .data_out_o       (fifo_dout),    
    .data_present_o   (data_present),
    .full_o           (buffer_full_o),
    .hfull_o          (buffer_hfull_o),
    .afull_o          (buffer_afull_o),
    .aempty_o         (buffer_aempty_o)
  );                                
  
  kcuart_tx kcuart_tx(
    .clk              (clk),
    .rst_n            (rst_n),    
                   
    .parity_en_i      (parity_en_i),    
    .msb_first_i      (msb_first_i),                          
    .start_polarity_i (start_polarity_i),
                   
    .data_in_i        (fifo_dout),
    .send_character_i (data_present),
    .en_16x_baud_i    (en_16x_baud_i),
    
    .serial_out_o     (serial_out_o),
    .tx_complete_o    (tx_complete)  
  );
endmodule
