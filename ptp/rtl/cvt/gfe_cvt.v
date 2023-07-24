/*++
//  convert gmii/mii to/from xgmii-like interface
//  notes: the number of frame preamble octets must be 7
//         followed by one octet sfd(0xd5)
//  --*/
`include "ptpv2_defines.v"

module gfe_cvt (
  input                clk  ,
  input                rst_n,

  input                mii_mode_i,  //0:ge, 1: 100m/10m ethernet
  output               clk_en_o  ,

  //gmii/mii input
  input                en_i,
  input                er_i,
  input [7:0]          d_i ,
  
  //gmii/mii output converted from xgmii input
  output reg           en_o,
  output reg           er_o,
  output reg [7:0]     d_o ,   

  //xgmii input
  input [63:0]         xd_i,
  input [7:0]          xc_i,
  
  //xgmii output converted from gmii/mii input
  output reg [63:0]    xd_o,
  output reg [7:0]     xc_o
);

  //generate clock enable signal
  wire [3:0] clk_cnt_p1;
  reg  [3:0] clk_cnt;
  reg  clk_en;

  assign clk_cnt_p1 = clk_cnt + 1;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      clk_cnt <= 4'd0;
    else if((mii_mode_i == 0 && clk_cnt == 4'd7)||(mii_mode_i == 0 && clk_cnt == 4'd15))
      clk_cnt <= 4'd0;
    else 
      clk_cnt <= clk_cnt_p1;
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      clk_en <= 0;
    else if((mii_mode_i == 0 && clk_cnt == 4'd7)||(mii_mode_i == 0 && clk_cnt == 4'd15))
      clk_en <= 1;
    else 
      clk_en <= 0;
  end
  assign clk_en_o = clk_en;

  //++
  //convert gmii/mii signals to xgmii-like signals
  //--
  reg         en_d1;
  reg         er_d1;
  reg [7:0]   d_d1;

  wire frm_start = en_i & (~en_d1);
  wire frm_end   = en_d1 & (~en_i);
  
  reg frm_start_d1, frm_end_d1;

  always @(posedge clk) begin
    en_d1 <= en_i;   
    er_d1 <= er_i;
    d_d1  <= d_i ;

    frm_start_d1 <= frm_start;
    frm_end_d1 <= frm_end;
  end

  //ge/gmii to xgmii conversion
  reg [63:0]    ge_xd;
  reg [7:0]     ge_xc;

  reg [7:0]     ge_oct;
  reg           ge_ctl;

  always @(*) begin 
    ge_xd = xd_o;
    ge_xc = xc_o;

    if(frm_start) begin
      ge_ctl = 1;
      ge_oct = `START;
    end
    else if(frm_end) begin
      ge_ctl = 1;
      ge_oct = `TERMINATE;
    end
    else if(er_i == 1) begin
      ge_ctl = 1;
      ge_oct = `ERROR;
    end
    else if(en_i == 1) begin
      ge_ctl = 0;
      ge_oct = d_i;
    end
    else begin
      ge_ctl = 1;
      ge_oct = `IDLE;
    end

    case(clk_cnt)
      4'd0:
      begin
        ge_xc[0]   = ge_ctl;
        ge_xd[7:0] = ge_oct;
      end
      4'd1:
      begin
        ge_xc[1]    = ge_ctl;
        ge_xd[15:8] = ge_oct;
      end
      4'd2:
      begin
        ge_xc[2]     = ge_ctl;
        ge_xd[23:16] = ge_oct;
      end
      4'd3:
      begin
        ge_xc[3]     = ge_ctl;
        ge_xd[31:24] = ge_oct;
      end
      4'd4:
      begin
        ge_xc[4]     = ge_ctl;
        ge_xd[39:32] = ge_oct;
      end
      4'd5:
      begin
        ge_xc[5]     = ge_ctl;
        ge_xd[47:40] = ge_oct;
      end
      4'd6:
      begin
        ge_xc[6]     = ge_ctl;
        ge_xd[55:48] = ge_oct;
      end
      4'd7:
      begin
        ge_xc[7]     = ge_ctl;
        ge_xd[63:56] = ge_oct;
      end
    endcase
  end

  //fe/mii to xgmii conversion
  reg [63:0]    fe_xd;
  reg [7:0]     fe_xc;

  reg [7:0]     fe_oct, fe_oct_d1;
  reg           fe_ctl, fe_ctl_d1;

  reg  nibble_align;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      nibble_align <= 0;
    else if(en_i == 1)
      nibble_align <= ~nibble_align;
    else if(frm_end == 1)
      nibble_align <= 0;
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      fe_oct_d1 <= `IDLE;
      fe_ctl_d1 <= 1;
    end
    else if(frm_end_d1 == 1) begin
      fe_oct_d1 <= `IDLE;
      fe_ctl_d1 <= 1;
    end
    else begin
      fe_oct_d1 <= fe_oct;
      fe_ctl_d1 <= fe_ctl;
    end
  end

  always @(*) begin 
    fe_xd = xd_o;
    fe_xc = xc_o;

    if(frm_start_d1) begin
      fe_ctl = 1;
      fe_oct = `START;
    end
    else if(frm_end_d1) begin
      fe_ctl = 1;
      fe_oct = `TERMINATE;
    end
    else if((er_i == 1 || er_d1 == 1) && nibble_align == 1) begin
      fe_ctl = 1;
      fe_oct = `ERROR;
    end
    else if(en_i == 1 && nibble_align == 1) begin
      fe_ctl = 0;
      fe_oct = {d_i[3:0], d_d1[3:0]};
    end
    else if(en_i == 0 && en_d1 == 0) begin
      fe_ctl = 1;
      fe_oct = `IDLE;
    end
    else begin
      fe_ctl = fe_ctl_d1;
      fe_oct = fe_oct_d1;
    end

    case(clk_cnt)
      4'd0, 4'd1:
      begin
        fe_xc[0]   = fe_ctl;
        fe_xd[7:0] = fe_oct;
      end
      4'd2, 4'd3:
      begin
        fe_xc[1]    = fe_ctl;
        fe_xd[15:8] = fe_oct;
      end
      4'd4, 4'd5:
      begin
        fe_xc[2]     = fe_ctl;
        fe_xd[23:16] = fe_oct;
      end
      4'd6, 4'd7:
      begin
        fe_xc[3]     = fe_ctl;
        fe_xd[31:24] = fe_oct;
      end
      4'd8, 4'd9:
      begin
        fe_xc[4]     = fe_ctl;
        fe_xd[39:32] = fe_oct;
      end
      4'd10, 4'd11:
      begin
        fe_xc[5]     = fe_ctl;
        fe_xd[47:40] = fe_oct;
      end
      4'd12, 4'd13:
      begin
        fe_xc[6]     = fe_ctl;
        fe_xd[55:48] = fe_oct;
      end
      4'd14, 4'd15:
      begin
        fe_xc[7]     = fe_ctl;
        fe_xd[63:56] = fe_oct;
      end
    endcase
  end

  //multiplex ge/fe to xge-like interface
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      xd_o <= {8{`IDLE}}; 
      xc_o <= 8'hff;
    end
    else if(mii_mode_i == 1) begin
      xd_o <= fe_xd; 
      xc_o <= fe_xc;
    end
    else begin
      xd_o <= ge_xd; 
      xc_o <= ge_xc;
    end
  end

  //++
  //convert xgmii-like signals to gmii/mii
  //--
  reg [63:0]    xd_i_z1;
  reg [7:0]     xc_i_z1;

  always @(posedge clk) begin
    if(clk_en == 1) begin
      xd_i_z1 <= xd_i;
      xc_i_z1 <= xc_i;
    end
  end

  //xgmii to gmii conversion
  reg       ge_en  ;
  reg       ge_er  ;
  reg [7:0] ge_d   ; 

  reg       ctl_ge;
  reg [7:0] oct_ge;  

  always @(*) begin
    case(clk_cnt)
      4'd0: 
      begin
        ctl_ge = xc_i[0];
        oct_ge = xd_i[7:0]; 
      end
      4'd1:
      begin
        ctl_ge = xc_i_z1[1];
        oct_ge = xd_i_z1[15:8];
      end
      4'd2:
      begin
        ctl_ge = xc_i_z1[2];
        oct_ge = xd_i_z1[23:16];
      end
      4'd3:
      begin
        ctl_ge = xc_i_z1[3];
        oct_ge = xd_i_z1[31:24];
      end
      4'd4:
      begin
        ctl_ge = xc_i_z1[4];
        oct_ge = xd_i_z1[39:32];
      end
      4'd5:
      begin
        ctl_ge = xc_i_z1[5];
        oct_ge = xd_i_z1[47:40];
      end
      4'd6:
      begin
        ctl_ge = xc_i_z1[6];
        oct_ge = xd_i_z1[55:48];
      end
      4'd7:
      begin
        ctl_ge = xc_i_z1[7];
        oct_ge = xd_i_z1[63:56];
      end
      default:
      begin
        ctl_ge = 0;
        oct_ge = 0;
      end
    endcase
    
    if(oct_ge == `START && ctl_ge == 1) begin
      ge_en = 1;
      ge_er = 0;
      ge_d  = 8'h55;
    end
    else if(oct_ge == `TERMINATE && ctl_ge == 1) begin
      ge_en = 0;
      ge_er = 0;
      ge_d  = 8'h0;
    end
    else if(oct_ge == `ERROR && ctl_ge == 1) begin
      ge_en = 1;
      ge_er = 1;
      ge_d  = 8'h0;
    end
    else if(ctl_ge == 0) begin
      ge_en = 1;
      ge_er = 0;
      ge_d  = oct_ge;
    end
    else begin
      ge_en = 0;
      ge_er = 0;
      ge_d  = oct_ge;
    end
  end

  //xgmii to mii conversion
  reg       fe_en;
  reg       fe_er;
  reg [7:0] fe_d, fe_dp; 

  reg       ctl_fe, ctl_fe_d1;
  reg [7:0] oct_fe, oct_fe_d1;  

  always @(posedge clk) begin
    ctl_fe_d1 <= ctl_fe;
    oct_fe_d1 <= oct_fe;
  end
  
  always @(*) begin
    ctl_fe = ctl_fe_d1;
    oct_fe = oct_fe_d1;

    case(clk_cnt)
      4'd0: 
      begin
        ctl_fe = xc_i[0];
        oct_fe = xd_i[7:0]; 
      end
      4'd2:
      begin
        ctl_fe = xc_i_z1[1];
        oct_fe = xd_i_z1[15:8];
      end
      4'd4:
      begin
        ctl_fe = xc_i_z1[2];
        oct_fe = xd_i_z1[23:16];
      end
      4'd6:
      begin
        ctl_fe = xc_i_z1[3];
        oct_fe = xd_i_z1[31:24];
      end
      4'd8:
      begin
        ctl_fe = xc_i_z1[4];
        oct_fe = xd_i_z1[39:32];
      end
      4'd10:
      begin
        ctl_fe = xc_i_z1[5];
        oct_fe = xd_i_z1[47:40];
      end
      4'd12:
      begin
        ctl_fe = xc_i_z1[6];
        oct_fe = xd_i_z1[55:48];
      end
      4'd14:
      begin
        ctl_fe = xc_i_z1[7];
        oct_fe = xd_i_z1[63:56];
      end
    endcase
    
    if(oct_ge == `START && ctl_ge == 1) begin
      fe_en = 1;
      fe_er = 0;
      fe_dp = 8'h55;
    end
    else if(oct_ge == `TERMINATE && ctl_ge == 1) begin
      fe_en = 0;
      fe_er = 0;
      fe_dp = 8'h0;
    end
    else if(oct_ge == `ERROR && ctl_ge == 1) begin
      fe_en = 1;
      fe_er = 1;
      fe_dp = 8'h0;
    end
    else if(ctl_ge == 0) begin
      fe_en = 1;
      fe_er = 0;
      fe_dp = oct_ge;
    end
    else begin
      fe_en = 0;
      fe_er = 0;
      fe_dp = oct_ge;
    end

    fe_d = 8'h0;
    case(clk_cnt)
      4'd0, 4'd2, 4'd4, 4'd6, 4'd8, 4'd10, 4'd12, 4'd14:
        fe_d = {4'b0, fe_dp[3:0]};
      4'd1, 4'd3, 4'd5, 4'd7, 4'd9, 4'd11, 4'd13, 4'd15:
        fe_d = {4'b0, fe_dp[7:4]};
    endcase
  end
  
  //multiplex gmii/mii output interface
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      en_o <= 0;
      er_o <= 0;
      d_o  <= 8'h0;   
    end
    else if(mii_mode_i == 1) begin
      en_o <= fe_en;
      er_o <= fe_er;
      d_o  <= fe_d ;   
    end
    else begin
      en_o <= ge_en;
      er_o <= ge_er;
      d_o  <= ge_d ;   
    end
  end

endmodule
