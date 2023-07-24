/*++
//  _ethernet frame monitor
--*/
`include "ptpv2_defines.v"

module frame_monitor (
  input             clk,
  input             dump_finish_i,

`ifdef GFE_DESIGN
  input             mii_mode_i,

  input             data_en_i,
  input             data_er_i,
  input [7:0]       data_i
`else
  input [7:0]       xc_i,
  input [63:0]      xd_i
`endif
);

  integer           logfile;
  integer           broadcast;
  integer           frame_len, i, j;
  reg  [7:0]        rcvd_frame[255:0];
  reg  [3:0]        first_nibble;
  reg  [7:0]        data;
  reg               data_en_z1;
  reg  [11:0]       eth_count;

  reg               get_sof_done;
  integer           sof_pos;

`ifdef GFE_DESIGN
  wire mii_mode = mii_mode_i;
`endif

  initial begin
    #1;
    logfile  = $fopen("./xge-ptpv2-frame.dat") ;  
    broadcast = logfile;   //1 | logfile; 

    frame_len = 0 ;
    i = 0 ;
    j = 0 ;
    eth_count = 0 ;
    data_en_z1 = 0 ;
    first_nibble = 0 ;
    data = 0 ;

    get_sof_done = 1'b0;
    sof_pos = 0;

    wait(dump_finish_i == 1'b1);
    $fclose(logfile);
  end

`ifdef GFE_DESIGN  
  always @(posedge clk) data_en_z1 <= data_en_i;

  always @(posedge clk) begin
    if(data_en_i == 1'b1)
      eth_count <= eth_count + 1;
    else
      eth_count <= 12'd0;
  end

  always @(posedge clk) begin
    if(data_en_i == 1'b1) begin
      if(mii_mode == 1'b0) begin  //1000M ethernet
        rcvd_frame[frame_len] = data_i[7:0];
        frame_len = frame_len + 1;
      if(data_i[7:0] == 8'hd5 && get_sof_done == 1'b0) begin
        sof_pos = frame_len;
        get_sof_done = 1'b1;
      end
      end
      else begin                  //10/100M ethernet
        if(eth_count[0] == 1'b0) 
          first_nibble = data_i[3:0];
        else begin
          data = {data_i[3:0], first_nibble[3:0]};
          rcvd_frame[frame_len] = data[7:0];
          frame_len = frame_len + 1; 
        if(data[7:0] == 8'hd5 && get_sof_done == 1'b0) begin
          sof_pos = frame_len;
          get_sof_done = 1'b1;
        end
      end
      end
    end
    else if(data_en_z1 == 1'b1 && data_en_i == 1'b0) begin
      for(i = sof_pos; i < frame_len; i = i+4) begin
        j = i - sof_pos;
        if((i+4) <= frame_len) 
          $fdisplay(broadcast, "%h  %h %h %h %h", j, rcvd_frame[i], rcvd_frame[i+1], rcvd_frame[i+2], rcvd_frame[i+3]);  
        else if((i+3) == frame_len)
          $fdisplay(broadcast, "%h  %h %h %h", j, rcvd_frame[i], rcvd_frame[i+1], rcvd_frame[i+2]);  
        else if((i+2) == frame_len)
          $fdisplay(broadcast, "%h  %h %h", j, rcvd_frame[i], rcvd_frame[i+1]);  
        else if((i+1) == frame_len)
          $fdisplay(broadcast, "%h  %h", j, rcvd_frame[i]);  
      end

      $fdisplay(broadcast, "   ");
      frame_len = 0;
      get_sof_done = 1'b0;
    end
  end  
`else
  //xge design
  always @(posedge clk) begin : XGE_RCV_PROC
    integer k;

    for(k = 0; k < 8; k = k+1) begin
      if(xc_i[k] == 1 && xd_i[k*8+7-:8] == `START) begin 
        frame_len = 0;
        rcvd_frame[frame_len] = 8'h55;
        frame_len = frame_len + 1;
      end
      else if(xc_i[k] == 0) begin
        rcvd_frame[frame_len] = xd_i[k*8+7-:8];      
        frame_len = frame_len + 1;
      if(xd_i[k*8+7-:8] == 8'hd5 && get_sof_done == 1'b0) begin
        sof_pos = frame_len;
        get_sof_done = 1'b1;
      end
      end
      else if(xc_i[k] == 1 && xd_i[k*8+7-:8] == `TERMINATE) begin
        for(i = sof_pos; i < frame_len; i = i+4) begin
          j = i - sof_pos;
          if((i+4) <= frame_len) 
            $fdisplay(broadcast, "%h  %h %h %h %h", j, rcvd_frame[i], rcvd_frame[i+1], rcvd_frame[i+2], rcvd_frame[i+3]);  
          else if((i+3) == frame_len)
            $fdisplay(broadcast, "%h  %h %h %h", j, rcvd_frame[i], rcvd_frame[i+1], rcvd_frame[i+2]);  
          else if((i+2) == frame_len)
            $fdisplay(broadcast, "%h  %h %h", j, rcvd_frame[i], rcvd_frame[i+1]);  
          else if((i+1) == frame_len)
            $fdisplay(broadcast, "%h  %h", j, rcvd_frame[i]);  
        end //for i
        $fdisplay(broadcast, "   ");

        frame_len = 0;
        get_sof_done = 1'b0;
      end
    end //for k
  end
`endif  //GFE_DESIGN
  
endmodule


