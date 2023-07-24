/*++
//  calculate ipv6 udp checksum then output the last two padding octets
//  refer to rfc768
--*/

`include "ptpv2_defines.v"

module ipv6_udp_chksum(
  input               tx_clk,
  input               tx_rst_n,              //async reset, active low
  input               tx_clk_en_i,

  input               ipv6_udp_chk_en_i,     
  input  [10:0]       eth_count_base_i,
  input               ipv6_flag_i,
  input  [10:0]       ipv6_addr_base_i,
  input  [10:0]       ptp_addr_base_i,
  input               is_ptp_message_i,

  input  [63:0]       txd_i,
  input  [7:0]        txc_i,

  input  [15:0]       ptp_messageLength_i,
  input  [3:0]        ptp_messageType_i,

  output reg          ipv6_padchg_flag_o,   //change udp padding octets or not
  output reg [10:0]   chkpad_addr_base_o,
  output reg [15:0]   chksum_pad_o
);
  genvar i;

  wire  chksum_calc_en = ipv6_udp_chk_en_i & ipv6_flag_i;

  //base address of ipv6 udp padding octets 
  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n)
      chkpad_addr_base_o <= 11'h0;
    else if(tx_clk_en_i) begin
      if(chksum_calc_en == 1'b1)
        chkpad_addr_base_o <= ptp_addr_base_i + ptp_messageLength_i[10:0];
      else
        chkpad_addr_base_o <= 11'h0;
    end
  end

  //change flag of padding octets
  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n)
      ipv6_padchg_flag_o <= 0;
    else if(tx_clk_en_i) begin
      if(chksum_calc_en == 1'b1 && is_ptp_message_i == 1'b1 && ptp_messageType_i[3] == 1'b0)
        ipv6_padchg_flag_o <= 1;
      else
        ipv6_padchg_flag_o <= 0;
    end
  end

  //simply detect the end of frame, 1 cycle pulse
  reg      simple_efd, simple_efd_z1;
  always @(*) begin
    simple_efd = 0;

    if((txd_i[`LANE0] == `TERMINATE && txc_i[0]) || (txd_i[`LANE1] == `TERMINATE && txc_i[1]) ||
	     (txd_i[`LANE2] == `TERMINATE && txc_i[2]) || (txd_i[`LANE3] == `TERMINATE && txc_i[3]) ||
       (txd_i[`LANE4] == `TERMINATE && txc_i[4]) || (txd_i[`LANE5] == `TERMINATE && txc_i[5]) ||
	     (txd_i[`LANE6] == `TERMINATE && txc_i[6]) || (txd_i[`LANE7] == `TERMINATE && txc_i[7])) 
	  simple_efd = 1; 
  end

  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n)
      simple_efd_z1 <= 0;
    else if(tx_clk_en_i) 
      simple_efd_z1 <= simple_efd;
  end

  //++
  //get udp header information
  //--
  reg   [15:0]    udp_srcPort;
  reg   [15:0]    udp_dstPort;
  reg   [15:0]    udp_length;
  reg   [15:0]    udp_chksum;

  reg   [15:0]    udp_srcPort_lane[7:0];
  reg   [15:0]    udp_dstPort_lane[7:0];
  reg   [15:0]    udp_length_lane[7:0];
  reg   [15:0]    udp_chksum_lane[7:0];

  generate
    for(i = 0; i < 8; i = i+1) begin : PARSE_UDP_HEADER
      reg [10:0]   eth_count;
      reg [7:0]    txd_lane;

      reg [15:0]   udp_srcPort_tmp;
      reg [15:0]   udp_dstPort_tmp;
      reg [15:0]   udp_length_tmp;
      reg [15:0]   udp_chksum_tmp;

      always @(*) begin
        eth_count = eth_count_base_i + i;
        txd_lane  = txd_i[8*i+7: 8*i];
      end

      always @(*) begin
        udp_srcPort_tmp = udp_srcPort;
        udp_dstPort_tmp = udp_dstPort;
        udp_length_tmp  = udp_length;
        udp_chksum_tmp  = udp_chksum;

        if(chksum_calc_en == 1'b1 && !txc_i[i]) begin
          if(eth_count == ipv6_addr_base_i+40)  udp_srcPort_tmp[15:8] = txd_lane;
          if(eth_count == ipv6_addr_base_i+41)  udp_srcPort_tmp[7:0]  = txd_lane;
          if(eth_count == ipv6_addr_base_i+42)  udp_dstPort_tmp[15:8] = txd_lane;
          if(eth_count == ipv6_addr_base_i+43)  udp_dstPort_tmp[7:0]  = txd_lane;
          if(eth_count == ipv6_addr_base_i+44)  udp_length_tmp[15:8]  = txd_lane;
          if(eth_count == ipv6_addr_base_i+45)  udp_length_tmp[7:0]   = txd_lane;
          if(eth_count == ipv6_addr_base_i+46)  udp_chksum_tmp[15:8]  = txd_lane;
          if(eth_count == ipv6_addr_base_i+47)  udp_chksum_tmp[7:0]   = txd_lane;
        end
        else if(simple_efd_z1 == 1) begin
          udp_srcPort_tmp = 16'h0;
          udp_dstPort_tmp = 16'h0;
          udp_length_tmp  = 16'h0;
          udp_chksum_tmp  = 16'h0;
        end
      end //always

      always @(*) begin
        udp_srcPort_lane[i] = udp_srcPort_tmp;
        udp_dstPort_lane[i] = udp_dstPort_tmp;
        udp_length_lane[i]  = udp_length_tmp;
        udp_chksum_lane[i]  = udp_chksum_tmp;
      end
    end //for i
  endgenerate

  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n) begin
      udp_srcPort  <= 16'h0;
      udp_dstPort  <= 16'h0;
      udp_length   <= 16'h0;
      udp_chksum   <= 16'h0;
    end
    else if(tx_clk_en_i) begin 
      udp_srcPort  <= `OR_LANE(udp_srcPort_lane);     
      udp_dstPort  <= `OR_LANE(udp_dstPort_lane);
      udp_length   <= `OR_LANE(udp_length_lane);         
      udp_chksum   <= `OR_LANE(udp_chksum_lane);         
    end
  end

  //delay xgmii-like data
  reg    [63:0] txd_z1;
  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n) begin
      txd_z1 <= 64'h0;
    end
    else if(tx_clk_en_i) begin 
      txd_z1 <= txd_i;
    end
  end

  //++
  //generate addends for calculation of checksum
  //--
  reg  [31:0] addend_lane[7:0];
  wire [7:0] txd_lane_z1_max = txd_z1[`LANE7];

  generate
    for(i = 0; i < 8; i = i+1) begin : GENERATE_ADDEND
      reg [10:0]   eth_count;
      reg [7:0]    txd_lane;
      reg [7:0]    txd_lane_z1;
      reg [17:0]   addend_tmp;

      always @(*) begin
        eth_count = eth_count_base_i + i;
        txd_lane = txd_i[8*i+7: 8*i];

        txd_lane_z1 = 8'h0;
        case(i)
          'd0 : txd_lane_z1 = txd_lane_z1_max;
          'd1 : txd_lane_z1 = txd_i[7:0];
          'd2 : txd_lane_z1 = txd_i[15:8];
          'd3 : txd_lane_z1 = txd_i[23:16];
          'd4 : txd_lane_z1 = txd_i[31:24];
          'd5 : txd_lane_z1 = txd_i[39:32];
          'd6 : txd_lane_z1 = txd_i[47:40];
          'd7 : txd_lane_z1 = txd_i[55:48];
          default: ;
        endcase
      end

      always @(*) begin
        addend_tmp    = 18'h0;
        
        //ipv6 next header and zeros, (16 bits zeros omitted)
        if(eth_count == ipv6_addr_base_i+6)  
          addend_tmp = {10'h0, txd_lane};
        
        //ipv6 src address and dst address, udp src port and dst port
        if(eth_count >= (ipv6_addr_base_i+8) && eth_count <= (ipv6_addr_base_i+43)) 
          addend_tmp = {2'b0, txd_lane_z1, txd_lane};

        //udp length, repeat two times
        if(eth_count == (ipv6_addr_base_i+45)) 
          addend_tmp = {1'b0, txd_lane_z1, txd_lane, 1'b0};

        //udp check sum, set to zero 
        if(eth_count == (ipv6_addr_base_i+47)) 
          addend_tmp = 18'h0;

        //udp data, before reach the padding octets
        if(eth_count >= ptp_addr_base_i && eth_count < (ptp_addr_base_i+ptp_messageLength_i[10:0])) 
          addend_tmp = {2'b0, txd_lane_z1, txd_lane};
      end //always

      always @(*) begin
        addend_lane[i] = {14'b0, addend_tmp};
      end
    end //for i
  endgenerate

  reg  [7:0]    add_toggle, add_toggle_z1;
  reg  [7:0]    add_valid;
  wire add_toggle_z1_max = add_toggle_z1[7];

  function shift_add_toggle;
    input [3:0] index;
    input [7:0] add_toggle_val;

    begin
      case(index)
        'd1 : shift_add_toggle = add_toggle_val[0];
        'd2 : shift_add_toggle = add_toggle_val[1];
        'd3 : shift_add_toggle = add_toggle_val[2];
        'd4 : shift_add_toggle = add_toggle_val[3];
        'd5 : shift_add_toggle = add_toggle_val[4];
        'd6 : shift_add_toggle = add_toggle_val[5];
        'd7 : shift_add_toggle = add_toggle_val[6];
        default : shift_add_toggle = 0;
      endcase
    end
  endfunction

  generate
    for(i = 0; i < 8; i = i+1) begin : GENERATE_ADD_TOGGLE
      reg [10:0]   eth_count;

      always @(*) begin
        eth_count = eth_count_base_i + i;
      end

      always @(*) begin
        add_toggle[i] = 0;
        if(eth_count <= (ipv6_addr_base_i+8))
          add_toggle[i] = 0;
        else if(chksum_calc_en == 1'b1 && !txc_i[i] && i > 0)
          //add_toggle[i] = ~add_toggle[i-1];
          add_toggle[i] = ~shift_add_toggle(i, add_toggle);
        else if(chksum_calc_en == 1'b1 && !txc_i[i] && i == 0)
          add_toggle[i] = ~add_toggle_z1_max;
        else if(simple_efd_z1 == 1)
          add_toggle[i] = 0;
      end //always-- add toggle

      always @(*) begin
        add_valid = 0;

        //ipv6 next header and zeros, (16 bits zeros omitted)
        if(eth_count == ipv6_addr_base_i+6)  
          add_valid[i] = (!txc_i[i]);
        
        //ipv6 src address and dst address, udp src port and dst port
        if(eth_count >= (ipv6_addr_base_i+8) && eth_count <= (ipv6_addr_base_i+43)) 
          add_valid[i] = ((!txc_i[i]) & add_toggle[i]);

        //udp length, repeat two times
        if(eth_count == (ipv6_addr_base_i+45)) 
          add_valid[i] = ((!txc_i[i]) & add_toggle[i]);

        //udp check sum, set to zero value
        if(eth_count == (ipv6_addr_base_i+47)) 
          add_valid[i] = ((!txc_i[i]) & add_toggle[i]);

        //udp data, before reach the padding octets
        if(eth_count >= ptp_addr_base_i && eth_count < (ptp_addr_base_i+ptp_messageLength_i[10:0])) 
          add_valid[i] = ((!txc_i[i]) & add_toggle[i]);
      end  //always-- add valid

    end //for i
  endgenerate

  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n) 
      add_toggle_z1 <= 8'h0;
    else if(tx_clk_en_i) 
      add_toggle_z1 <= add_toggle;
  end

  //++
  //calculate udp check sum, only ptp event message need this
  //message length of ptp event message is always times of 2 octets.
  //udp_checksum = ~(c+m) -->~udp_checksum+(~c) = m;
  //--

  reg    [31:0] sum_p1;
  reg    [31:0] sum;

  reg    [16:0] c_sum;
  wire   [15:0] c_p1;
  wire   [15:0] c_p1_inv;
  wire   [15:0] udp_chksum_inv;
  wire   [16:0] m_sum;
  wire   [15:0] chksum_pad_p1;
  
  reg  [31:0] addend0, addend1, addend2, addend3;

  always @(*) begin
    addend0 = (add_valid[0] == 1) ? addend_lane[0] :
              ((add_valid[1] == 1) ? addend_lane[1] : 32'h0);
    addend1 = (add_valid[2] == 1) ? addend_lane[2] :
              ((add_valid[3] == 1) ? addend_lane[3] : 32'h0);
    addend2 = (add_valid[4] == 1) ? addend_lane[4] :
              ((add_valid[5] == 1) ? addend_lane[5] : 32'h0);
    addend3 = (add_valid[6] == 1) ? addend_lane[6] :
              ((add_valid[7] == 1) ? addend_lane[7] : 32'h0);

    sum_p1 = sum + ((addend0 + addend1) + (addend2 + addend3));
  end

  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n) 
      sum <= 32'h0;
    else if(tx_clk_en_i) begin
      if(simple_efd_z1 == 1)
        sum <= 32'h0;
      else
        sum <= sum_p1;
    end
  end

  //compute checksum padding octets, one's complement
  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n) 
      c_sum <= 17'h0;
    else if(tx_clk_en_i) begin
      if(simple_efd_z1 == 1) 
        c_sum <= 17'h0;
      else
        c_sum <= {1'b0, sum_p1[31:16]} + {1'b0, sum_p1[15:0]};
    end
  end

  //assign c_p1[15:0] = sum[31:16] + sum[15:0];
  assign c_p1[15:0] = c_sum[15:0] + {15'b0, c_sum[16]};
  assign c_p1_inv[15:0] = ~c_p1[15:0];

  assign udp_chksum_inv[15:0] = ~udp_chksum[15:0];
  assign m_sum[16:0] = {1'b0, udp_chksum_inv[15:0]} + {1'b0, c_p1_inv[15:0]};
  assign chksum_pad_p1[15:0] = m_sum[15:0] + {15'b0, m_sum[16]};

  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n) 
      chksum_pad_o <= 16'h0;
    else if(tx_clk_en_i) begin
      if(simple_efd_z1 == 1)
        chksum_pad_o <= 16'h0;
      else
        chksum_pad_o <= chksum_pad_p1;
    end
  end

endmodule  

