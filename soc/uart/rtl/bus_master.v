/*++
//  Description : uart on-chip-bus master
//  File        : bus_master.v
--*/

`timescale 1ns/10fs

module bus_master(
  input                  clk               ,
  input                  rst_n             ,      //active low reset
  
  input                  en_16x_baud_i        ,
                                       
  //uart rx interface
  input  [7:0]           rx_data_out_i            ,
  output                 rx_read_buffer_o         ,
  input                  rx_buffer_data_present_i ,
  input                  rx_buffer_full_i         ,
  input                  rx_buffer_hfull_i    ,
  input                  rx_buffer_afull_i  ,
  input                  rx_buffer_aempty_i ,

  //uart tx interface
  output reg [7:0]       tx_data_in_o           ,
  output reg             tx_write_buffer_o      ,      //active high
  input                  tx_buffer_full_i       ,
  input                  tx_buffer_hfull_i  ,  
  input                  tx_buffer_afull_i,
  input                  tx_buffer_aempty_i,  

  //on chip bus interface
  output                 bus2ip_clk      ,
  output                 bus2ip_rst_n    ,
  output  [15:0]         bus2ip_addr_o   ,
  output  [15:0]         bus2ip_data_o   ,
  output                 bus2ip_rd_ce_o  ,    //active high
  output                 bus2ip_wr_ce_o  ,    //active high
  input   [15:0]         ip2bus_data_i
);
  parameter SOF = 8'haa;
  parameter EOF = 8'hd5;
  parameter TIMEOUT_VALUE = 12'd3200;  //16*10*20, 20 bytes time.

  //++
  //Rx parse packets from host
  //--
  wire          get_sof_p1;
  reg           get_sof_done;
  wire          get_eof_p1;
  reg           get_eof_done;
  wire [7:0]    rx_data;
  reg  [11:0]   baud_timer;

  reg  [5:0]    byte_count;
  reg  [5:0]    expected_count;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      baud_timer <= 12'd0;
    else if(rx_buffer_data_present_i == 1'b1 || get_eof_done == 1'b1)
      baud_timer <= 12'd0;
    else if(en_16x_baud_i == 1'b1 && baud_timer < TIMEOUT_VALUE)
      baud_timer <= baud_timer + 1;
  end

  wire baud_timeout = (baud_timer == TIMEOUT_VALUE) ? 1 : 0;

  assign rx_data[7:0] = (rx_buffer_data_present_i == 1'b1) ? rx_data_out_i[7:0] : 8'h0;
  assign get_sof_p1 = (rx_data[7:0] == SOF) ? 1 : 0;
  assign get_eof_p1 = (rx_data[7:0] == EOF && byte_count == expected_count) ? 1 : 0;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      get_sof_done <= 1'b0;
    else if(baud_timeout == 1'b1 || (get_eof_done == 1'b0 && get_eof_p1 == 1'b1))
      get_sof_done <= 1'b0;
    else if(get_sof_p1 == 1'b1)
      get_sof_done <= 1'b1;
  end 

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      get_eof_done <= 1'b0;
    else if(get_sof_done == 1'b0 && get_sof_p1 == 1'b1)
      get_eof_done <= 1'b0;
    else if(get_eof_p1 == 1'b1)
      get_eof_done <= 1'b1;
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      byte_count <= 6'd0;
    else if(get_sof_done == 1'b0 && get_sof_p1 == 1'b1)
      byte_count <= 6'd1;
    else if(rx_buffer_data_present_i == 1'b1 && get_eof_p1 == 1'b0 && get_eof_done == 1'b0)
      byte_count <= byte_count + 1;
    else if(baud_timeout == 1'b1 || get_eof_done == 1'b1)
      byte_count <= 6'd0;
  end

  //parse host commands 
  wire [3:0]    opcode;
  reg           write_reg;
  reg           read_reg;
  reg  [3:0]    burst_len; //in fact length - 1
  wire [4:0]    burst_len_p1;
  reg  [15:0]   base_addr;

  assign opcode[3:0] = rx_data_out_i[7:4];
  assign burst_len_p1 = burst_len + 1;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      write_reg <= 1'b0;
      read_reg  <= 1'b0;
    end
    else if(get_sof_done == 1'b0 && get_sof_p1 == 1'b1) begin
      write_reg <= 1'b0;
      read_reg  <= 1'b0;
    end
    else if(byte_count[5:0] == 6'd1 && rx_buffer_data_present_i == 1'b1) begin
      if(opcode[3:0] == 4'b0000)
        read_reg  <= 1'b1;
      else 
        read_reg  <= 1'b0;

      if(opcode[3:0] == 4'b0001)
        write_reg <= 1'b1;
      else
        write_reg <= 1'b0;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      burst_len[3:0] <= 4'h0;
    else if(get_sof_done == 1'b0 && get_sof_p1 == 1'b1)
      burst_len[3:0] <= 4'h0;
    else if(byte_count[5:0] == 6'd1 && rx_buffer_data_present_i == 1'b1)
      burst_len[3:0] <= rx_data_out_i[3:0];
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      base_addr[15:0] <= 16'h0;
    else if(get_sof_done == 1'b0 && get_sof_p1 == 1'b1)
      base_addr[15:0] <= 16'h0;
    else if(byte_count[5:0] == 6'd2 && rx_buffer_data_present_i == 1'b1)
      base_addr[15:8] <= rx_data_out_i[7:0];
    else if(byte_count[5:0] == 6'd3 && rx_buffer_data_present_i == 1'b1)
      base_addr[7:0] <= rx_data_out_i[7:0];
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      expected_count[5:0] <= 6'd63;
    else if(read_reg == 1'b1)
      expected_count[5:0] <= 6'd5;
    else if(write_reg == 1'b1)
      expected_count[5:0] <= 6'd5 + {burst_len_p1, 1'b0};
  end
    
  //reserve burst write data
  reg  [15:0]  write_data0;
  reg  [15:0]  write_data1;
  reg  [15:0]  write_data2;
  reg  [15:0]  write_data3;
  reg  [15:0]  write_data4;
  reg  [15:0]  write_data5;
  reg  [15:0]  write_data6;
  reg  [15:0]  write_data7;
  reg  [15:0]  write_data8;
  reg  [15:0]  write_data9;
  reg  [15:0]  write_dataa;
  reg  [15:0]  write_datab;
  reg  [15:0]  write_datac;
  reg  [15:0]  write_datad;
  reg  [15:0]  write_datae;
  reg  [15:0]  write_dataf;
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      write_data0 <= 16'h0;
      write_data1 <= 16'h0;
      write_data2 <= 16'h0;
      write_data3 <= 16'h0;
      write_data4 <= 16'h0;
      write_data5 <= 16'h0;
      write_data6 <= 16'h0;
      write_data7 <= 16'h0;
      write_data8 <= 16'h0;
      write_data9 <= 16'h0;
      write_dataa <= 16'h0;
      write_datab <= 16'h0;
      write_datac <= 16'h0;
      write_datad <= 16'h0;
      write_datae <= 16'h0;
      write_dataf <= 16'h0;
    end 
    else if(get_sof_done == 1'b0 && get_sof_p1 == 1'b1) begin
      write_data0 <= 16'h0;
      write_data1 <= 16'h0;
      write_data2 <= 16'h0;
      write_data3 <= 16'h0;
      write_data4 <= 16'h0;
      write_data5 <= 16'h0;
      write_data6 <= 16'h0;
      write_data7 <= 16'h0;
      write_data8 <= 16'h0;
      write_data9 <= 16'h0;
      write_dataa <= 16'h0;
      write_datab <= 16'h0;
      write_datac <= 16'h0;
      write_datad <= 16'h0;
      write_datae <= 16'h0;
      write_dataf <= 16'h0;
    end
    else if(rx_buffer_data_present_i == 1'b1 && write_reg == 1'b1) begin
      case(byte_count[5:0])
        6'd4:     write_data0[15:8] <= rx_data_out_i;  
        6'd5:     write_data0[7:0]  <= rx_data_out_i;
        6'd6:     write_data1[15:8] <= rx_data_out_i;  
        6'd7:     write_data1[7:0]  <= rx_data_out_i;
        6'd8:     write_data2[15:8] <= rx_data_out_i;  
        6'd9:     write_data2[7:0]  <= rx_data_out_i;
        6'd10:    write_data3[15:8] <= rx_data_out_i;  
        6'd11:    write_data3[7:0]  <= rx_data_out_i;
        6'd12:    write_data4[15:8] <= rx_data_out_i;  
        6'd13:    write_data4[7:0]  <= rx_data_out_i;
        6'd14:    write_data5[15:8] <= rx_data_out_i;  
        6'd15:    write_data5[7:0]  <= rx_data_out_i;
        6'd16:    write_data6[15:8] <= rx_data_out_i;  
        6'd17:    write_data6[7:0]  <= rx_data_out_i;
        6'd18:    write_data7[15:8] <= rx_data_out_i;  
        6'd19:    write_data7[7:0]  <= rx_data_out_i;
        6'd20:    write_data8[15:8] <= rx_data_out_i;  
        6'd21:    write_data8[7:0]  <= rx_data_out_i;
        6'd22:    write_data9[15:8] <= rx_data_out_i;  
        6'd23:    write_data9[7:0]  <= rx_data_out_i;
        6'd24:    write_dataa[15:8] <= rx_data_out_i;  
        6'd25:    write_dataa[7:0]  <= rx_data_out_i;
        6'd26:    write_datab[15:8] <= rx_data_out_i;  
        6'd27:    write_datab[7:0]  <= rx_data_out_i;
        6'd28:    write_datac[15:8] <= rx_data_out_i;  
        6'd29:    write_datac[7:0]  <= rx_data_out_i;
        6'd30:    write_datad[15:8] <= rx_data_out_i;  
        6'd31:    write_datad[7:0]  <= rx_data_out_i;
        6'd32:    write_datae[15:8] <= rx_data_out_i;  
        6'd33:    write_datae[7:0]  <= rx_data_out_i;
        6'd34:    write_dataf[15:8] <= rx_data_out_i;  
        6'd35:    write_dataf[7:0]  <= rx_data_out_i;
      endcase
    end
  end

  //get FCS and compare
  reg  [7:0]  calculated_fcs;
  wire [7:0]  received_fcs = rx_data_out_i;
  reg         fcs_matched;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      calculated_fcs <= 8'h0;
    else if(get_sof_done == 1'b0 && get_sof_p1 == 1'b1)
      calculated_fcs <= 8'h0;
    else if(byte_count > 0 && rx_buffer_data_present_i == 1'b1)
      calculated_fcs <= calculated_fcs ^ rx_data_out_i;
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      fcs_matched <= 1'b0;
    else if(get_sof_done == 1'b0 && get_sof_p1 == 1'b1)
      fcs_matched <= 1'b0;
    else if(byte_count == (expected_count-1) && rx_buffer_data_present_i == 1'b1)
      fcs_matched <= (calculated_fcs[7:0] == received_fcs[7:0]);
  end

  //++
  //on chip bus register write access
  //--
  reg         write_in_progress;
  reg  [3:0]  write_count;
  reg         write_toggle;  //write need two cycles.
  reg  [15:0] write_addr;
  reg         write_enable;
  reg  [15:0] write_data; 


  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      write_in_progress <= 1'b0;
    else if(fcs_matched == 1'b1 && write_reg == 1'b1 && get_eof_done == 1'b0 && get_eof_p1 == 1'b1)
      write_in_progress <= 1'b1;
    else if(write_count == burst_len && write_toggle == 1'b1)
      write_in_progress <= 1'b0;
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      write_toggle <= 1'b0;
    else if(get_sof_done == 1'b0 && get_sof_p1 == 1'b1)
      write_toggle <= 1'b0;
    else if(write_in_progress == 1'b1)
      write_toggle <= ~write_toggle;
  end
      
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      write_count <= 4'h0;
    else if(get_sof_done == 1'b0 && get_sof_p1 == 1'b1)
      write_count <= 4'h0;
    else if(write_in_progress == 1'b1 && write_toggle == 1'b1)
      write_count <= write_count + 1;
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      write_addr <= 16'h0;
    else
      write_addr <= base_addr + {12'h0, write_count};
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      write_enable <= 1'b0;
    else if(write_in_progress == 1'b1)
      write_enable <= 1'b1;
    else
      write_enable <= 1'b0;
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      write_data <= 16'h0;
    else if(write_in_progress == 1'b1)
      case(write_count)
        4'h0:    write_data <= write_data0;
        4'h1:    write_data <= write_data1;
        4'h2:    write_data <= write_data2;
        4'h3:    write_data <= write_data3;
        4'h4:    write_data <= write_data4;
        4'h5:    write_data <= write_data5;
        4'h6:    write_data <= write_data6;
        4'h7:    write_data <= write_data7;
        4'h8:    write_data <= write_data8;
        4'h9:    write_data <= write_data9;
        4'ha:    write_data <= write_dataa;
        4'hb:    write_data <= write_datab;
        4'hc:    write_data <= write_datac;
        4'hd:    write_data <= write_datad;
        4'he:    write_data <= write_datae;
        4'hf:    write_data <= write_dataf;
      endcase
  end


  //++
  //on chip bus register read  access
  //--
  reg         read_in_progress;
  reg  [3:0]  read_count;
  reg         read_toggle;  //read need two cycles.
  reg  [15:0] read_addr;
  reg         read_enable;
  reg  [15:0] read_data0; 
  reg  [15:0] read_data1;
  reg  [15:0] read_data2;
  reg  [15:0] read_data3;
  reg  [15:0] read_data4;
  reg  [15:0] read_data5;
  reg  [15:0] read_data6;
  reg  [15:0] read_data7;
  reg  [15:0] read_data8;
  reg  [15:0] read_data9;
  reg  [15:0] read_dataa;
  reg  [15:0] read_datab;
  reg  [15:0] read_datac;
  reg  [15:0] read_datad;
  reg  [15:0] read_datae;
  reg  [15:0] read_dataf;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      read_in_progress <= 1'b0;
    else if(fcs_matched == 1'b1 && read_reg == 1'b1 && get_eof_done == 1'b0 && get_eof_p1 == 1'b1)
      read_in_progress <= 1'b1;
    else if(read_count == burst_len && read_toggle == 1'b1)
      read_in_progress <= 1'b0;
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      read_toggle <= 1'b0;
    else if(get_sof_done == 1'b0 && get_sof_p1 == 1'b1)
      read_toggle <= 1'b0;
    else if(read_in_progress == 1'b1)
      read_toggle <= ~read_toggle;
  end
      
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      read_count <= 4'h0;
    else if(get_sof_done == 1'b0 && get_sof_p1 == 1'b1)
      read_count <= 4'h0;
    else if(read_in_progress == 1'b1 && read_toggle == 1'b1)
      read_count <= read_count + 1;
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      read_addr <= 16'h0;
    else
      read_addr <= base_addr + {12'h0, read_count};
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      read_enable <= 1'b0;
    else if(read_in_progress == 1'b1)
      read_enable <= 1'b1;
    else
      read_enable <= 1'b0;
  end

  reg         read_in_progress_d1, read_in_progress_d2;
  reg  [3:0]  read_count_d1, read_count_d2;
  reg         read_toggle_d1, read_toggle_d2;  //read need two cycles.

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      {read_in_progress_d1, read_in_progress_d2} <= 2'b0;
      {read_count_d1, read_count_d2}             <= 8'h0;
      {read_toggle_d1, read_toggle_d2}           <= 2'b0;
    end
    else begin
      {read_in_progress_d1, read_in_progress_d2} <= {read_in_progress, read_in_progress_d1};
      {read_count_d1, read_count_d2}             <= {read_count, read_count_d1}            ;
      {read_toggle_d1, read_toggle_d2}           <= {read_toggle, read_toggle_d1}          ;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      read_data0 <= 16'h0;
      read_data1 <= 16'h0;
      read_data2 <= 16'h0;
      read_data3 <= 16'h0;
      read_data4 <= 16'h0;
      read_data5 <= 16'h0;
      read_data6 <= 16'h0;
      read_data7 <= 16'h0;
      read_data8 <= 16'h0;
      read_data9 <= 16'h0;
      read_dataa <= 16'h0;
      read_datab <= 16'h0;
      read_datac <= 16'h0;
      read_datad <= 16'h0;
      read_datae <= 16'h0;
      read_dataf <= 16'h0;
    end
    else if(read_in_progress_d2 == 1'b1 && read_toggle_d2 == 1'b0) begin
      case(read_count_d2)
        4'h0:    read_data0 <= ip2bus_data_i;
        4'h1:    read_data1 <= ip2bus_data_i;
        4'h2:    read_data2 <= ip2bus_data_i;
        4'h3:    read_data3 <= ip2bus_data_i;
        4'h4:    read_data4 <= ip2bus_data_i;
        4'h5:    read_data5 <= ip2bus_data_i;
        4'h6:    read_data6 <= ip2bus_data_i;
        4'h7:    read_data7 <= ip2bus_data_i;
        4'h8:    read_data8 <= ip2bus_data_i;
        4'h9:    read_data9 <= ip2bus_data_i;
        4'ha:    read_dataa <= ip2bus_data_i;
        4'hb:    read_datab <= ip2bus_data_i;
        4'hc:    read_datac <= ip2bus_data_i;
        4'hd:    read_datad <= ip2bus_data_i;
        4'he:    read_datae <= ip2bus_data_i;
        4'hf:    read_dataf <= ip2bus_data_i;
      endcase
    end
  end

  //++
  //operate on uart rx buffer
  //--
  reg    get_eof_done_d1;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      get_eof_done_d1 <= 1'b0;
    else
      get_eof_done_d1 <= get_eof_done;
  end
  
  assign rx_read_buffer_o = (write_in_progress || read_in_progress || (get_eof_done & (~get_eof_done_d1))) ? 1'b0 : rx_buffer_data_present_i;


  //++
  //operate on uart tx buffer, compose a packet to host
  //--
  reg         tx_start;
  reg         tx_in_progress;
  reg  [5:0]  tx_count; 
  reg  [3:0]  tx_burst_len, tx_burst_len_z1;
  reg  [15:0] tx_base_addr, tx_base_addr_z1;

  wire [4:0] tx_burst_len_p1 = tx_burst_len_z1 + 1;
  wire [5:0] tx_byte_len = {tx_burst_len_p1, 1'b0};
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      tx_start <= 1'b0;
      tx_burst_len <= 4'h0;
      tx_base_addr <= 16'h0;
    end
    else if(read_in_progress_d2 == 1'b1 && read_in_progress_d1 == 1'b0) begin
      tx_start <= 1'b1;
      tx_burst_len <= burst_len;
      tx_base_addr <= base_addr;
    end
    else if(tx_in_progress == 1'b0) begin
      tx_start <= 1'b0;
      tx_burst_len <= 4'h0;
      tx_base_addr <= 16'h0;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      tx_in_progress <= 1'b0;
      tx_burst_len_z1 <= 4'h0;
      tx_base_addr_z1 <= 16'h0;
    end
    else if(tx_start == 1'b1 && tx_in_progress == 1'b0) begin
      tx_in_progress <= 1'b1;
      tx_burst_len_z1 <= tx_burst_len;
      tx_base_addr_z1 <= tx_base_addr;
    end
    else if(tx_count == (tx_byte_len+5) && tx_buffer_full_i == 1'b0 && tx_buffer_afull_i == 1'b0) begin
      tx_in_progress <= 1'b0;
      tx_burst_len_z1 <= 4'h0;
      tx_base_addr_z1 <= 16'h0;
    end
  end

  wire [5:0] tx_count_p1 = tx_count + 1;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      tx_count <= 6'h0;
    else if(tx_in_progress == 1'b1 && tx_buffer_full_i == 1'b0 && tx_buffer_afull_i == 1'b0)
      tx_count <= tx_count_p1;
    else if(tx_in_progress == 1'b0)
      tx_count <= 6'h0;
  end

  reg   [7:0]   tx_data_in_p1;
  reg   [7:0]   tx_fcs;

  always @(*) begin
    tx_data_in_p1 = 8'h0;

    if(tx_in_progress == 1'b1 && tx_buffer_full_i == 1'b0 && tx_buffer_afull_i == 1'b0) begin
      case(tx_count)
        6'd0   :  tx_data_in_p1 = 8'haa;
        6'd1   :  tx_data_in_p1 = {4'b0, tx_burst_len_z1};
        6'd2   :  tx_data_in_p1 = tx_base_addr_z1[15:8];
        6'd3   :  tx_data_in_p1 = tx_base_addr_z1[7:0];
        6'd4   :  tx_data_in_p1 = read_data0[15:8];
        6'd5   :  tx_data_in_p1 = read_data0[7:0];
        6'd6   :  tx_data_in_p1 = read_data1[15:8];
        6'd7   :  tx_data_in_p1 = read_data1[7:0];
        6'd8   :  tx_data_in_p1 = read_data2[15:8];
        6'd9   :  tx_data_in_p1 = read_data2[7:0];
        6'd10  :  tx_data_in_p1 = read_data3[15:8];
        6'd11  :  tx_data_in_p1 = read_data3[7:0];
        6'd12  :  tx_data_in_p1 = read_data4[15:8];
        6'd13  :  tx_data_in_p1 = read_data4[7:0];
        6'd14  :  tx_data_in_p1 = read_data5[15:8];
        6'd15  :  tx_data_in_p1 = read_data5[7:0];
        6'd16  :  tx_data_in_p1 = read_data6[15:8];
        6'd17  :  tx_data_in_p1 = read_data6[7:0];
        6'd18  :  tx_data_in_p1 = read_data7[15:8];
        6'd19  :  tx_data_in_p1 = read_data7[7:0];
        6'd20  :  tx_data_in_p1 = read_data8[15:8];
        6'd21  :  tx_data_in_p1 = read_data8[7:0];
        6'd22  :  tx_data_in_p1 = read_data9[15:8];
        6'd23  :  tx_data_in_p1 = read_data9[7:0];
        6'd24  :  tx_data_in_p1 = read_dataa[15:8];
        6'd25  :  tx_data_in_p1 = read_dataa[7:0];
        6'd26  :  tx_data_in_p1 = read_datab[15:8];
        6'd27  :  tx_data_in_p1 = read_datab[7:0];
        6'd28  :  tx_data_in_p1 = read_datac[15:8];
        6'd29  :  tx_data_in_p1 = read_datac[7:0];
        6'd30  :  tx_data_in_p1 = read_datad[15:8];
        6'd31  :  tx_data_in_p1 = read_datad[7:0];
        6'd32  :  tx_data_in_p1 = read_datae[15:8];
        6'd33  :  tx_data_in_p1 = read_datae[7:0];
        6'd34  :  tx_data_in_p1 = read_dataf[15:8];
        6'd35  :  tx_data_in_p1 = read_dataf[7:0];
      endcase
    end
  end


  reg  tx_in_progress_d1;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      tx_in_progress_d1 <= 0;
    else
      tx_in_progress_d1 <= tx_in_progress;
   end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      tx_fcs <= 8'h0;
    else if(tx_in_progress == 1'b1 && tx_in_progress_d1 == 1'b1 && tx_buffer_full_i == 1'b0 && tx_buffer_afull_i == 1'b0)
      tx_fcs <= tx_data_in_p1[7:0] ^ tx_fcs;
    else if(tx_in_progress == 1'b0)
      tx_fcs <= 8'h0;
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      tx_data_in_o <= 8'h0;
    else if(tx_in_progress == 1'b1 && tx_buffer_full_i == 1'b0 && tx_buffer_afull_i == 1'b0 && tx_count == (tx_byte_len+4))
      tx_data_in_o <= tx_fcs;
    else if(tx_in_progress == 1'b1 && tx_buffer_full_i == 1'b0 && tx_buffer_afull_i == 1'b0 && tx_count == (tx_byte_len+5))
      tx_data_in_o <= 8'hd5;
    else
      tx_data_in_o <= tx_data_in_p1;
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      tx_write_buffer_o <= 1'b0;
    else if(tx_in_progress == 1'b1 && tx_buffer_full_i == 1'b0 && tx_buffer_afull_i == 1'b0)
      tx_write_buffer_o <= 1'b1;
    else 
      tx_write_buffer_o <= 1'b0;
  end


  //++
  //deal with on-chip-bus signals
  //--
  reg write_in_progress_d1;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      write_in_progress_d1 <= 0;
    else
      write_in_progress_d1 <= write_in_progress;
  end

  assign bus2ip_clk     = clk; 
  assign bus2ip_rst_n   = rst_n;
  assign bus2ip_addr_o  = (write_in_progress == 1'b1 || write_in_progress_d1 == 1'b1) ? write_addr : read_addr;
  assign bus2ip_data_o  = write_data;
  assign bus2ip_rd_ce_o = read_enable;
  assign bus2ip_wr_ce_o = write_enable;

endmodule
