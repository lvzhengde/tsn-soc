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

`include "uart_defines.v"

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

    //uart access interface for AXI4 slave
    input  [ 7:0]   slv_rdata_i ,
    output          slv_read_o  ,
    output [ 7:0]   slv_wdata_o ,
    output          slv_write_o ,

    //interrupt output
    output          intr_o     
);
    parameter CLK_FREQ   = 100000000   ;  //100MHz
    parameter UART_SPEED = 115200      ;  //Baud rate
    parameter BAUD_CFG   = CLK_FREQ/(16*UART_SPEED);

    wire uart_wr_sel_w = ((waddr_i & `UART_ADDR_MASK) == `UART_BASEADDR);
    wire uart_rd_sel_w = ((raddr_i & `UART_ADDR_MASK) == `UART_BASEADDR);

    //-----------------------------------------------------------------
    // Baud Rate Config Register
    //-----------------------------------------------------------------
    wire baud_wr_sel_w = (waddr_i[7:0] == `UART_BAUD) & uart_wr_sel_w;  
    reg  [15:0]   baud_config_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            baud_config_q <= BAUD_CFG;
        else if (wen_i & baud_wr_sel_w) begin
           if (wstrb_i[0]) baud_config_q[ 7: 0] <= wdata_i[ 7: 0];
           if (wstrb_i[1]) baud_config_q[15: 8] <= wdata_i[15: 8];
        end
    end 

    //-----------------------------------------------------------------
    // UART Control Register
    //-----------------------------------------------------------------
    wire ctrl_wr_sel_w = (waddr_i[7:0] == `UART_CONTROL) & uart_wr_sel_w;

    reg           parity_en_q     ;  
    reg           msb_first_q     ;  
    reg           start_polarity_q;  

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            {parity_en_q, msb_first_q, start_polarity_q} <= 3'b0;
        else if (wen_i & ctrl_wr_sel_w & wstrb_i[0]) 
            {parity_en_q, msb_first_q, start_polarity_q} <= wdata_i[2:0] ;
    end 

    //-----------------------------------------------------------------
    // AXI Slave UART TX DATA Register
    //-----------------------------------------------------------------
    wire txd_wr_sel_w = (waddr_i[7:0] == `UART_TXDATA) & uart_wr_sel_w;

    reg  [ 7:0]   slv_wdata_q ;
    reg           slv_write_q ;

    // write signal auto clear
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slv_wdata_q[7:0] <= 8'h0;
            slv_write_q      <= 1'b0      ;
        end
        else if (wen_i & txd_wr_sel_w & wstrb_i[0]) begin
            slv_wdata_q[7:0] <= wdata_i[7:0];
            slv_write_q      <= 1'b1      ;
        end
        else begin
            slv_write_q      <= 1'b0      ;
        end
    end 

    //-----------------------------------------------------------------
    // AXI Master Reset CPU Register
    //-----------------------------------------------------------------
    wire rstcpu_wr_sel_w = (waddr_i[7:0] == `UART_RSTCPU) & uart_wr_sel_w;

    reg           reset_cpu_q ;

    // Maintain the signal until the next write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            reset_cpu_q <= 1'b0;
        else if (wen_i & rstcpu_wr_sel_w & wstrb_i[0]) 
            reset_cpu_q <= (uart_mst_i) ? wdata_i[1] : 1'b0;
    end 

    //-----------------------------------------------------------------
    // Reset TX/RX Buffer Register
    //-----------------------------------------------------------------
    wire rstbuf_wr_sel_w = (waddr_i[7:0] == `UART_RSTBUF) & uart_wr_sel_w;

    reg           reset_buffer_q  ;  

    // Auto clear
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            reset_buffer_q <= 1'b0;
        else if (wen_i & rstbuf_wr_sel_w & wstrb_i[0]) 
            reset_buffer_q <= wdata_i[0];
        else
            reset_buffer_q <= 1'b0;
    end 

    //-----------------------------------------------------------------
    // UART Interrupt Status Register (read/write 1 clear)
    //-----------------------------------------------------------------
    wire isr_wr_sel_w = (waddr_i[7:0] == `UART_ISR) & uart_wr_sel_w;

    reg  isr_rx_present_q;
    reg  isr_tx_full_q  ; 

    reg  rx_present_d1;
    reg  tx_full_d1; 

    always @(posedge clk) rx_present_d1 <= rx_buffer_data_present_i;
    always @(posedge clk) tx_full_d1    <= tx_buffer_full_i;

    wire rx_present_int_w = rx_buffer_data_present_i & (~rx_present_d1);
    wire tx_full_int_w    = tx_buffer_full_i & (~tx_full_d1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            isr_rx_present_q <= 1'b0;
            isr_tx_full_q    <= 1'b0; 
        end
        else if (wen_i & isr_wr_sel_w & wstrb_i[0]) begin //write 1 clear
            if (wdata_i[0]) isr_rx_present_q <= 1'b0;
            if (wdata_i[1]) isr_tx_full_q    <= 1'b0;
        end 
        else begin
            if (rx_present_int_w) isr_rx_present_q <= 1'b1;
            if (tx_full_int_w   ) isr_tx_full_q    <= 1'b1;
        end
    end 

    //-----------------------------------------------------------------
    // UART Interrupt Enable Register (read/write 1 clear)
    //-----------------------------------------------------------------
    wire ier_wr_sel_w = (waddr_i[7:0] == `UART_IER) & uart_wr_sel_w;

    reg  ier_rx_present_q;
    reg  ier_tx_full_q  ; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ier_rx_present_q <= 1'b0;
            ier_tx_full_q    <= 1'b0; 
        end
        else if (wen_i & ier_wr_sel_w & wstrb_i[0]) begin //write 1 clear
            ier_rx_present_q <= wdata_i[0];
            ier_tx_full_q    <= wdata_i[1]; 
        end 
    end 

    //-----------------------------------------------------------------
    // Read Mux
    //-----------------------------------------------------------------
    reg           slv_read    ;

    wire [31:0] rmask_w = {{8{rstrb_i[3]}}, {8{rstrb_i[2]}}, {8{rstrb_i[1]}}, {8{rstrb_i[0]}}};

    reg  [31:0] rdata   ;
    reg  [31:0] rdata_q ;

    always @(*) begin
        rdata[31:0] = 32'h0;
        slv_read    = 1'b0 ;

        if (ren_i & uart_rd_sel_w) begin
          case (raddr_i[7:0])
            `UART_BAUD :    
                rdata[31:0] = {16'h0, baud_config_q[15:0]}; 
            `UART_CONTROL :    
                rdata[31:0] = {29'b0, parity_en_q, msb_first_q, start_polarity_q};
            `UART_STATUS :    
                rdata[31:0] = {23'b0, rx_buffer_data_present_i, rx_buffer_full_i, rx_buffer_hfull_i,
                               rx_buffer_afull_i, rx_buffer_aempty_i, tx_buffer_full_i, 
                               tx_buffer_hfull_i, tx_buffer_afull_i, tx_buffer_aempty_i};
            `UART_TXDATA :    
                rdata[31:0] = {24'h0, slv_wdata_q[7:0]};  //uart write data
            `UART_RXDATA :    
            begin
                rdata[31:0] = {19'h0, rx_buffer_data_present_i, rx_buffer_full_i, rx_buffer_hfull_i,
                               rx_buffer_afull_i, rx_buffer_aempty_i, slv_rdata_i[7:0]};  //uart read data with status info
                slv_read    = 1'b1;
            end
            `UART_RSTCPU :
                rdata[31:0] = {30'h0, uart_mst_i, reset_cpu_q};
            `UART_IER :
                rdata[31:0] = {30'h0, ier_tx_full_q, ier_rx_present_q};
            `UART_ISR :
                rdata[31:0] = {30'h0, isr_tx_full_q, isr_rx_present_q};
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

    //-----------------------------------------------------------------
    // Outputs
    //-----------------------------------------------------------------
    assign rdata_o     = (ren_i == 1'b1) ? (rdata & rmask_w) : rdata_q; //no delay and skid buffer
    assign slv_read_o  = slv_read;
    assign slv_write_o = slv_write_q;
    assign slv_wdata_o = slv_wdata_q;

    assign parity_en_o      = parity_en_q      ;  
    assign msb_first_o      = msb_first_q      ;  
    assign start_polarity_o = start_polarity_q ;  
    assign baud_config_o    = baud_config_q    ;
    assign reset_cpu_o      = reset_cpu_q      ;
    assign reset_buffer_o   = reset_buffer_q   ;

    // Interrupt request output
    assign intr_o = (ier_rx_present_q & isr_rx_present_q) | (ier_tx_full_q & isr_tx_full_q);    

endmodule
