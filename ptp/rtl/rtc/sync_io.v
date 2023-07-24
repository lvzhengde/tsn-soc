/*++
//  deal with pps output and pps input
--*/

`include "ptpv2_defines.v"

module sync_io (
  input                rtc_clk,
  input                rtc_rst_n,          //async. reset, active low

  input  [31:0]        tick_inc_i,         //tick increment value, default to 6.26 format unsigned nano seconds
  input  [79:0]        rtc_std_i,          //48 bits seconds + 32 bits nanoseconds
  input  [15:0]        rtc_fns_i,          //16 bit fractional nanoseconds of rtc

  input  [31:0]        pps_width_i,
  input                intxms_sel_i,       //0: 10ms; 1: 7.8125ms=1/128ms

  input                pps_i,              //pps input
  output reg [79:0]    pts_std_o,          //timestamp of pps input (second+nanosecond)
  output reg [15:0]    pts_fns_o,          //timestamp of pps input (fractional nanosecond) 
  output reg           pps_o,              //pps output from current time
  output               intxms_o   
);
  parameter  INT10MS = 24'd10000000;       //10^7  nano seconds  10ms,  aligned with 1_p_p_s
  parameter  INTQ8MS = 24'd7812500;        //7812500 ns, 7.8125ms

  wire  [63:0] zero_dword = 64'b0;
  wire  [23:0] intxms_period = (intxms_sel_i == 1'b0) ? INT10MS : INTQ8MS;

  //++
  //generate pps output
  //-- 
  wire  [31:0]  ns_phase_adjusted;
  wire  [31:0]  ns_adjusted_mod;
  reg   [31:0]  ns_adjusted_mod_d1;

  //take tick increment every cycle into consideration
  assign ns_phase_adjusted = rtc_std_i[31:0] + {zero_dword[`FNS_W-2:0], tick_inc_i[31:`FNS_W-1]};  //+2*tick_inc_i
  assign ns_adjusted_mod   = (ns_phase_adjusted < `SC2NS) ? ns_phase_adjusted : (ns_phase_adjusted - `SC2NS);

  always @(posedge rtc_clk or negedge rtc_rst_n) begin
    if(!rtc_rst_n)
      ns_adjusted_mod_d1 <= 32'd0;
    else
      ns_adjusted_mod_d1 <=  ns_adjusted_mod;
  end

  wire  seconds_start_p1;
  reg   seconds_start;

  assign seconds_start_p1 = (ns_adjusted_mod_d1 < {8'h0, intxms_period});  //seconds start detected;
  always @(posedge rtc_clk or negedge rtc_rst_n) begin
    if(!rtc_rst_n)
      seconds_start <= 0;
    else
      seconds_start <= seconds_start_p1;
  end

  reg  [31:0] pps_width_ns; 
  always @(posedge rtc_clk or negedge rtc_rst_n) begin
    if(~rtc_rst_n)
      pps_width_ns <= (`SC2NS>>1);
    else if(pps_width_i > 32'h0 && pps_width_i < `SC2NS)
      pps_width_ns <= pps_width_i;
    else
      pps_width_ns <= (`SC2NS>>1);
  end 
  
  //generate pps output 
  always @(posedge rtc_clk or negedge rtc_rst_n) begin
    if(~rtc_rst_n)
      pps_o <= 1'b0;
    else if(seconds_start_p1 == 1'b1 && seconds_start == 1'b0)
      pps_o <= 1'b1;
    else if(ns_adjusted_mod_d1 >= pps_width_ns)
      pps_o <= 1'b0;
  end 

  //++
  //generate xms pulse and interrupt, aligned with pps output
  //--
  reg  [`FNS_W+23:0]  counterxms;
  wire [`FNS_W+23:0]  counterxms_p1;
  reg          trigxms;
  reg          seconds_d1;
  
  always @(posedge rtc_clk or negedge rtc_rst_n) begin
    if (!rtc_rst_n) 
      seconds_d1 <= 0;
    else
      seconds_d1 <= rtc_std_i[32];
  end
  
  assign counterxms_p1 = counterxms + {zero_dword[`FNS_W-9:0], tick_inc_i};

  wire [`FNS_W+23:0] intxms_period_shift;
  assign intxms_period_shift[`FNS_W+23:`FNS_W] = intxms_period;
  assign intxms_period_shift[`FNS_W-1:0] = 0;

  
  always @(posedge rtc_clk or negedge rtc_rst_n) begin
    if (!rtc_rst_n) begin
      counterxms <= 50'd0;
      trigxms    <= 0;
    end
    else if(seconds_start_p1 == 1'b1 && seconds_start == 1'b0) begin            //align with start of seconds
      counterxms <= 50'd0;
      trigxms    <= 1;
    end
    else if((seconds_d1 != rtc_std_i[32]) && seconds_start !=1) begin           //for simulation purpose only
      counterxms <= 50'd0;
      trigxms    <= 0;
    end 
    else if(counterxms[`FNS_W+23:`FNS_W] > (intxms_period-1)) begin              //10^7-1 nanoseconds (10ms), reset to 0
      counterxms <= counterxms_p1 - intxms_period_shift;
      trigxms    <= 1;
    end
    else begin
      counterxms <= counterxms_p1;
      trigxms    <= 0;
    end
  end

  assign intxms_o = trigxms;

  //++
  //generate timestamp for pps input
  //--
  reg pps_in_d1, pps_in_d2, pps_in_d3;

  always @(posedge rtc_clk or negedge rtc_rst_n) begin
    if(!rtc_rst_n)
      {pps_in_d1, pps_in_d2, pps_in_d3} <= 3'b0;
    else
      {pps_in_d1, pps_in_d2, pps_in_d3} <= {pps_i, pps_in_d1, pps_in_d2};
  end

  //the actual time of pps posedge should be (timestamp-2*tic_inc)
  //it can be corrected by software easily
  wire pps_pos_pul = pps_in_d2 & (~pps_in_d3);
  always @(posedge rtc_clk or negedge rtc_rst_n) begin
    if(!rtc_rst_n) begin
      pts_std_o <= 80'h0;
      pts_fns_o <= 16'h0;    
    end
    else if(pps_pos_pul == 1) begin
      pts_std_o <= rtc_std_i;
      pts_fns_o <= rtc_fns_i;    
    end
  end

endmodule

