
/*++
//  extract ingress timestamp (ns part) from messageTypeSpecific field
//  of ptpv2 event messages.
//  recalculate correctionField by subtract egress asymmetry. 
//  fill messageTypeSpecific field to zero according to standard.
--*/
`include "ptpv2_defines.v"

module tx_emb_ts(
  //xgmii interface
  input               tx_clk,
  input               tx_rst_n,
  input               tx_clk_en_i,            //for adapting to gmii/mii

  input  [63:0]       txd_i,
  input  [7:0]        txc_i,

  output reg [63:0]   txd_o,
  output reg [7:0]    txc_o,

  //configuration register i/f
  input  [31:0]       tsu_cfg_i,
  input  [31:0]       egress_asymmetry_i,

  //ptpv2 message related information
  input  [10:0]       eth_count_base_i,      //aligned with txd_i now
  input  [10:0]       ptp_addr_base_i,
  input  [3:0]        ptp_messageType_i,          
  input  [63:0]       ptp_correctionField_i,
  input  [31:0]       ptp_messageTypeSpecific_i,
  input               is_ptp_message_i,  
  input  [15:0]       ptp_messageLength_i,
  input  [15:0]       ptp_flagField_i, 

  input               ipv6_flag_i,
  input  [10:0]       ipv6_addr_base_i,
  input               ipv4_flag_i,
  input  [10:0]       ipv4_addr_base_i,

  //output information of currently sending packet
  output reg [63:0]   correctionField_o,     //ns * 2^16                               
  output reg [31:0]   ingress_time_o,        //32 bits ns  

  output reg [10:0]   ptp_addr_base_o,
  output reg [3:0]    ptp_messageType_o,          
  output reg          is_ptp_message_o,  
  output reg [15:0]   ptp_messageLength_o, 
  output reg [15:0]   ptp_flagField_o, 

  output reg          ipv6_flag_o,
  output reg [10:0]   ipv6_addr_base_o,
  output reg          ipv4_flag_o,
  output reg [10:0]   ipv4_addr_base_o,

  input               get_sfd_done_i,
  output reg          get_sfd_done_o,

  output reg [10:0]   eth_count_base_o
);
  genvar i;

  //xgmii delayline
  reg  [7:0]  txc_z1, txc_z2, txc_z3;
  reg  [63:0] txd_z1, txd_z2, txd_z3;

  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n) begin
      {txc_z1, txc_z2, txc_z3} <= {3{8'b0}};
      {txd_z1, txd_z2, txd_z3} <= {3{64'b0}};
    end
    else if(tx_clk_en_i) begin
      {txc_z1, txc_z2, txc_z3} <= {txc_i, txc_z1, txc_z2};
      {txd_z1, txd_z2, txd_z3} <= {txd_i, txd_z1, txd_z2};
    end
  end

  reg  get_sfd_done_z1, get_sfd_done_z2, get_sfd_done_z3, get_sfd_done_z4;

  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n)
      {get_sfd_done_z1, get_sfd_done_z2, get_sfd_done_z3, get_sfd_done_z4} <= {4{1'b0}};
    else if(tx_clk_en_i) 
      {get_sfd_done_z1, get_sfd_done_z2, get_sfd_done_z3, get_sfd_done_z4} <= {get_sfd_done_i, 
                        get_sfd_done_z1, get_sfd_done_z2, get_sfd_done_z3};
  end

  wire next_frame_detected = get_sfd_done_z3 && (~get_sfd_done_z4);

  //eth_count_base delay line
  reg  [10:0]  eth_count_base_z1, eth_count_base_z2, eth_count_base_z3, eth_count_base_z4;  

  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n) begin
       {eth_count_base_z1, eth_count_base_z2, eth_count_base_z3, eth_count_base_z4} <= {4{11'h0}};
    end
    else if(tx_clk_en_i) begin
       {eth_count_base_z1, eth_count_base_z2, eth_count_base_z3, eth_count_base_z4} <= {eth_count_base_i, 
                           eth_count_base_z1, eth_count_base_z2, eth_count_base_z3};
    end
  end

  //ingress time and correctionField related
  wire one_step    = tsu_cfg_i[0];
  wire peer_delay  = tsu_cfg_i[2];
  wire tc_offload  = tsu_cfg_i[3];
  wire eg_asym_en  = tsu_cfg_i[6];
  wire emb_ingressTime_en = tsu_cfg_i[5];

  wire [63:0] asym_correction = {{16{egress_asymmetry_i[31]}}, egress_asymmetry_i[31:0], 16'b0};  

  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n)
      correctionField_o <= 64'h0;
    else if(tx_clk_en_i) begin
      if(eg_asym_en == 1'b1 && (ptp_messageType_i[3:0] == 4'h1 || ptp_messageType_i[3:0] ==  4'h2) && is_ptp_message_i == 1'b1)
        correctionField_o <= ptp_correctionField_i - asym_correction;  // only for delay_req and pdelay_req messages.
      else
        correctionField_o <= ptp_correctionField_i;
    end
  end

  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n)
      ingress_time_o <= 32'h0;
    else if(tx_clk_en_i) 
      ingress_time_o <= ptp_messageTypeSpecific_i;
  end

  //related control signals for one-step clock processing
  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n) begin
      ptp_addr_base_o     <= 11'h80;
      ptp_messageType_o   <= 4'hf;  
      ptp_flagField_o     <= 16'h0;
      is_ptp_message_o    <= 0;  
      ptp_messageLength_o <= 16'h0; 
    end
    else if(tx_clk_en_i) begin
      if(is_ptp_message_i == 1'b1 ) begin //latch
        ptp_addr_base_o     <= ptp_addr_base_i;
        ptp_messageType_o   <= ptp_messageType_i;  
        ptp_flagField_o     <= ptp_flagField_i;        
        is_ptp_message_o    <= is_ptp_message_i;  
        ptp_messageLength_o <= ptp_messageLength_i;
      end
      else if(next_frame_detected == 1) begin //next frame begin
        ptp_addr_base_o     <= 11'h80;
        ptp_messageType_o   <= 4'hf;  
        ptp_flagField_o     <= 16'h0;
        is_ptp_message_o    <= 0;  
        ptp_messageLength_o <= 16'h0; 
      end
    end
  end

  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n) begin
      ipv6_flag_o      <= 0;
      ipv6_addr_base_o <= 11'h0;
    end
    else if(tx_clk_en_i) begin
      if(ipv6_flag_i == 1'b1) begin //latch
        ipv6_flag_o      <= ipv6_flag_i;
        ipv6_addr_base_o <= ipv6_addr_base_i;        
      end
      else if(next_frame_detected == 1) begin //next frame begin
        ipv6_flag_o      <= 0;
        ipv6_addr_base_o <= 11'h0;
      end
    end
  end

  always @(posedge tx_clk or negedge tx_rst_n) begin
    if(!tx_rst_n) begin
      ipv4_flag_o      <= 0;
      ipv4_addr_base_o <= 11'h0;
    end
    else if(tx_clk_en_i) begin
      if(ipv4_flag_i == 1'b1) begin //latch
        ipv4_flag_o      <= ipv4_flag_i;
        ipv4_addr_base_o <= ipv4_addr_base_i;        
      end
      else if(next_frame_detected == 1) begin //next frame begin
        ipv4_flag_o      <= 0;
        ipv4_addr_base_o <= 11'h0;
      end
    end
  end

  //output xgmii data
  //use data input delayed 6(parse)+3(emb_ts) cycles
  reg  [7:0]  txc_tmp;
  reg  [63:0] txd_tmp;

  generate
    for(i = 0; i < 8; i = i+1) begin : TX_EMBED_TS 
      reg [10:0]   eth_count;
      reg [7:0]    txd_lane;

      always @(*) begin
        eth_count = eth_count_base_z3 + i;
      end

      always @(*) begin
        txd_lane = txd_z3[8*i+7:8*i];

        //ptp event message, one-step clock or tc-offload, embedded ingress time
        if(is_ptp_message_i == 1'b1 && ptp_messageType_i[3] == 1'b0 && emb_ingressTime_en == 1'b1 && 
          (one_step | tc_offload) && !txc_z3[i]) begin 
          if(eth_count == (ptp_addr_base_i+16)) txd_lane = 8'h0;             //messageTypeSpecific
          if(eth_count == (ptp_addr_base_i+17)) txd_lane = 8'h0;
          if(eth_count == (ptp_addr_base_i+18)) txd_lane = 8'h0;
          if(eth_count == (ptp_addr_base_i+19)) txd_lane = 8'h0;
        end

        txc_tmp[i]         = txc_z3[i];
        txd_tmp[8*i+7:8*i] = txd_lane;
      end  //always
    end //for i
  endgenerate

  //delay outputs two samples to facilitate alteration of packet
  reg  [7:0]  txc_tmp_z1;
  reg  [63:0] txd_tmp_z1;

  always @(posedge tx_clk or negedge tx_rst_n) begin  
    if(!tx_rst_n) begin
      txc_tmp_z1  <= 8'h0;
      txd_tmp_z1  <= 64'h0;
    end
    else if(tx_clk_en_i) begin  
      txc_tmp_z1  <= txc_tmp;
      txd_tmp_z1  <= txd_tmp;
    end
  end

  always @(posedge tx_clk or negedge tx_rst_n) begin  
    if(!tx_rst_n) begin
      txc_o  <= 8'h0;
      txd_o  <= 64'h0;

      eth_count_base_o <= 0;
      get_sfd_done_o   <= 0;
    end
    else if(tx_clk_en_i) begin  
      txc_o  <= txc_tmp_z1;
      txd_o  <= txd_tmp_z1;

      eth_count_base_o <= eth_count_base_z4;
      get_sfd_done_o   <= get_sfd_done_z4;
    end
  end


endmodule
