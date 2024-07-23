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
 *  Description : uart configuration and status registers.
 *  File        : uart_registers.v
-*/

module uart_registers (
    input           clk     ,
    input           rst_n   ,      

    //program download setting
    input           uart_mst_i  ,    
    output          reset_cpu_o ,

    //register access interface
    input  [31:0]   waddr_i , 
    input  [31:0]   wdata_i , 
    input  [ 3:0]   wstrb_i , 
    input           wen_i   , 
    input  [31:0]   raddr_i , 
    output [31:0]   rdata_o , 
    input  [ 3:0]   rstrb_i ,
    input           ren_i   ,        

    //fifo status signals
    input           rx_buffer_data_present_i ,
    input           rx_buffer_full_i   ,
    input           rx_buffer_hfull_i  ,
    input           rx_buffer_afull_i  ,
    input           rx_buffer_aempty_i ,

    input           tx_buffer_full_i  ,
    input           tx_buffer_hfull_i ,
    input           tx_buffer_afull_i ,
    input           tx_buffer_aempty_i,

    //configurations
    output          parity_en_o     ,  //0: no parity; 1: has parity
    output          msb_first_o     ,  //0: lsb first; 1: msb first           
    output          start_polarity_o,  //0: low level start bit, high level stop bit; 1: high level start bit, low level stop bit;
    output          reset_buffer_o  ,  //reset uart fifo, active high
    output [15:0]   baud_config_o   ,

    // uart access interface for AXI4 slave
    input  [ 7:0]   slv_rdata_i ,
    output          slv_read_o  ,
    output [ 7:0]   slv_wdata_o ,
    output          slv_write_o 
);
    parameter BASEADDR   = 24'h90_0000 ;
    parameter CLK_FREQ   = 100000000   ;  //100MHz
    parameter UART_SPEED = 115200      ;  //Baud rate
    parameter BAUD_CFG   = CLK_FREQ/(16*UART_SPEED);

    reg           parity_en_q     ;  
    reg           msb_first_q     ;  
    reg           start_polarity_q;  
    reg           reset_buffer_q  ;  
    reg  [15:0]   baud_config_q   ;

    reg           slv_read    ;
    reg  [ 7:0]   slv_wdata_q ;
    reg           slv_write_q ;

    reg           reset_cpu_q ;

    //read operation
    wire [31:0] rmask_w = {{8{rstrb_i[3]}}, {8{rstrb_i[2]}}, {8{rstrb_i[1]}}, {8{rstrb_i[0]}}};

    reg  [31:0] rdata   ;
    reg  [31:0] rdata_q ;

    always @(*) begin
        rdata[31:0] = 32'h0;
        slv_read    = 1'b0 ;

        if (ren_i == 1'b1 && raddr_i[31:8] == BASEADDR) begin
          case (raddr_i[7:0])
            8'h00:    
                rdata[31:0] = {16'h0, baud_config_q[15:0]}; 
            8'h04:    
                rdata[31:0] = {29'b0, parity_en_q, msb_first_q, start_polarity_q};
            8'h08:    
                rdata[31:0] = {23'b0, rx_buffer_data_present_i, rx_buffer_full_i, rx_buffer_hfull_i,
                               rx_buffer_afull_i, rx_buffer_aempty_i, tx_buffer_full_i, 
                               tx_buffer_hfull_i, tx_buffer_afull_i, tx_buffer_aempty_i};
            8'h0c:    
                rdata[31:0] = {24'h0, slv_wdata_q[7:0]};  //uart write data
            8'h10:    
            begin
                rdata[31:0] = {19'h0, rx_buffer_data_present_i, rx_buffer_full_i, rx_buffer_hfull_i,
                               rx_buffer_afull_i, rx_buffer_aempty_i, slv_rdata_i[7:0]};  //uart read data with status info
                slv_read    = 1'b1;
            end
            8'h14:
                rdata[31:0] = {30'h0, uart_mst_i, reset_cpu_q};
            default:  
                rdata[31:0] = 32'h0;
          endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            rdata_q <= 32'h0;
        else
            rdata_q <= rdata_o;
    end

    assign rdata_o    = (ren_i == 1'b1) ? (rdata & rmask_w) : rdata_q; //no delay and skid buffer
    assign slv_read_o = slv_read;

    //write operation
    wire [31:0] wmask_w = {{8{wstrb_i[3]}}, {8{wstrb_i[2]}}, {8{wstrb_i[1]}}, {8{wstrb_i[0]}}};
    reg  [31:0] pre_data;

    always @(*) begin
        case (waddr_i[7:0])
            8'h00 :    
                pre_data[31:0] = {16'h0, baud_config_q[15:0]}; 
            8'h04 :    
                pre_data[31:0] = {29'b0, parity_en_q, msb_first_q, start_polarity_q};
            8'h0c :    
                pre_data[31:0] = {24'h0, slv_wdata_q[7:0]};  //uart write data
            8'h14:
                pre_data[31:0] = {30'h0, uart_mst_i, reset_cpu_q};
            default:  
                pre_data[31:0] = 32'h0;
        endcase
    end

    wire  [31:0] wdata = (pre_data & (~wmask_w)) | (wdata_i & wmask_w);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_config_q[15:0] <= BAUD_CFG;         
            parity_en_q         <= 1'b0;
            msb_first_q         <= 1'b0;
            start_polarity_q    <= 1'b0;
            reset_cpu_q         <= 1'b0;
            reset_buffer_q      <= 1'b0;
        end
        else if (wen_i == 1'b1 && waddr_i[31:8] == BASEADDR) begin
            case (waddr_i[7:0])
                8'h00:   
                    baud_config_q[15:0] <= wdata[15:0];
                8'h04:   
                    {parity_en_q, msb_first_q, start_polarity_q} <= wdata[2:0] ;
                8'h0c:
                begin
                    slv_wdata_q[7:0] <= wdata[7:0];
                    slv_write_q      <= 1'b1      ;
                end
                8'h14:
                    reset_cpu_q      <= (uart_mst_i) ? wdata[1] : 1'b0;
                8'h20:   
                    reset_buffer_q   <= wdata[0]  ;
                default: 
                    ;
            endcase
        end
        else begin
            slv_write_q    <= 1'b0 ;
            reset_buffer_q <= 1'b0 ;
        end
    end

    //outputs
    assign slv_write_o = slv_write_q;
    assign slv_wdata_o = slv_wdata_q;

    assign parity_en_o      = parity_en_q      ;  
    assign msb_first_o      = msb_first_q      ;  
    assign start_polarity_o = start_polarity_q ;  
    assign baud_config_o    = baud_config_q    ;
    assign reset_cpu_o      = reset_cpu_q      ;
    assign reset_buffer_o   = reset_buffer_q   ;

endmodule
