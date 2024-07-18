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
 *  Description  : uart test host
 *  File         : uart_host.v  
-*/


module uart_host
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
    input      serial_in_i,
    output     serial_out_o  
); 
    reg           parity_en ; 
    reg           msb_first ; 
    reg           start_polarity;

    wire          en_16x_baud;
    reg           reset_buffer;

    wire [7:0]    rx_data_out ;
    reg           rx_read_buffer;
    wire          rx_buffer_data_present;
    wire          rx_buffer_full;
    wire          rx_buffer_hfull;     

    reg   [7:0]   tx_data_in         ; 
    reg           tx_write_buffer    ; 
    wire          tx_buffer_full     ; 
    wire          tx_buffer_hfull; 

    reg   [15:0]  baud_config    ;


    // clock and reset
    reg clk   = 0;  
    reg rst_n = 0;

    always #(T_CLK/2) clk = ~clk;

    task reset;
    begin
        rst_n    = 0;
        #555 
        rst_n    = 1;
    end
    endtask 

    // UART RX
    uart_rx uart_rx
    (
        .clk                   (clk ),
        .rst_n                 (rst_n ),     
                              
        .parity_en_i           (parity_en ),     
        .msb_first_i           (msb_first ),     
        .start_polarity_i      (start_polarity),
                              
        .serial_in_i           (serial_in_i ),
        .data_out_o            (rx_data_out ),
        .read_buffer_i         (rx_read_buffer ),
        .reset_buffer_i        (reset_buffer ),                     
        .en_16x_baud_i         (en_16x_baud ),
                            
        .buffer_data_present_o (rx_buffer_data_present ),
        .buffer_full_o         (rx_buffer_full ),
        .buffer_hfull_o        (rx_buffer_hfull ),
        .buffer_afull_o        ( ),
        .buffer_aempty_o       ( )  
    );

    // UART TX
    uart_tx uart_tx
    (
        .clk                   (clk ) , 
        .rst_n                 (rst_n ) , 
                                
        .parity_en_i           (parity_en ) , 
        .msb_first_i           (msb_first ) , 
        .start_polarity_i      (start_polarity),
                                
        .data_in_i             (tx_data_in ) , 
        .write_buffer_i        (tx_write_buffer ) , 
        .reset_buffer_i        (reset_buffer ) , 
        .en_16x_baud_i         (en_16x_baud ) , 
                                
        .serial_out_o          (serial_out_o ) , 
        .buffer_full_o         (tx_buffer_full ) , 
        .buffer_hfull_o        (tx_buffer_hfull ),
        .buffer_afull_o        ( ),
        .buffer_aempty_o       ( )
    );

    baud_generator  baud_generator
    (
        .clk                   (clk )   ,
        .rst_n                 (rst_n)   ,
                               
        .baud_config_i         (baud_config )   ,
        .en_16x_baud_o         (en_16x_baud )
    );

    localparam BASEADDR   = 24'h90_0000 ;
    localparam CLK_FREQ   = 100000000   ;  //100MHz
    localparam UART_SPEED = 115200      ;  //Baud rate
    localparam BAUD_CFG   = CLK_FRQ/(16*UART_SPEED);

    reg    tx_done;
    reg    rx_terminate;

    initial begin
        parity_en         = 0;
        msb_first         = 0;
        baud_config[15:0] = BAUD_CFG;
        start_polarity    = 0;

        rx_read_buffer    = 1'b0;
        tx_write_buffer   = 1'b0;
        tx_data_in        = 8'h0;
        reset_buffer      = 1'b0;

        tx_done      = 0;
        rx_terminate = 0;
    end

    reg  [ 31:0]  rd_buffer[0:1023]; 
    reg  [ 31:0]  wr_buffer[0:1023]; 

    //-----------------------------------------------------------------
    // Tasks
    //-----------------------------------------------------------------
    task test_transmit;
        input integer len;
        input integer random;

        integer idx, seed;
    begin
        tx_write_buffer = 1'b0;
        tx_data_in      = 8'h0; 
        seed    = random;
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
            wait(~tx_buffer_full);
            @(posedge clk);
            tx_write_buffer = 1'b1; 
            tx_data_in      = wr_buffer[idx][7:0];
            @(posedge clk);
            tx_write_buffer = 1'b0;
            tx_data_in      = 8'h0;
            @(posedge clk); 
        end
        
        //wait for finishing transmit
        wait(uart_tx.data_present == 1'b0);
        repeat(16*11) @(posedge en_16x_baud);

        tx_done = 1;
    end
    endtask

    task test_receive;
        output integer len;
    begin
        len = 0;

        while (rx_terminate != 1'b1 && len <= 1024) begin        //get SOF
            wait(rx_buffer_data_present);
            @(posedge clk);
            wr_buffer[len][31:0] = {24'h0, rx_data_out[7:0]};
            rx_read_buffer = 1'b1;
            @(posedge clk);
            rx_read_buffer = 1'b0;
            @(posedge clk);

            len = len + 1;
        end
    end
    endtask


    localparam REQ_WRITE        = 8'had;
    localparam REQ_READ         = 8'h5a;

    task write_mem;
        input [31:0]  addr;
        input [ 7:0]  len ;  // in bytes
        input integer random;

        integer idx, seed;
        reg  [31:0] temp;
        reg  [ 1:0] offset;
        reg  [ 7:0] data;
    begin
        tx_write_buffer = 1'b0;
        tx_data_in      = 8'h0; 
        seed    = random;
        tx_done = 0;
        offset  = 0;
        data    = 0;

        //prepare data
        for (idx = 0; idx < (len/4)+1; idx = idx+1) begin
            if (random == 0)
                wr_buffer[idx] = idx;
            else
                wr_buffer[idx] = $random(seed);
        end

        //tx command
        wait(~tx_buffer_full);
        @(posedge clk);
        tx_write_buffer = 1'b1;
        tx_data_in      = REQ_WRITE;
        @(posedge clk);
        tx_write_buffer = 1'b0;
        tx_data_in      = 8'h0;
        @(posedge clk);

        //tx length
        wait(~tx_buffer_full);
        @(posedge clk);
        tx_write_buffer = 1'b1;
        tx_data_in      = len;
        @(posedge clk);
        tx_write_buffer = 1'b0;
        tx_data_in      = 8'h0;
        @(posedge clk);

        //tx memory address
        temp = addr;
        for (idx = 0; idx < 4; idx = idx+1) begin
            wait(~tx_buffer_full);
            @(posedge clk);
            tx_write_buffer = 1'b1;
            tx_data_in      = temp[31:24];
            @(posedge clk);
            tx_write_buffer = 1'b0;
            tx_data_in      = 8'h0;
            @(posedge clk);

            temp = {temp[23:0], 8'h0};
        end

        //tx data
        idx = 0;
        while (idx < len) begin
            offset = idx[1:0]
            case (offset)
                2'b00: data = wr_buffer[idx>>2][ 7: 0];
                2'b01: data = wr_buffer[idx>>2][15: 8];
                2'b10: data = wr_buffer[idx>>2][23:16];
                2'b11: data = wr_buffer[idx>>2][31:24];
            endcase

            wait(~tx_buffer_full);
            @(posedge clk);
            tx_write_buffer = 1'b1;
            tx_data_in      = data;
            @(posedge clk);
            tx_write_buffer = 1'b0;
            tx_data_in      = 8'h0;
            @(posedge clk);

            idx = idx + 1;
        end

        //wait for finishing transmit
        wait(uart_tx.data_present == 1'b0);
        repeat(16*11) @(posedge en_16x_baud);

        tx_done = 1;
    end
    endtask

  //++
  //tasks for register write access
  //--
  task write_register;
    input [15:0]  base_addr;
    input [3:0]   burst_len;
    
    begin : WRITE_PROCESS
      integer i;
      reg [7:0]  tx_fcs;
      reg [15:0]  data;

      i = 0;
      tx_fcs = 8'h0;
      tx_write_buffer = 1'b0;
      tx_data_in = 8'h0; 

      data = 16'h0;

      //tx SOF
      wait(~tx_buffer_full);
      @(posedge clk);
      tx_write_buffer = 1'b1;
      tx_data_in = 8'haa;
      @(posedge clk);
      tx_write_buffer = 1'b0;
      tx_data_in = 8'h0;
      @(posedge clk);

      //tx OL
      wait(~tx_buffer_full);
      @(posedge clk);
      tx_write_buffer = 1'b1; 
      tx_data_in = {4'b0001, burst_len};
      tx_fcs = tx_fcs ^ tx_data_in;
      @(posedge clk);
      tx_write_buffer = 1'b0;
      tx_data_in = 8'h0;
      @(posedge clk);

      //tx base addr
      wait(~tx_buffer_full);
      @(posedge clk);
      tx_write_buffer = 1'b1; 
      tx_data_in = base_addr[15:8];
      tx_fcs = tx_fcs ^ tx_data_in;
      @(posedge clk);
      tx_write_buffer = 1'b0;
      tx_data_in = 8'h0;
      @(posedge clk); 

      wait(~tx_buffer_full);
      @(posedge clk);
      tx_write_buffer = 1'b1; 
      tx_data_in = base_addr[7:0];
      tx_fcs = tx_fcs ^ tx_data_in;
      @(posedge clk);
      tx_write_buffer = 1'b0;
      tx_data_in = 8'h0;
      @(posedge clk);

      //tx data
      for(i=0; i<=burst_len; i=i+1) begin

	data = wr_buffer[i];

        wait(~tx_buffer_full);
	@(posedge clk);
        tx_write_buffer = 1'b1; 
        tx_data_in = data[15:8];
        tx_fcs = tx_fcs ^ tx_data_in;
        @(posedge clk);
        tx_write_buffer = 1'b0;
        tx_data_in = 8'h0;
        @(posedge clk); 

        wait(~tx_buffer_full);
	@(posedge clk);
        tx_write_buffer = 1'b1; 
        tx_data_in = data[7:0];
        tx_fcs = tx_fcs ^ tx_data_in;
        @(posedge clk);
        tx_write_buffer = 1'b0;
        tx_data_in = 8'h0;
	@(posedge clk);

      end 

      //tx FCS
      wait(~tx_buffer_full);
      @(posedge clk);
      tx_write_buffer = 1'b1; 
      tx_data_in = tx_fcs;
      @(posedge clk);
      tx_write_buffer = 1'b0;
      tx_data_in = 8'h0;
      @(posedge clk);

      //tx EOF
      wait(~tx_buffer_full);
      @(posedge clk);
      tx_write_buffer = 1'b1; 
      tx_data_in = 8'hd5;
      @(posedge clk);
      tx_write_buffer = 1'b0;
      tx_data_in = 8'h0;
      @(posedge clk);

      wait(uart_tx.data_present == 1'b0);
      repeat(16*11) @(posedge en_16x_baud);

    end
  endtask 


  //++
  //tasks for register read access
  //--
    task read_register;
    input [15:0]  base_addr;
    input [3:0]   burst_len;
    
    begin : READ_PROCESS
      integer i;
      reg [7:0]  tx_fcs;
      reg [7:0]  data;
      reg [15:0] temp;

      i = 0;
      tx_fcs = 8'h0;
      tx_write_buffer = 1'b0;
      tx_data_in = 8'h0; 

      data = 8'h0;

      //tx SOF
      wait(~tx_buffer_full);
      @(posedge clk);
      tx_write_buffer = 1'b1;
      tx_data_in = 8'haa;
      @(posedge clk);
      tx_write_buffer = 1'b0;
      tx_data_in = 8'h0;
      @(posedge clk);

      //tx OL
      wait(~tx_buffer_full);
      @(posedge clk);
      tx_write_buffer = 1'b1; 
      tx_data_in = {4'b0000, burst_len};
      tx_fcs = tx_fcs ^ tx_data_in;
      @(posedge clk);
      tx_write_buffer = 1'b0;
      tx_data_in = 8'h0;
      @(posedge clk);

      //tx base addr
      wait(~tx_buffer_full);
      @(posedge clk);
      tx_write_buffer = 1'b1; 
      tx_data_in = base_addr[15:8];
      tx_fcs = tx_fcs ^ tx_data_in;
      @(posedge clk);
      tx_write_buffer = 1'b0;
      tx_data_in = 8'h0;
      @(posedge clk); 

      wait(~tx_buffer_full);
      @(posedge clk);
      tx_write_buffer = 1'b1; 
      tx_data_in = base_addr[7:0];
      tx_fcs = tx_fcs ^ tx_data_in;
      @(posedge clk);
      tx_write_buffer = 1'b0;
      tx_data_in = 8'h0;
      @(posedge clk);

      //tx FCS
      wait(~tx_buffer_full);
      @(posedge clk);
      tx_write_buffer = 1'b1; 
      tx_data_in = tx_fcs;
      @(posedge clk);
      tx_write_buffer = 1'b0;
      tx_data_in = 8'h0;
      @(posedge clk);

      //tx EOF
      wait(~tx_buffer_full);
      @(posedge clk);
      tx_write_buffer = 1'b1; 
      tx_data_in = 8'hd5;
      @(posedge clk)
      tx_write_buffer = 1'b0;
      tx_data_in = 8'h0;
      @(posedge clk);


      //get received data and parse.
      parse_rx_packet(base_addr, burst_len);

    end
  endtask 

  reg   [7:0]  rcved_OL;
  reg   [15:0] rcved_base_addr;
  reg          valid_frame;
  reg          fcs_matched;

  task parse_rx_packet;
    input [15:0]  base_addr;
    input [3:0]   burst_len;
    
    begin : RX_PARSE_PROCESS
      integer i;
      reg [7:0]  rx_fcs;
      reg [7:0]  data;
      reg [15:0] temp;
      reg [4:0]  burst_len_p1;
      reg [4:0]  byte_len;

      burst_len_p1 = burst_len + 1;
      byte_len = {burst_len_p1, 1'b0};

      i = 0;
      rx_fcs = 8'h0;
      rx_read_buffer = 1'b0;
      fcs_matched = 1'b0;
      valid_frame = 1'b0;

      data = 8'h0;

      while(data != 8'haa) begin        //get SOF
        wait(rx_buffer_data_present);
	@(posedge clk);
        data = rx_data_out;
        rx_read_buffer = 1'b1;
        @(posedge clk);
        rx_read_buffer = 1'b0;
	@(posedge clk);
      end
      
      @(posedge clk);

      wait(rx_buffer_data_present);     //get OL
      @(posedge clk);
      data = rx_data_out;
      rx_read_buffer = 1'b1;
      @(posedge clk);
      rx_read_buffer = 1'b0;
      rcved_OL = data;
      rx_fcs = rx_fcs ^ data;
      @(posedge clk);

      wait(rx_buffer_data_present);     //get base address
      @(posedge clk);
      data = rx_data_out;
      rx_read_buffer = 1'b1;
      @(posedge clk);
      rx_read_buffer = 1'b0;
      rcved_base_addr[15:8] = data;
      rx_fcs = rx_fcs ^ data;
      @(posedge clk);
      
      wait(rx_buffer_data_present);   
      @(posedge clk);  
      data = rx_data_out;
      rx_read_buffer = 1'b1;
      @(posedge clk);
      rx_read_buffer = 1'b0;
      rcved_base_addr[7:0] = data;
      rx_fcs = rx_fcs ^ data;
      @(posedge clk);

      //get readed register data
      for(i=0; i<=burst_len; i=i+1) begin
        wait(rx_buffer_data_present); 
        @(posedge clk);	
        data = rx_data_out;
        rx_read_buffer = 1'b1;
        @(posedge clk);
        rx_read_buffer = 1'b0;
        temp[15:8] = data;
        rx_fcs = rx_fcs ^ data;
        @(posedge clk); 

        wait(rx_buffer_data_present);
        @(posedge clk);
        data = rx_data_out;
        rx_read_buffer = 1'b1;
        @(posedge clk);
        rx_read_buffer = 1'b0;
        temp[7:0] = data;
        rx_fcs = rx_fcs ^ data;
	@(posedge clk);

        rd_buffer[i] = temp;
      end

      //get FCS
      wait(rx_buffer_data_present);
      @(posedge clk);     
      data = rx_data_out;
      rx_read_buffer = 1'b1;
      @(posedge clk);
      rx_read_buffer = 1'b0;
      if(rx_fcs == data)
        fcs_matched = 1'b1;
      @(posedge clk);

      //get EOF
      wait(rx_buffer_data_present);
      @(posedge clk);     
      data = rx_data_out;
      rx_read_buffer = 1'b1;
      @(posedge clk);
      rx_read_buffer = 1'b0;
      if(data == 8'hd5 && rcved_OL == {4'b0, burst_len} && rcved_base_addr == base_addr && fcs_matched == 1'b1)
        valid_frame = 1'b1;

      @(posedge clk);

      #5000;

    end
  endtask

endmodule
