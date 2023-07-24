/*++
// tx ptp frame buffer 
// for simplicity, just behavioral
--*/

`include "ptpv2_defines.v"

module tx_ptp_buf (
  //tx interface
  input               tx_clk,
  input               tx_rst_n,
  
  output reg [63:0]   xge_txd_o,
  output reg [7:0]    xge_txc_o,

  //32 bits on chip bus access interface
  input               bus2ip_clk   ,
  input               bus2ip_rst_n  ,
  input  [31:0]       bus2ip_addr_i ,
  input  [31:0]       bus2ip_data_i ,
  input               bus2ip_rd_ce_i ,         //active high
  input               bus2ip_wr_ce_i ,         //active high
  output reg [31:0]   ip2bus_data_o   
);
  parameter TX_BUF_BADDR = 32'h2000;
  reg  [31:0] wr_buf[127:0]; //tx buffer
  reg  [8:0]  frm_len;
  reg         tx_start, tx_start_d1, tx_start_d2;

  //bus write operation
  wire [31:0] masked_addr  = bus2ip_addr_i & 32'h1ff;
  wire [6:0]  shifted_addr = masked_addr[8:2];
  
  always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
    if(!bus2ip_rst_n) begin
      frm_len  <= 0;
      tx_start <= 0;
    end
    else if(bus2ip_wr_ce_i == 1'b1 && bus2ip_addr_i == TX_BUF_BADDR + 32'h200) begin   //frm_len and tx_start signal
      frm_len  <= bus2ip_data_i[8:0];
      tx_start <= bus2ip_data_i[15];
    end
    else if(bus2ip_wr_ce_i == 1'b1 && bus2ip_addr_i >= TX_BUF_BADDR && bus2ip_addr_i < (TX_BUF_BADDR+32'h200)) begin   
      wr_buf[shifted_addr] <= bus2ip_data_i[31:0];
    end
    else begin  //clear self-clearing register bits
      if(tx_start_d2 == 1'b1)   tx_start   <= 0 ;
    end
  end

  always @(posedge bus2ip_clk or negedge bus2ip_rst_n) begin
    if(!bus2ip_rst_n) begin
      {tx_start_d1,  tx_start_d2} <= 2'b0;
    end
    else begin
      {tx_start_d1,  tx_start_d2} <= {tx_start,  tx_start_d1};
    end
  end

  //bus read operation
  always @(*) begin
    if(bus2ip_rd_ce_i == 1'b1 && bus2ip_addr_i == TX_BUF_BADDR + 32'h200) //frame length
      ip2bus_data_o[31:0] = {16'b0, tx_start, 6'b0, frm_len};
    else if(bus2ip_rd_ce_i == 1'b1 && bus2ip_addr_i >= TX_BUF_BADDR && bus2ip_addr_i < (TX_BUF_BADDR+32'h200)) 
      ip2bus_data_o[31:0] = wr_buf[shifted_addr];
    else
      ip2bus_data_o[31:0] = 32'h0;
  end

  //++
  //transmit data to xgmii, use state machine
  //--
  parameter TX_IDLE = 2'd0, TX_FIRST = 2'd1, TX_DATA = 2'd2, TX_LAST = 2'd3;
  reg  [1:0] cstate, nstate;

  //start signal delay in tx_clk domain
  reg  tx_start_z1, tx_start_z2, tx_start_z3; 
  wire  start_pul = tx_start_z2 & (~tx_start_z3);

  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n) begin
      {tx_start_z1,  tx_start_z2, tx_start_z3} <= 3'b0;
    end
    else begin
      {tx_start_z1,  tx_start_z2, tx_start_z3} <= {tx_start,  tx_start_z1, tx_start_z2};
    end
  end

  reg  [8:0]  eth_count;
  wire [8:0]  tx_octets = (eth_count >= 8) ? eth_count - 8 : 0;
  wire last_p = ((tx_octets+16) > frm_len) ? 1 : 0;

  //state transition
  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n) 
      cstate <= TX_IDLE;
    else 
      cstate <= nstate;
  end

  //next state switch
  always @(*) begin
    nstate = cstate;
    case(cstate)
      TX_IDLE:
        if(start_pul == 1'b1)
          nstate = TX_FIRST;
      TX_FIRST:               //transmit START code
        nstate = TX_DATA;
      TX_DATA:                //transmit normal data
        if(last_p == 1'b1)
          nstate = TX_LAST;
      TX_LAST:                //transmit TERMINATE code
        nstate = TX_IDLE;
    endcase
  end

  //output logic of state machine
  wire [6:0]  addr0 = tx_octets[8:2];
  wire [6:0]  addr1 = addr0 + 1;
  wire [63:0] data_tuple = {wr_buf[addr1], wr_buf[addr0]};
  wire [8:0]  res_len = frm_len - tx_octets;

  always @(posedge tx_clk or negedge tx_rst_n) begin : TX_XGMII
    if(!tx_rst_n) begin
      xge_txd_o <= {8{`IDLE}};
      xge_txc_o <= 8'hff;
      eth_count <= 0;
    end
    else if(cstate == TX_IDLE) begin
      xge_txd_o <= {8{`IDLE}};
      xge_txc_o <= 8'hff;
      eth_count <= 0;
    end
    else if(cstate == TX_FIRST) begin
      xge_txd_o <= {`SFD, {6{`PREAMBLE}}, `START};
      xge_txc_o <= 8'h01;
      eth_count <= eth_count + 8;
    end
    else if(cstate == TX_DATA) begin
      xge_txd_o <= data_tuple;
      xge_txc_o <= 8'h0;
      eth_count <= eth_count + 8;
    end
    else if(cstate == TX_LAST) begin
      case (res_len[2:0])
        3'd0: begin
          xge_txd_o <= {{7{`IDLE}}, `TERMINATE};
          xge_txc_o <= 8'b1111_1111;
        end
        3'd1: begin
          xge_txd_o <= {{6{`IDLE}}, `TERMINATE, data_tuple[7:0]};
          xge_txc_o <= 8'b1111_1110;
          eth_count <= eth_count + 1;
        end
        3'd2: begin
          xge_txd_o <= {{5{`IDLE}}, `TERMINATE, data_tuple[15:0]};
          xge_txc_o <= 8'b1111_1100;
          eth_count <= eth_count + 2;
        end
        3'd3: begin
          xge_txd_o <= {{4{`IDLE}}, `TERMINATE, data_tuple[23:0]};
          xge_txc_o <= 8'b1111_1000;
          eth_count <= eth_count + 3;
        end
        3'd4: begin
          xge_txd_o <= {{3{`IDLE}}, `TERMINATE, data_tuple[31:0]};
          xge_txc_o <= 8'b1111_0000;
          eth_count <= eth_count + 4;
        end
        3'd5: begin
          xge_txd_o <= {{2{`IDLE}}, `TERMINATE, data_tuple[39:0]};
          xge_txc_o <= 8'b1110_0000;
          eth_count <= eth_count + 5;
        end
        3'd6: begin
          xge_txd_o <= {`IDLE, `TERMINATE, data_tuple[47:0]};
          xge_txc_o <= 8'b1100_0000;
          eth_count <= eth_count + 6;
        end
        3'd7: begin
          xge_txd_o <= {`TERMINATE, data_tuple[55:0]};
          xge_txc_o <= 8'b1000_0000;
          eth_count <= eth_count + 7;
        end
      endcase
    end
  end

endmodule


