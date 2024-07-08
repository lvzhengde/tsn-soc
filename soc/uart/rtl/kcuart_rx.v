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
 *  Description : constant compact uart receiver
 *  File        : kcuart_rx.v
-*/

module kcuart_rx(
    input            clk    ,
    input            rst_n  ,      //active low reset
                                    
    input            msb_first_i      ,   //0: lsb first; 1: msb first  
    input            parity_en_i      ,   //0: no parity; 1: has parity
    input            start_polarity_i ,   //0: low start bit, high stop bit; 1: high start bit, low stop bit 

    input            en_16x_baud_i ,
    input            serial_in_i   ,
  
    output reg [7:0] data_out_o  ,
    output reg       data_strobe_o      
);

    wire [3:0] bit_count_p1;
    reg  [3:0] bit_count;
    wire [3:0] baud_count_p1;
    reg  [3:0] baud_count;
    reg        serial_in_d1, serial_in_d2, serial_in_d3;

    wire       calculated_parity;
    reg        start_bit, stop_bit;
    wire       mismatch_parity;
    reg  [8:0] received_data;
    wire [7:0] par_data;

    reg        rx_active;
    reg        stop_condtion;
    wire       break_condition;

    wire       start_polarity = start_polarity_i;
    wire       stop_polarity = ~start_polarity;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            {serial_in_d1, serial_in_d2, serial_in_d3} <= 3'b0;
        else
            {serial_in_d1, serial_in_d2, serial_in_d3} <= {serial_in_i, serial_in_d1, serial_in_d2};
    end

    wire   serial_negedge = (serial_in_d2 == 1'b0 && serial_in_d3 == 1'b1);
    wire   serial_posedge = (serial_in_d2 == 1'b1 && serial_in_d3 == 1'b0);

    wire   start_condition = (start_polarity == 1'b0) ? (serial_negedge == 1'b1 && bit_count[3:0] == 4'd0 && rx_active == 1'b0)
                                                    : (serial_posedge == 1'b1 && bit_count[3:0] == 4'd0 && rx_active == 1'b0);    

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            rx_active <= 1'b0;
        else if(start_condition == 1'b1)
            rx_active <= 1'b1;
        else if(bit_count == 4'd1 && start_bit != start_polarity)  //invalid start bit
            rx_active <= 1'b0;
        else if(stop_condtion == 1'b1)
            rx_active <= 1'b0;
    end
  
    //count bit cycles
    assign baud_count_p1 = baud_count + 1;
  
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            baud_count <= 4'd0;
        else if(en_16x_baud_i == 1'b1 && rx_active == 1'b1)
            baud_count <= baud_count_p1;
        else if(rx_active == 1'b0)
            baud_count <= 4'd0;
    end

    //count bit numbers
    wire [3:0] bit_num = (parity_en_i == 1'b0) ? 10 : 11;
    assign bit_count_p1 = bit_count + 1;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            bit_count <= 4'd0;
        else if(en_16x_baud_i == 1'b1 && baud_count == 4'd15 && rx_active == 1'b1) begin
            if(bit_count < (bit_num - 1))
                bit_count <= bit_count_p1;
            else if(bit_count >= (bit_num - 1))
                bit_count <= 4'd0;
        end
        else if(rx_active == 1'b0)
            bit_count <= 4'd0;
    end
  
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            stop_condtion <= 0;
        else 
            stop_condtion <= (baud_count == 4'd8 && bit_count == (bit_num - 1) && en_16x_baud_i == 1'b1) ? 1 : 0; 
    end

    //sample uart data input to parallel data 
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            received_data <= 9'h0;
            start_bit     <= 1'b1;
            stop_bit      <= 1'b1;
        end
        else if(en_16x_baud_i == 1'b1 && baud_count == 4'd8 && rx_active == 1'b1) begin
            case(bit_count)
                4'd0:  start_bit        <= serial_in_d3 ; //start bit, falling edge
                4'd1:  received_data[0] <= serial_in_d3 ;
                4'd2:  received_data[1] <= serial_in_d3 ;
                4'd3:  received_data[2] <= serial_in_d3 ;
                4'd4:  received_data[3] <= serial_in_d3 ;
                4'd5:  received_data[4] <= serial_in_d3 ;
                4'd6:  received_data[5] <= serial_in_d3 ;
                4'd7:  received_data[6] <= serial_in_d3 ;
                4'd8:  received_data[7] <= serial_in_d3 ;
                4'd9:  
                    if(parity_en_i == 1'b1)
                        received_data[8] <= serial_in_d3 ; 
                    else
                        stop_bit         <= serial_in_d3 ;
                4'd10: 
                    if(parity_en_i == 1'b1)
                        stop_bit <= serial_in_d3 ;
            endcase
        end
        else if(rx_active == 1'b0) begin
            received_data <= 9'h0;
            start_bit     <= start_polarity;
            stop_bit      <= stop_polarity;
        end
    end

    assign break_condition = (stop_bit != stop_polarity && bit_count == (bit_num - 1)) ? 1 : 0;

    assign par_data[7:0] = (msb_first_i == 1'b0) ? received_data[7:0] : {received_data[0], received_data[1], received_data[2],
                             received_data[3], received_data[4], received_data[5], received_data[6], received_data[7]};

    assign calculated_parity = ^received_data[7:0];

    assign mismatch_parity = (parity_en_i == 1'b1 && calculated_parity != received_data[8]) ? 1'b1 : 1'b0;

    //output data to RX buffer
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            data_strobe_o <= 1'b0;
        else 
            data_strobe_o <= (stop_condtion == 1'b1 && break_condition == 1'b0 && mismatch_parity == 1'b0);
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            data_out_o <= 8'h0;
        else if(stop_condtion == 1'b1)
            data_out_o <= par_data[7:0];
    end
endmodule
