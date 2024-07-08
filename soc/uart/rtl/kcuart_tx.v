/*++
//  Description : constant compact uart transmitter
//  File        : kcuart_tx.v
--*/

`timescale 1ns/10fs

module kcuart_tx(
  input          clk     ,
  input          rst_n   ,      //active low reset
                                
  input          msb_first_i      ,    //0: lsb first; 1: msb first                        
  input          parity_en_i      ,    //0: no parity; 1: has parity
  input          start_polarity_i ,    //0: low start bit, high stop bit; 1: high start bit, low stop bit 
                                
  input  [7:0]   data_in_i        ,
  input          send_character_i ,
  input          en_16x_baud_i   ,
  
  output reg     serial_out_o     ,
  output reg     tx_complete_o      
);
  wire [3:0]      bit_count_p1;
  reg  [3:0]      bit_count;
  wire [3:0]      baud_count_p1;
  reg  [3:0]      baud_count;

  wire       start_polarity = start_polarity_i;
  wire       stop_polarity = ~start_polarity;

  //count bit cycles
  assign baud_count_p1 = baud_count + 1;
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      baud_count <= 4'd0;
    else if(send_character_i == 1'b0)
      baud_count <= 4'd0;
    else if(en_16x_baud_i == 1'b1)
      baud_count <= baud_count_p1;
  end

  //count bit numbers
  wire [3:0] bit_num = (parity_en_i == 1'b0) ? 10 : 11;
  assign bit_count_p1 = bit_count + 1;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      bit_count <= 4'd0;
    else if(en_16x_baud_i == 1'b1 && baud_count == 4'd15) begin
      if(bit_count < (bit_num - 1) && send_character_i == 1'b1)
        bit_count <= bit_count_p1;
      else if(send_character_i == 1'b0 || bit_count >= (bit_num - 1))
        bit_count <= 4'd0;
    end
  end
  
  //put serial data out
  wire         parity_bit = ^data_in_i[7:0];
  wire [8:0]   data_sent = (msb_first_i == 1'b0) ? {parity_bit, data_in_i[7:0]} : {parity_bit, data_in_i[0], data_in_i[1],
                                  data_in_i[2], data_in_i[3], data_in_i[4], data_in_i[5], data_in_i[6], data_in_i[7]};

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      serial_out_o <= 1'b1;
    else if(en_16x_baud_i == 1'b1) begin
      if(baud_count == 4'b0 && send_character_i == 1'b1) 
        case(bit_count)
          4'd0:  serial_out_o <= start_polarity; //start bit
          4'd1:  serial_out_o <= data_sent[0];
          4'd2:  serial_out_o <= data_sent[1];
          4'd3:  serial_out_o <= data_sent[2];
          4'd4:  serial_out_o <= data_sent[3];
          4'd5:  serial_out_o <= data_sent[4];
          4'd6:  serial_out_o <= data_sent[5];
          4'd7:  serial_out_o <= data_sent[6];
          4'd8:  serial_out_o <= data_sent[7];
          4'd9:  
            if(parity_en_i == 1'b1) 
              serial_out_o <= data_sent[8];
            else
              serial_out_o <= stop_polarity;   //stop bit
          default: serial_out_o <= stop_polarity;
        endcase
      else if(send_character_i == 1'b0)
        serial_out_o <= stop_polarity;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      tx_complete_o <= 1'b0;
    else if(en_16x_baud_i == 1'b1) begin
      if(bit_count == (bit_num - 1) && baud_count == 4'd15)
        tx_complete_o <= 1'b1;
      else
        tx_complete_o <= 1'b0;
    end
    else
      tx_complete_o <= 1'b0;
  end
endmodule
