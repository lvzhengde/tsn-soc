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
 *  Description  : uart test device
 *  File         : uart_device.v  
-*/

`include "uart_defines.v"

module uart_device
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter T_CLK = 10  //100MHz clock
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    input           uart_mst_i  ,    //0: Normal slave operation, 1: UART as AXI4 bus master 
    input           uart_rxd_i  ,
    output          uart_txd_o  ,  
    output          reset_cpu_o ,
    output          intr_o        
);  

    reg clk   = 0;  
    reg rst_n = 0;

    localparam QDELAY  = 0.1;

    always #(T_CLK/2) clk = ~clk;

    task reset;
    begin
        rst_n    = 0;
        #555 
        rst_n    = 1;
    end
    endtask 

    wire           mst_awvalid_w ;  
    wire  [ 31:0]  mst_awaddr_w  ;   
    wire  [  3:0]  mst_awid_w    ;   
    wire  [  7:0]  mst_awlen_w   ;   
    wire  [  1:0]  mst_awburst_w ;  
    wire           mst_wvalid_w  ;   
    wire  [ 31:0]  mst_wdata_w   ;  
    wire  [  3:0]  mst_wstrb_w   ;  
    wire           mst_wlast_w   ;  
    wire           mst_bready_w  ;   
    wire           mst_arvalid_w ;    
    wire  [ 31:0]  mst_araddr_w  ;   
    wire  [  3:0]  mst_arid_w    ;   
    wire  [  7:0]  mst_arlen_w   ;  
    wire  [  1:0]  mst_arburst_w ;    
    wire           mst_rready_w  ;   
     
    wire           mst_awready_w ;   
    wire           mst_wready_w  ;  
    wire           mst_bvalid_w  ;  
    wire  [  1:0]  mst_bresp_w   ; 
    wire  [  3:0]  mst_bid_w     ;
    wire           mst_arready_w ;   
    wire           mst_rvalid_w  ;  
    wire  [ 31:0]  mst_rdata_w   ; 
    wire  [  1:0]  mst_rresp_w   ; 
    wire  [  3:0]  mst_rid_w     ; 
    wire           mst_rlast_w   ; 

    wire           slv_awvalid_w ;
    wire  [ 31:0]  slv_awaddr_w  ;
    wire  [  3:0]  slv_awid_w    ;
    wire  [  7:0]  slv_awlen_w   ;
    wire  [  1:0]  slv_awburst_w ;
    wire           slv_wvalid_w  ;
    wire  [ 31:0]  slv_wdata_w   ;
    wire  [  3:0]  slv_wstrb_w   ;
    wire           slv_wlast_w   ;
    wire           slv_bready_w  ;
    wire           slv_arvalid_w ;
    wire  [ 31:0]  slv_araddr_w  ;
    wire  [  3:0]  slv_arid_w    ;
    wire  [  7:0]  slv_arlen_w   ;
    wire  [  1:0]  slv_arburst_w ;
    wire           slv_rready_w  ;
     
    wire           slv_awready_w ;
    wire           slv_wready_w  ;
    wire           slv_bvalid_w  ;
    wire  [  1:0]  slv_bresp_w   ;
    wire  [  3:0]  slv_bid_w     ;
    wire           slv_arready_w ;
    wire           slv_rvalid_w  ;
    wire  [ 31:0]  slv_rdata_w   ;
    wire  [  1:0]  slv_rresp_w   ;
    wire  [  3:0]  slv_rid_w     ;
    wire           slv_rlast_w   ;


    uart_top uart_top 
    (
        .clk             (clk   ),
        .rst_n           (rst_n ),      
    
        // uart interface
        .uart_mst_i      (uart_mst_i ),    
        .uart_rxd_i      (uart_rxd_i ),
        .uart_txd_o      (uart_txd_o ),  
        .reset_cpu_o     (reset_cpu_o),
        .intr_o          (intr_o     ),
    
        // AXI4 bus master interface
        .mst_awvalid_o   (mst_awvalid_w ),  
        .mst_awaddr_o    (mst_awaddr_w  ),   
        .mst_awid_o      (mst_awid_w    ),   
        .mst_awlen_o     (mst_awlen_w   ),   
        .mst_awburst_o   (mst_awburst_w ),  
        .mst_wvalid_o    (mst_wvalid_w  ),   
        .mst_wdata_o     (mst_wdata_w   ),  
        .mst_wstrb_o     (mst_wstrb_w   ),  
        .mst_wlast_o     (mst_wlast_w   ),  
        .mst_bready_o    (mst_bready_w  ),   
        .mst_arvalid_o   (mst_arvalid_w ),    
        .mst_araddr_o    (mst_araddr_w  ),   
        .mst_arid_o      (mst_arid_w    ),   
        .mst_arlen_o     (mst_arlen_w   ),  
        .mst_arburst_o   (mst_arburst_w ),    
        .mst_rready_o    (mst_rready_w  ),   
    
        .mst_awready_i   (mst_awready_w ),   
        .mst_wready_i    (mst_wready_w  ),  
        .mst_bvalid_i    (mst_bvalid_w  ),  
        .mst_bresp_i     (mst_bresp_w   ), 
        .mst_bid_i       (mst_bid_w     ),
        .mst_arready_i   (mst_arready_w ),   
        .mst_rvalid_i    (mst_rvalid_w  ),  
        .mst_rdata_i     (mst_rdata_w   ), 
        .mst_rresp_i     (mst_rresp_w   ), 
        .mst_rid_i       (mst_rid_w     ), 
        .mst_rlast_i     (mst_rlast_w   ), 
    
        // AXI4 bus slave interface
        .slv_awvalid_i   (slv_awvalid_w ),
        .slv_awaddr_i    (slv_awaddr_w  ),
        .slv_awid_i      (slv_awid_w    ),
        .slv_awlen_i     (slv_awlen_w   ),
        .slv_awburst_i   (slv_awburst_w ),
        .slv_wvalid_i    (slv_wvalid_w  ),
        .slv_wdata_i     (slv_wdata_w   ),
        .slv_wstrb_i     (slv_wstrb_w   ),
        .slv_wlast_i     (slv_wlast_w   ),
        .slv_bready_i    (slv_bready_w  ),
        .slv_arvalid_i   (slv_arvalid_w ),
        .slv_araddr_i    (slv_araddr_w  ),
        .slv_arid_i      (slv_arid_w    ),
        .slv_arlen_i     (slv_arlen_w   ),
        .slv_arburst_i   (slv_arburst_w ),
        .slv_rready_i    (slv_rready_w  ),
    
        .slv_awready_o   (slv_awready_w ),
        .slv_wready_o    (slv_wready_w  ),
        .slv_bvalid_o    (slv_bvalid_w  ),
        .slv_bresp_o     (slv_bresp_w   ),
        .slv_bid_o       (slv_bid_w     ),
        .slv_arready_o   (slv_arready_w ),
        .slv_rvalid_o    (slv_rvalid_w  ),
        .slv_rdata_o     (slv_rdata_w   ),
        .slv_rresp_o     (slv_rresp_w   ),
        .slv_rid_o       (slv_rid_w     ),
        .slv_rlast_o     (slv_rlast_w   )
    );

    reg  sim_done = 0;

    //AXI slave
    mem_axi4_beh
    #(
        .P_SIZE_IN_BYTES      (1024 ), 
        .ID                   (0    ), 
        .P_DELAY_WRITE_SETUP  (2    ),
        .P_DELAY_WRITE_BURST  (2    ),
        .P_DELAY_READ_SETUP   (2    ),
        .P_DELAY_READ_BURST   (2    )
    )
    u_mem_axi4_0
    (
        .clk             (clk    ),
        .rst_n           (rst_n  ),
    
        // AXI4 interface
        .axi_awvalid_i   (mst_awvalid_w ),
        .axi_awaddr_i    (mst_awaddr_w  ),
        .axi_awid_i      (mst_awid_w    ),
        .axi_awlen_i     (mst_awlen_w   ),
        .axi_awburst_i   (mst_awburst_w ),
        .axi_wvalid_i    (mst_wvalid_w  ),
        .axi_wdata_i     (mst_wdata_w   ),
        .axi_wstrb_i     (mst_wstrb_w   ),
        .axi_wlast_i     (mst_wlast_w   ),
        .axi_bready_i    (mst_bready_w  ),
        .axi_arvalid_i   (mst_arvalid_w ),
        .axi_araddr_i    (mst_araddr_w  ),
        .axi_arid_i      (mst_arid_w    ),
        .axi_arlen_i     (mst_arlen_w   ),
        .axi_arburst_i   (mst_arburst_w ),
        .axi_rready_i    (mst_rready_w  ),
    
        .axi_awready_o   (mst_awready_w ),
        .axi_wready_o    (mst_wready_w  ),
        .axi_bvalid_o    (mst_bvalid_w  ),
        .axi_bresp_o     (mst_bresp_w   ),
        .axi_bid_o       (mst_bid_w     ),
        .axi_arready_o   (mst_arready_w ),
        .axi_rvalid_o    (mst_rvalid_w  ),
        .axi_rdata_o     (mst_rdata_w   ),
        .axi_rresp_o     (mst_rresp_w   ),
        .axi_rid_o       (mst_rid_w     ),
        .axi_rlast_o     (mst_rlast_w   ),
    
        .done_i          (sim_done      )
    );


    // AXI4 bus masters
    reg    test_busy = 1;

    axi4_master 
    #(
        .ID    (1) 
    )
    u_axi4_master
    (
        .clk             (clk    ),
        .rst_n           (rst_n  ),
    
        .axi_awready_i   (slv_awready_w ),
        .axi_wready_i    (slv_wready_w  ),
        .axi_bvalid_i    (slv_bvalid_w  ),
        .axi_bresp_i     (slv_bresp_w   ),
        .axi_bid_i       (slv_bid_w     ),
        .axi_arready_i   (slv_arready_w ),
        .axi_rvalid_i    (slv_rvalid_w  ),
        .axi_rdata_i     (slv_rdata_w   ),
        .axi_rresp_i     (slv_rresp_w   ),
        .axi_rid_i       (slv_rid_w     ),
        .axi_rlast_i     (slv_rlast_w   ),
    
        .axi_awvalid_o   (slv_awvalid_w ),
        .axi_awaddr_o    (slv_awaddr_w  ),
        .axi_awid_o      (slv_awid_w    ),
        .axi_awlen_o     (slv_awlen_w   ),
        .axi_awburst_o   (slv_awburst_w ),
        .axi_wvalid_o    (slv_wvalid_w  ),
        .axi_wdata_o     (slv_wdata_w   ),
        .axi_wstrb_o     (slv_wstrb_w   ),
        .axi_wlast_o     (slv_wlast_w   ),
        .axi_bready_o    (slv_bready_w  ),
        .axi_arvalid_o   (slv_arvalid_w ),
        .axi_araddr_o    (slv_araddr_w  ),
        .axi_arid_o      (slv_arid_w    ),
        .axi_arlen_o     (slv_arlen_w   ),
        .axi_arburst_o   (slv_arburst_w ),
        .axi_rready_o    (slv_rready_w  ),
    
        .busy_i          (test_busy     )
    );
    

    //-----------------------------------------------------------------
    // Tasks and functions
    //-----------------------------------------------------------------
    reg  [ 31:0]  rd_buffer[0:1023]; 
    reg  [ 31:0]  wr_buffer[0:1023]; 

    reg  [ 31:0]  rd_data, wr_data;
    wire [ 31:0]  base_addr = `UART_BASEADDR; 

    reg  tx_done = 0;

    task axi_uart_transmit;
        input integer len;
        input integer random;

        integer     idx, seed;
        reg  [31:0] addr;
        reg         tx_fifo_full;
    begin
        seed = random;
        tx_fifo_full = 0;
        tx_done = 0;

        if(len > 1024) begin
            $display($time,,"%m ERROR length exceed 1024 %x", len);
            $finish;
        end

        //prepare transmit data
        for (idx = 0; idx < len; idx = idx+1) begin
            if (random == 0)
                wr_buffer[idx] = idx & 'hff;
            else
                wr_buffer[idx] = $random(seed) & 'hff;
        end

        //transmit data
        for (idx = 0; idx < len; idx = idx+1) begin
            //read uart status 
            addr = base_addr + `UART_STATUS;
            u_axi4_master.axi_master_read (addr, 1, 1, 0);
            rd_data = u_axi4_master.rdata[0];
            tx_fifo_full = rd_data[3];

            while (tx_fifo_full == 1) begin
                repeat(12) @(posedge uart_top.en_16x_baud_w);
                u_axi4_master.axi_master_read (addr, 1, 1, 0);
                rd_data = u_axi4_master.rdata[0];
                tx_fifo_full = rd_data[3];
            end

            //write data to transmit
            addr = base_addr + `UART_TXDATA;
            wr_data = {24'h0, wr_buffer[idx][7:0]};
            u_axi4_master.wdata[0] = wr_data;
            u_axi4_master.axi_master_write(addr, 1, 1, 0);
            $display($time,, "%m idx = %d, transmitted data = %02x", idx, wr_data[7:0]);
            @(posedge clk); 
        end //for

        //wait for finishing transmit
        wait(uart_top.uart_tx.data_present == 1'b0);
        repeat(16*11) @(posedge uart_top.en_16x_baud_w);

        $display($time,, "%m Device UART Transmit Done!");
        tx_done = 1;
    end
    endtask

    reg  rx_terminate    = 0;
    reg  rx_data_present = 0;

    task axi_uart_receive;
        output integer len;

        reg  [31:0] addr;
    begin
        len = 0;
        rx_terminate    = 0;
        rx_data_present = 0;

        while (rx_terminate != 1'b1 && len <= 1024) begin        
            //read uart rx data register 
            addr = base_addr + `UART_RXDATA;
            u_axi4_master.axi_master_read (addr, 1, 1, 0);
            rd_data = u_axi4_master.rdata[0];
            rx_data_present = rd_data[12];

            if (rx_data_present == 1'b1) begin
                rd_buffer[len][31:0] = {24'h0, rd_data[7:0]};
                $display($time,, "%m idx = %d, received data = %02x", len, rd_data[7:0]);
                len = len + 1;
            end
            else begin //wait
                repeat(2) @(posedge uart_top.en_16x_baud_w);
            end

            @(posedge clk);
        end  //while
    end
    endtask

endmodule
