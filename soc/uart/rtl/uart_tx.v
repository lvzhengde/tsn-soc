/*+
 * Copyright (c) 2022-2024 Zhengde
 * 
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1 Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 * 
 * 2 Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * 
 * 3 Neither the name of the copyright holder nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-*/

/*+
 *  Description : uart transmitter top level
 *  File        : uart_tx.v
-*/

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
