/*++
//  Description  : uart test host
//  File         : uart_host.v  
--*/

`timescale 1ns/10fs

module uart_host(
  input      serial_in_i,
  output     serial_out_o  
); 
  wire          clk;

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

  clkgen clkgen (
    .clk                   (clk ),
    .rst_n                 (rst_n )
  );

  uart_rx uart_rx(
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
    .buffer_afull_o  ( ),
    .buffer_aempty_o ( )  
  );

  uart_tx uart_tx(
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
    .buffer_hfull_o    (tx_buffer_hfull ),
    .buffer_afull_o  ( ),
    .buffer_aempty_o ( )
  );

  baud_generator  baud_generator(
    .clk                   (clk )   ,
    .rst_n                 (rst_n)   ,
                           
    .baud_config_i         (baud_config )   ,
    .en_16x_baud_o         (en_16x_baud )
  );

  initial begin
    parity_en = 0;
    msb_first = 0;
    baud_config[15:0] = 16'd68;
    start_polarity = 0;

    rx_read_buffer = 1'b0;
    tx_write_buffer = 1'b0;
    tx_data_in = 8'h0;
    reset_buffer = 1'b0;
  end

  reg  [15:0]   wr_buffer[15:0];
  reg  [15:0]   rd_buffer[15:0]; 

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
