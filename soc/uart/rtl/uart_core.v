/*++
//  Description : uart top level, include uart transmitter/receiver
//                and on-chip-bus master.
//  File        : uart_core.v
--*/

`timescale 1ns/10fs

module uart_core(
  input                  clk     ,
  input                  rst_n   ,      //active low reset

  //two-wires uart interface
  input                  serial_in_i     ,
  output                 serial_out_o    ,  

  //on chip bus interface
  output                 bus2ip_clk      ,
  output                 bus2ip_rst_n    ,
  output  [15:0]         bus2ip_addr_o   ,
  output  [15:0]         bus2ip_data_o   ,
  output                 bus2ip_rd_ce_o  ,    //active high
  output                 bus2ip_wr_ce_o  ,    //active high
  input   [15:0]         ip2bus_data_i
);

  wire          parity_en ; 
  wire          msb_first ; 
  wire          start_polarity;

  wire          en_16x_baud;
  wire          reset_buffer;

  wire [7:0]    rx_data_out ;
  wire          rx_read_buffer;
  wire          rx_buffer_data_present;
  wire          rx_buffer_full;
  wire          rx_buffer_hfull;
  wire          rx_buffer_afull;
  wire          rx_buffer_aempty;  

  wire  [7:0]   tx_data_in         ; 
  wire          tx_write_buffer    ; 
  wire          tx_buffer_full     ; 
  wire          tx_buffer_hfull;
  wire          tx_buffer_afull;
  wire          tx_buffer_aempty; 

  wire  [15:0]  baud_config  ;

  wire  [15:0]  bus2ip_addr  ; 
  wire  [15:0]  bus2ip_data  ; 
  wire          bus2ip_rd_ce ; 
  wire          bus2ip_wr_ce ; 
  wire  [15:0]  ip2bus_data  ; 


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
    .buffer_afull_o        (rx_buffer_afull ),
    .buffer_aempty_o       (rx_buffer_aempty )     
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
    .buffer_hfull_o        (tx_buffer_hfull ),
    .buffer_afull_o        (tx_buffer_afull ),
    .buffer_aempty_o       (tx_buffer_aempty )         
  );


 baud_generator  baud_generator(
    .clk                   (clk )   ,
    .rst_n                 (rst_n)  ,
                           
    .baud_config_i         (baud_config )  ,
    .en_16x_baud_o         (en_16x_baud )
  );

 uart_regs  uart_regs(
    //on-chip bus interface
    .bus2ip_clk            (bus2ip_clk   ),
    .bus2ip_rst_n          (bus2ip_rst_n ),
    .bus2ip_addr_i         (bus2ip_addr  ),
    .bus2ip_data_i         (bus2ip_data  ),
    .bus2ip_rd_ce_i        (bus2ip_rd_ce ),
    .bus2ip_wr_ce_i        (bus2ip_wr_ce ),
    .ip2bus_data_o         (ip2bus_data  ),
  
    //fifo status signals
    .rx_buffer_data_present_i (rx_buffer_data_present  ) ,
    .rx_buffer_full_i         (rx_buffer_full          ) ,
    .rx_buffer_hfull_i        (rx_buffer_hfull     ) ,
    .rx_buffer_afull_i        (rx_buffer_afull  ) ,
    .rx_buffer_aempty_i       (rx_buffer_aempty ) ,    
                                                        
    .tx_buffer_full_i         (tx_buffer_full          ) ,
    .tx_buffer_hfull_i        (tx_buffer_hfull     ) ,
    .tx_buffer_afull_i        (tx_buffer_afull),
    .tx_buffer_aempty_i       (tx_buffer_aempty),   
  
    //global configurations
    .parity_en_o            (parity_en    ) ,     
    .msb_first_o            (msb_first    ) ,    
    .start_polarity_o       (start_polarity),
    .reset_buffer_o         (reset_buffer ) ,   
    .baud_config_o          (baud_config  ) 
  );

 bus_master  bus_master(
    .clk                    (clk        ),
    .rst_n                  (rst_n      ),      
                                           
    .en_16x_baud_i          (en_16x_baud   ),
                                         
    //uart rx interface
    .rx_data_out_i           (rx_data_out            ) ,
    .rx_read_buffer_o        (rx_read_buffer         ) ,
    .rx_buffer_data_present_i(rx_buffer_data_present ) ,
    .rx_buffer_full_i        (rx_buffer_full         ) ,
    .rx_buffer_hfull_i       (rx_buffer_hfull    ) ,
    .rx_buffer_afull_i       (rx_buffer_afull  ) ,
    .rx_buffer_aempty_i      (rx_buffer_aempty ) ,
  
    //uart tx interface
    .tx_data_in_o            (tx_data_in          ) ,
    .tx_write_buffer_o       (tx_write_buffer     ) ,
    .tx_buffer_full_i        (tx_buffer_full      ) ,
    .tx_buffer_hfull_i       (tx_buffer_hfull ) , 
    .tx_buffer_afull_i       (tx_buffer_afull),
    .tx_buffer_aempty_i      (tx_buffer_aempty),   
  
    //on chip bus interface
    .bus2ip_clk              (bus2ip_clk    ) ,
    .bus2ip_rst_n            (bus2ip_rst_n  ) ,
    .bus2ip_addr_o           (bus2ip_addr   ) ,
    .bus2ip_data_o           (bus2ip_data   ) ,
    .bus2ip_rd_ce_o          (bus2ip_rd_ce  ) ,  
    .bus2ip_wr_ce_o          (bus2ip_wr_ce  ) , 
    .ip2bus_data_i           (ip2bus_data_i ) 
  );

  assign bus2ip_addr_o   = bus2ip_addr; 
  assign bus2ip_data_o   = bus2ip_data; 
  assign bus2ip_rd_ce_o  = bus2ip_rd_ce;    
  assign bus2ip_wr_ce_o  = bus2ip_wr_ce;    

endmodule
