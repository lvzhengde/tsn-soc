/*++
// double rate xgmii to/from single rate xgmii
// note: just a behavioral function description 
//       unverified.
--*/

`include "ptpv2_defines.v"

module xgmii_dr2sr (
  input            clk,
  input            rst_n,
  
  input   [31:0]   dr_xd_i,
  input   [3:0]    dr_xc_i,
  output  [31:0]   dr_xd_o,
  output  [3:0]    dr_xc_o,

  input   [63:0]   sr_xd_i,
  input   [7:0]    sr_xc_i,
  output  [63:0]   sr_xd_o,
  output  [7:0]    sr_xc_o
);

  //double rate to single rate
  reg  [31:0] dr_xd_pos_d1;
  reg  [3:0]  dr_xc_pos_d1;
  reg  [31:0] dr_xd_neg_d1;
  reg  [3:0]  dr_xc_neg_d1;
  
  always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
      dr_xd_pos_d1 <= {4{`IDLE}};
      dr_xc_pos_d1 <= 4'hf;
    end
    else begin
      dr_xd_pos_d1 <= dr_xd_i;
      dr_xc_pos_d1 <= dr_xc_i;
    end
  end

  always @(negedge clk or negedge rst_n) begin
    if(~rst_n) begin
      dr_xd_neg_d1 <= {4{`IDLE}};
      dr_xc_neg_d1 <= 4'hf;
    end
    else begin
      dr_xd_neg_d1 <= dr_xd_i;
      dr_xc_neg_d1 <= dr_xc_i;
    end
  end

  assign  sr_xd_o = {dr_xd_neg_d1, dr_xd_pos_d1};
  assign  sr_xc_o = {dr_xc_neg_d1, dr_xc_pos_d1};

  //single rate to double rate
  reg  [31:0] sr_xd_pos_d1;
  reg  [3:0]  sr_xc_pos_d1;
  reg  [31:0] sr_xd_neg_d1;
  reg  [3:0]  sr_xc_neg_d1;
  
  always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
      sr_xd_pos_d1 <= {4{`IDLE}};
      sr_xc_pos_d1 <= 4'hf;
    end
    else begin
      sr_xd_pos_d1 <= sr_xd_i[31:0];
      sr_xc_pos_d1 <= sr_xc_i[3:0];
    end
  end

  always @(negedge clk or negedge rst_n) begin
    if(~rst_n) begin
      sr_xd_neg_d1 <= {4{`IDLE}};
      sr_xc_neg_d1 <= 4'hf;
    end
    else begin
      sr_xd_neg_d1 <= sr_xd_i[63:32];
      sr_xc_neg_d1 <= sr_xc_i[7:4];
    end
  end
  
  //intentionally add delay by inversion
  wire clk_inv = ~clk;

  assign dr_xd_o = (clk_inv == 1'b0) ? sr_xd_pos_d1 : sr_xd_neg_d1;
  assign dr_xc_o = (clk_inv == 1'b0) ? sr_xc_pos_d1 : sr_xc_neg_d1;

endmodule
