/*++
//  crc recalculation for xgmii-like interface.
//  start of frame should be : S Dp Dp Dp Dp Dp Dp SFD
--*/

`include "ptpv2_defines.v"

module xge_crc (
  input               clk,                    //data clock
  input               rst_n,
  input               clk_en_i,               //for adapting to gmii/mii

  input               rpl_flag_i,             //replace original crc or not
  
  //xgmii-like data, 3 samples before
  input  [63:0]       xd_p3_i,
  input  [7:0]        xc_p3_i,                  
  
  //xgmii-like data, current input
  input  [63:0]       xd_i,
  input  [7:0]        xc_i,                  

  //xgmii-like data, output
  output reg [63:0]   xd_o,
  output reg [7:0]    xc_o
);
`include "utils.v"
  //start of frame, determined by START code only.
  reg     simple_sfd, simple_sfd_z1, simple_sfd_z2, simple_sfd_z3, simple_sfd_z4, simple_sfd_z5;     
  //end of frame
  reg     simple_efd_p3, simple_efd_p2, simple_efd_p1, simple_efd, simple_efd_z1;  

  //simply determine start of frame by using START code only, 1 sample pulse
  always @(*) begin
    simple_sfd = 0;
    if((xd_i[`LANE0] == `START && xc_i[0]) || (xd_i[`LANE1] == `START && xc_i[1]) ||
       (xd_i[`LANE2] == `START && xc_i[2]) || (xd_i[`LANE3] == `START && xc_i[3]) || 
       (xd_i[`LANE4] == `START && xc_i[4]) || (xd_i[`LANE5] == `START && xc_i[5]) ||
       (xd_i[`LANE5] == `START && xc_i[6]) || (xd_i[`LANE7] == `START && xc_i[7])) 
      simple_sfd = 1;
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      {simple_sfd_z1, simple_sfd_z2, simple_sfd_z3, simple_sfd_z4, simple_sfd_z5} <= 5'b0;
    else if(clk_en_i)
      {simple_sfd_z1, simple_sfd_z2, simple_sfd_z3, simple_sfd_z4, simple_sfd_z5} <= {simple_sfd, 
                      simple_sfd_z1, simple_sfd_z2, simple_sfd_z3, simple_sfd_z4};
  end
  //determine the lane number of start code
  reg   [3:0] start_loc, start_loc_z1;
  always @(*) begin
    start_loc = start_loc_z1;
    if(xd_i[`LANE0] == `START && xc_i[0])
      start_loc = 0;
    else if(xd_i[`LANE1] == `START && xc_i[1])
      start_loc = 1;
    else if(xd_i[`LANE2] == `START && xc_i[2])
      start_loc = 2;
    else if(xd_i[`LANE3] == `START && xc_i[3])
      start_loc = 3;
    else if(xd_i[`LANE4] == `START && xc_i[4])
      start_loc = 4;
    else if(xd_i[`LANE5] == `START && xc_i[5])
      start_loc = 5;
    else if(xd_i[`LANE6] == `START && xc_i[6])
      start_loc = 6;
    else if(xd_i[`LANE7] == `START && xc_i[7])
      start_loc = 7;
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      start_loc_z1 <= 4'b0;
    else if(clk_en_i)
      start_loc_z1 <= start_loc;
  end
  
  //detect the end of frame, 3 samples before, 1 sample pulse
  always @(*) begin
    simple_efd_p3 = 0;
    if((xd_p3_i[`LANE0] == `TERMINATE && xc_p3_i[0]) || (xd_p3_i[`LANE1] == `TERMINATE && xc_p3_i[1]) ||
	     (xd_p3_i[`LANE2] == `TERMINATE && xc_p3_i[2]) || (xd_p3_i[`LANE3] == `TERMINATE && xc_p3_i[3]) ||
       (xd_p3_i[`LANE4] == `TERMINATE && xc_p3_i[4]) || (xd_p3_i[`LANE5] == `TERMINATE && xc_p3_i[5]) ||
	     (xd_p3_i[`LANE6] == `TERMINATE && xc_p3_i[6]) || (xd_p3_i[`LANE7] == `TERMINATE && xc_p3_i[7])) 
	    simple_efd_p3 = 1; 
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      {simple_efd_p2, simple_efd_p1, simple_efd, simple_efd_z1} <= 4'b0;
    else if(clk_en_i)
      {simple_efd_p2, simple_efd_p1, simple_efd, simple_efd_z1} <= {simple_efd_p3, simple_efd_p2, simple_efd_p1, simple_efd};
  end

  //determine the lane number of terminate code
  reg   [3:0] term_loc_p3, term_loc_p2;
  always @(*) begin
    term_loc_p3 = term_loc_p2;
    if(xd_p3_i[`LANE0] == `TERMINATE && xc_p3_i[0])
      term_loc_p3 = 0;
    else if(xd_p3_i[`LANE1] == `TERMINATE && xc_p3_i[1])
      term_loc_p3 = 1;
    else if(xd_p3_i[`LANE2] == `TERMINATE && xc_p3_i[2])
      term_loc_p3 = 2;
    else if(xd_p3_i[`LANE3] == `TERMINATE && xc_p3_i[3])
      term_loc_p3 = 3;
    else if(xd_p3_i[`LANE4] == `TERMINATE && xc_p3_i[4])
      term_loc_p3 = 4;
    else if(xd_p3_i[`LANE5] == `TERMINATE && xc_p3_i[5])
      term_loc_p3 = 5;
    else if(xd_p3_i[`LANE6] == `TERMINATE && xc_p3_i[6])
      term_loc_p3 = 6;
    else if(xd_p3_i[`LANE7] == `TERMINATE && xc_p3_i[7])
      term_loc_p3 = 7;
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      term_loc_p2 <= 4'b0;
    else if(clk_en_i)
      term_loc_p2 <= term_loc_p3;
  end

  //generate the data used to calculate crc
  reg         data_valid;
  reg  [63:0] data;
  reg  [3:0]  lane_num;

  always @(*) begin
    data_valid = 1'b0;
    data       = 64'h0;
    lane_num   = 4'h0;

    if(simple_sfd)
      data_valid = 0;
    else if(simple_sfd_z1) begin    //start of frame
      data_valid = 1;
      if(start_loc_z1 == 0) begin
        data[63:0] = xd_i[63:0];
        lane_num = 8;
      end
      else if(start_loc_z1 == 1) begin
        data[55:0] = xd_i[63:8];
        lane_num = 7;
      end
      else if(start_loc_z1 == 2) begin
        data[47:0] = xd_i[63:16];
        lane_num = 6;
      end
      else if(start_loc_z1 == 3) begin
        data[39:0] = xd_i[63:24];
        lane_num = 5;
      end
      else if(start_loc_z1 == 4) begin
        data[31:0] = xd_i[63:32];
        lane_num = 4;
      end
      else if(start_loc_z1 == 5) begin
        data[23:0] = xd_i[63:40];
        lane_num = 3;
      end
      else if(start_loc_z1 == 6) begin
        data[15:0] = xd_i[63:48];
        lane_num = 2;
      end
      else if(start_loc_z1 == 7) begin
        data[7:0] = xd_i[63:56];
        lane_num = 1;
      end
    end
    else if(simple_efd_p1 && (term_loc_p2 == 0 || term_loc_p2 == 1 || term_loc_p2 == 2 || term_loc_p2 == 3 || term_loc_p2 == 4)) begin
      data_valid = 1;
      data = xd_i;
      lane_num = term_loc_p2 + 4;
    end
    else if(simple_efd && (term_loc_p2 == 5 || term_loc_p2 == 6 ||  term_loc_p2 == 7)) begin
      data_valid = 1;
      data = xd_i;
      lane_num = term_loc_p2 - 4;
    end
    else if(simple_efd)
      data_valid = 0;
    else if(!xc_i[0] && !xc_i[1] && !xc_i[2] && !xc_i[3] && !xc_i[4] && !xc_i[5] && !xc_i[6] && !xc_i[7]) begin
      data_valid = 1;
      data = xd_i;
      lane_num = 8;
    end
  end  //always

  //calculate crc
  reg   [31:0] current_crc;
  reg   [31:0] next_crc;
  reg   [31:0] crc_out;

  always @(*) begin
    next_crc = (data_valid == 1) ? xgeCalculateCRC(data, lane_num, current_crc) : current_crc;
    crc_out = ~reverse_32b(next_crc);
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      current_crc <= {32{1'b1}};
    else if(clk_en_i) begin
      if(simple_sfd)
        current_crc <= {32{1'b1}};
      else
        current_crc <= next_crc;
    end
  end
  
  //replace crc, generate output xgmii data
  reg  [7:0]    xc_out;                  
  reg  [63:0]   xd_out;

  always  @(*) begin
    xc_out = xc_i;
    xd_out = xd_i;

    if(rpl_flag_i == 1) begin
      if(simple_efd_p1 && term_loc_p3 == 0)
        xd_out[63:32] = crc_out[31:0];
      if(simple_efd_p1 && term_loc_p3 == 1)
        xd_out[63:40] = crc_out[23:0];
      if(simple_efd && term_loc_p3 == 1)
        xd_out[7:0] = crc_out[31:24];
      if(simple_efd_p1 && term_loc_p3 == 2)
        xd_out[63:48] = crc_out[15:0];
      if(simple_efd && term_loc_p3 == 2)
        xd_out[15:0] = crc_out[31:16];
      if(simple_efd_p1 && term_loc_p3 == 3)
        xd_out[63:56] = crc_out[7:0];
      if(simple_efd && term_loc_p3 == 3)
        xd_out[23:0] = crc_out[31:8];
      if(simple_efd && term_loc_p3 == 4)
        xd_out[31:0] = crc_out[31:0];
      if(simple_efd && term_loc_p3 == 5)
        xd_out[39:8] = crc_out[31:0];
      if(simple_efd && term_loc_p3 == 6)
        xd_out[47:16] = crc_out[31:0];
      if(simple_efd && term_loc_p3 == 7)
        xd_out[55:24] = crc_out[31:0];
    end //if replace crc
  end //always

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      xc_o <= 8'h0;
      xd_o <= 64'h0;
    end
    else if(clk_en_i) begin
      xc_o <= xc_out;
      xd_o <= xd_out;
    end
  end

endmodule
