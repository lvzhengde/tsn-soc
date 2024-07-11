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
 *  Description : uart top level, include uart transmitter/receiver
 *                and AXI4 bus Master / Slave.
 *  File        : uart_top.v
-*/

module uart_top (
    input           clk     ,
    input           rst_n   ,      

    // uart interface
    input           uart_mst_i ,    //0: Normal slave operation, 1: UART as AXI4 bus master 
    input           uart_rxd_i ,
    output          uart_txd_o ,  
    output          intr_o     ,

    // AXI4 bus master interface
    output          mst_awvalid_o ,  
    output [ 31:0]  mst_awaddr_o  ,   
    output [  3:0]  mst_awid_o    ,   
    output [  7:0]  mst_awlen_o   ,   
    output [  1:0]  mst_awburst_o ,  
    output          mst_wvalid_o  ,   
    output [ 31:0]  mst_wdata_o   ,  
    output [  3:0]  mst_wstrb_o   ,  
    output          mst_wlast_o   ,  
    output          mst_bready_o  ,   
    output          mst_arvalid_o ,    
    output [ 31:0]  mst_araddr_o  ,   
    output [  3:0]  mst_arid_o    ,   
    output [  7:0]  mst_arlen_o   ,  
    output [  1:0]  mst_arburst_o ,    
    output          mst_rready_o  ,   

    input           mst_awready_i ,   
    input           mst_wready_i  ,  
    input           mst_bvalid_i  ,  
    input  [  1:0]  mst_bresp_i   , 
    input  [  3:0]  mst_bid_i     ,
    input           mst_arready_i ,   
    input           mst_rvalid_i  ,  
    input  [ 31:0]  mst_rdata_i   , 
    input  [  1:0]  mst_rresp_i   , 
    input  [  3:0]  mst_rid_i     , 
    input           mst_rlast_i   , 

    // AXI4 bus slave interface
    input           slv_awvalid_i ,
    input  [ 31:0]  slv_awaddr_i  ,
    input  [  3:0]  slv_awid_i    ,
    input  [  7:0]  slv_awlen_i   ,
    input  [  1:0]  slv_awburst_i ,
    input           slv_wvalid_i  ,
    input  [ 31:0]  slv_wdata_i   ,
    input  [  3:0]  slv_wstrb_i   ,
    input           slv_wlast_i   ,
    input           slv_bready_i  ,
    input           slv_arvalid_i ,
    input  [ 31:0]  slv_araddr_i  ,
    input  [  3:0]  slv_arid_i    ,
    input  [  7:0]  slv_arlen_i   ,
    input  [  1:0]  slv_arburst_i ,
    input           slv_rready_i  ,

    output          slv_awready_o ,
    output          slv_wready_o  ,
    output          slv_bvalid_o  ,
    output [  1:0]  slv_bresp_o   ,
    output [  3:0]  slv_bid_o     ,
    output          slv_arready_o ,
    output          slv_rvalid_o  ,
    output [ 31:0]  slv_rdata_o   ,
    output [  1:0]  slv_rresp_o   ,
    output [  3:0]  slv_rid_o     ,
    output          slv_rlast_o   
);
    wire          parity_en_w     ; 
    wire          msb_first_w     ; 
    wire          start_polarity_w;

    wire          en_16x_baud_w   ;
    wire          reset_buffer_w  ;

    wire [ 7:0]   rx_data_out_w           ;
    wire          rx_read_buffer_w        ;
    wire          rx_buffer_data_present_w;
    wire          rx_buffer_full_w        ;
    wire          rx_buffer_hfull_w       ;
    wire          rx_buffer_afull_w       ;
    wire          rx_buffer_aempty_w      ;  

    wire  [ 7:0]  tx_data_in_w       ; 
    wire          tx_write_buffer_w  ; 
    wire          tx_buffer_full_w   ; 
    wire          tx_buffer_hfull_w  ;
    wire          tx_buffer_afull_w  ;
    wire          tx_buffer_aempty_w ; 

    wire  [15:0]  baud_config_w  ;


    uart_rx uart_rx 
    (
        .clk                   (clk   ),
        .rst_n                 (rst_n ),     
                              
        .parity_en_i           (parity_en_w      ),     
        .msb_first_i           (msb_first_w      ),     
        .start_polarity_i      (start_polarity_w ),
                              
        .serial_in_i           (uart_rxd_i       ),
        .data_out_o            (rx_data_out_w    ),
        .read_buffer_i         (rx_read_buffer_w ),
        .reset_buffer_i        (reset_buffer_w   ),                     
        .en_16x_baud_i         (en_16x_baud_w    ),
                            
        .buffer_data_present_o (rx_buffer_data_present_w ),
        .buffer_full_o         (rx_buffer_full_w         ),
        .buffer_hfull_o        (rx_buffer_hfull_w        ),
        .buffer_afull_o        (rx_buffer_afull_w        ),
        .buffer_aempty_o       (rx_buffer_aempty_w       )     
    );


    uart_tx uart_tx 
    (
        .clk                   (clk   ) , 
        .rst_n                 (rst_n ) , 
                                
        .parity_en_i           (parity_en_w      ) , 
        .msb_first_i           (msb_first_w      ) , 
        .start_polarity_i      (start_polarity_w ) ,
                                
        .data_in_i             (tx_data_in_w      ) , 
        .write_buffer_i        (tx_write_buffer_w ) , 
        .reset_buffer_i        (reset_buffer_w    ) , 
        .en_16x_baud_i         (en_16x_baud_w     ) , 
                                
        .serial_out_o          (uart_txd_o         ) , 
        .buffer_full_o         (tx_buffer_full_w   ) , 
        .buffer_hfull_o        (tx_buffer_hfull_w  ) ,
        .buffer_afull_o        (tx_buffer_afull_w  ) ,
        .buffer_aempty_o       (tx_buffer_aempty_w )         
    );


    baud_generator  baud_generator 
    (
        .clk                   (clk  )  ,
        .rst_n                 (rst_n)  ,
                               
        .baud_config_i         (baud_config_w )  ,
        .en_16x_baud_o         (en_16x_baud_w )
    );


    wire  [31:0]   waddr_w ; 
    wire  [31:0]   wdata_w ; 
    wire  [ 3:0]   wstrb_w ; 
    wire           wen_w   ; 
    wire  [31:0]   raddr_w ; 
    wire  [31:0]   rdata_w ; 
    wire  [ 3:0]   rstrb_w ;
    wire           ren_w   ;        
    
    wire  [ 7:0]   slv_rdata_w ;
    wire           slv_read_w  ;
    wire  [ 7:0]   slv_wdata_w ;
    wire           slv_write_w ;

      
    uart_registers  uart_registers 
    (
        .clk                      (clk    ),
        .rst_n                    (rst_n  ),              

        //register access interface
        .waddr_i                  (waddr_w ),
        .wdata_i                  (wdata_w ),
        .wstrb_i                  (wstrb_w ),
        .wen_i                    (wen_w   ),
        .raddr_i                  (raddr_w ),
        .rdata_o                  (rdata_w ),
        .rstrb_i                  (rstrb_w ),
        .ren_i                    (ren_w   ),
        
        //fifo status signals
        .rx_buffer_data_present_i (rx_buffer_data_present_w  ) ,
        .rx_buffer_full_i         (rx_buffer_full_w          ) ,
        .rx_buffer_hfull_i        (rx_buffer_hfull_w         ) ,
        .rx_buffer_afull_i        (rx_buffer_afull_w         ) ,
        .rx_buffer_aempty_i       (rx_buffer_aempty_w        ) ,    
                                                            
        .tx_buffer_full_i         (tx_buffer_full_w   ) ,
        .tx_buffer_hfull_i        (tx_buffer_hfull_w  ) ,
        .tx_buffer_afull_i        (tx_buffer_afull_w  ) ,
        .tx_buffer_aempty_i       (tx_buffer_aempty_w ) ,   
        
        //global configurations
        .parity_en_o              (parity_en_w      ) ,     
        .msb_first_o              (msb_first_w      ) ,    
        .start_polarity_o         (start_polarity_w ) ,
        .reset_buffer_o           (reset_buffer_w   ) ,   
        .baud_config_o            (baud_config_w    ) ,

        // uart access interface for AXI4 slave
        .slv_rdata_i              (slv_rdata_w ),
        .slv_read_o               (slv_read_w  ),
        .slv_wdata_o              (slv_wdata_w ),
        .slv_write_o              (slv_write_w )
    );

    uart_axi_slv uart_axi_slv 
    (
        .clk                   (clk   ),
        .rst_n                 (rst_n ),     

        // AXI4 bus slave interface
        .axi_awvalid_i         (slv_awvalid_i),
        .axi_awaddr_i          (slv_awaddr_i ),
        .axi_awid_i            (slv_awid_i   ),
        .axi_awlen_i           (slv_awlen_i  ),
        .axi_awburst_i         (slv_awburst_i),
        .axi_wvalid_i          (slv_wvalid_i ),
        .axi_wdata_i           (slv_wdata_i  ),
        .axi_wstrb_i           (slv_wstrb_i  ),
        .axi_wlast_i           (slv_wlast_i  ),
        .axi_bready_i          (slv_bready_i ),
        .axi_arvalid_i         (slv_arvalid_i),
        .axi_araddr_i          (slv_araddr_i ),
        .axi_arid_i            (slv_arid_i   ),
        .axi_arlen_i           (slv_arlen_i  ),
        .axi_arburst_i         (slv_arburst_i),
        .axi_rready_i          (slv_rready_i ),

        .axi_awready_o         (slv_awready_o),
        .axi_wready_o          (slv_wready_o ),
        .axi_bvalid_o          (slv_bvalid_o ),
        .axi_bresp_o           (slv_bresp_o  ),
        .axi_bid_o             (slv_bid_o    ),
        .axi_arready_o         (slv_arready_o),
        .axi_rvalid_o          (slv_rvalid_o ),
        .axi_rdata_o           (slv_rdata_o  ),
        .axi_rresp_o           (slv_rresp_o  ),
        .axi_rid_o             (slv_rid_o    ),
        .axi_rlast_o           (slv_rlast_o  ),

        //register access interface
        .waddr_o               (waddr_w   ),
        .wdata_o               (wdata_w   ),
        .wstrb_o               (wstrb_w   ),
        .wen_o                 (wen_w     ),
        .raddr_o               (raddr_w   ),
        .rdata_i               (rdata_w   ),
        .rstrb_o               (rstrb_w   ),
        .ren_o                 (ren_w     )
    );

    wire  [ 7:0]   mst_rdata_w ;
    wire           mst_read_w  ;
    wire  [ 7:0]   mst_wdata_w ;
    wire           mst_write_w ;


    uart_axi_mst uart_axi_mst 
    (
        .clk                      (clk   ),
        .rst_n                    (rst_n ),     

        // AXI4 bus master interface
        .axi_awvalid_o            (mst_awvalid_o),  
        .axi_awaddr_o             (mst_awaddr_o ),   
        .axi_awid_o               (mst_awid_o   ),   
        .axi_awlen_o              (mst_awlen_o  ),   
        .axi_awburst_o            (mst_awburst_o),  
        .axi_wvalid_o             (mst_wvalid_o ),   
        .axi_wdata_o              (mst_wdata_o  ),  
        .axi_wstrb_o              (mst_wstrb_o  ),  
        .axi_wlast_o              (mst_wlast_o  ),  
        .axi_bready_o             (mst_bready_o ),   
        .axi_arvalid_o            (mst_arvalid_o),    
        .axi_araddr_o             (mst_araddr_o ),   
        .axi_arid_o               (mst_arid_o   ),   
        .axi_arlen_o              (mst_arlen_o  ),  
        .axi_arburst_o            (mst_arburst_o),    
        .axi_rready_o             (mst_rready_o ),   

        .axi_awready_i            (mst_awready_i),   
        .axi_wready_i             (mst_wready_i ),  
        .axi_bvalid_i             (mst_bvalid_i ),  
        .axi_bresp_i              (mst_bresp_i  ), 
        .axi_bid_i                (mst_bid_i    ),
        .axi_arready_i            (mst_arready_i),   
        .axi_rvalid_i             (mst_rvalid_i ),  
        .axi_rdata_i              (mst_rdata_i  ), 
        .axi_rresp_i              (mst_rresp_i  ), 
        .axi_rid_i                (mst_rid_i    ), 
        .axi_rlast_i              (mst_rlast_i  ), 

        //uart rx interface
        .mst_rdata_i              (mst_rdata_w             ),
        .mst_read_o               (mst_read_w              ),
        .rx_buffer_data_present_i (rx_buffer_data_present_w),

        //uart tx interface
        .mst_wdata_o              (mst_wdata_w      ),
        .mst_write_o              (mst_write_w      ),      
        .tx_buffer_full_i         (tx_buffer_full_w ),
        .tx_buffer_afull_i        (tx_buffer_afull_w)
    );


    // Selection of UART operator
    assign rx_read_buffer_w  = (uart_mst_i == 1'b1) ? mst_read_w : slv_read_w;
    assign tx_write_buffer_w = (uart_mst_i == 1'b1) ? mst_write_w : slv_write_w;
    assign tx_data_in_w      = (uart_mst_i == 1'b1) ? mst_wdata_w : slv_wdata_w;

    assign mst_rdata_w = rx_data_out_w;
    assign slv_rdata_w = rx_data_out_w;


    //-----------------------------------------------------------------
    // Interrupt
    // Only generate interrupt when uart data received
    //-----------------------------------------------------------------    
    reg    intr_q;
    reg    rx_buffer_data_present_q;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            rx_buffer_data_present_q <= 1'b0;
        else
            rx_buffer_data_present_q <= rx_buffer_data_present_w;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            intr_q <= 1'b0;
        else if (rx_buffer_data_present_w & (~rx_buffer_data_present_q)) //positive edge
            intr_q <= 1'b1;
        else if ((~rx_buffer_data_present_w) & rx_buffer_data_present_q) //negative edge
            intr_q <= 1'b0;
    end

    assign intr_o = intr_q;

endmodule
