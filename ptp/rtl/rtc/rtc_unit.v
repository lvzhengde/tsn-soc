/*++
//  rtc unit top level
--*/

`include "ptpv2_defines.v"

module rtc_unit(
  input                rtc_clk,
  input                rtc_rst_n,          //async. reset, active low

  //32 bits on chip bus access interface
  input                bus2ip_clk    ,
  input                bus2ip_rst_n  ,

  input  [31:0]        bus2ip_addr_i ,
  input  [31:0]        bus2ip_data_i ,
  input                bus2ip_rd_ce_i ,    //active high
  input                bus2ip_wr_ce_i ,    //active high
  output [31:0]        ip2bus_data_o  ,  
                       
  //time related signals                     
  output [79:0]        rtc_std_o,          //current time(48 bits seconds + 32 bits nanoseconds)
  output [15:0]        rtc_fns_o,          //fractional nanoseconds of current time

  output               intxms_o,  
  input                pps_i,              //pps input
  output               pps_o               //pps output from current time
);  
  parameter BLK_ADDR = `RTC_BLK_ADDR;

  wire [31:0]    tick_inc;        
  wire [31:0]    ns_offset;     
  wire [47:0]    sc_offset;    
  wire           offset_valid;
  wire           clear_rtc;  
  wire [31:0]    pps_width;
  wire           intxms_sel;

  wire [79:0]    rtc_std;         
  wire [15:0]    rtc_fns;         
  wire [79:0]    pts_std;         
  wire [15:0]    pts_fns;         

  assign rtc_std_o = rtc_std; 
  assign rtc_fns_o = rtc_fns; 

  rtc_rgs rtc_rgs_inst(
    //32 bits on chip bus access interface
    .bus2ip_clk       (bus2ip_clk    ),
    .bus2ip_rst_n     (bus2ip_rst_n  ),
    .bus2ip_addr_i    (bus2ip_addr_i ),
    .bus2ip_data_i    (bus2ip_data_i ),
    .bus2ip_rd_ce_i   (bus2ip_rd_ce_i),    
    .bus2ip_wr_ce_i   (bus2ip_wr_ce_i),    
    .ip2bus_data_o    (ip2bus_data_o ),  
  
    //register i/f
    .rtc_std_i        (rtc_std  ),          
    .rtc_fns_i        (rtc_fns  ),          
    .pts_std_i        (pts_std  ),          
    .pts_fns_i        (pts_fns  ),          
  
    .tick_inc_o       (tick_inc    ), 
    .ns_offset_o      (ns_offset   ), 
    .sc_offset_o      (sc_offset   ), 
    .offset_valid_o   (offset_valid), 
    .clear_rtc_o      (clear_rtc   ), 
    
    .pps_width_o      (pps_width ),
    .intxms_sel_o     (intxms_sel)        
  );
  defparam rtc_rgs_inst.BLK_ADDR = BLK_ADDR;
  
  //shape related signal, syncronize with rtc_clk
  reg  offset_valid_d1, offset_valid_d2, offset_valid_d3;
  wire offset_valid_pul = offset_valid_d2 & (~offset_valid_d3);
  
  always @(posedge rtc_clk or negedge rtc_rst_n) begin
    if(~rtc_rst_n)
      {offset_valid_d1, offset_valid_d2, offset_valid_d3} <= 3'b0;
    else
      {offset_valid_d1, offset_valid_d2, offset_valid_d3} <= {offset_valid, offset_valid_d1, offset_valid_d2};
  end 
 
  reg [31:0] tick_inc_d1, tick_inc_d2;
  always @(posedge rtc_clk) {tick_inc_d1, tick_inc_d2} <= {tick_inc, tick_inc_d1};

  ptp_rtc ptp_rtc_inst(
    .rtc_clk           (rtc_clk    ),
    .rtc_rst_n         (rtc_rst_n  ),          
                                   
    .tick_inc_i        (tick_inc_d2),         
    .ns_offset_i       (ns_offset  ),        
    .sc_offset_i       (sc_offset  ),        
    .offset_valid_i    (offset_valid_pul),     
    .clear_rtc_i       (clear_rtc ),        
                                    
    .rtc_std_o         (rtc_std   ),          
    .rtc_fns_o         (rtc_fns   )      
  );  
  
  sync_io sync_io_inst(
    .rtc_clk           (rtc_clk     ),
    .rtc_rst_n         (rtc_rst_n   ),         
                                    
    .tick_inc_i        (tick_inc_d2 ),        
    .rtc_std_i         (rtc_std     ),         
    .rtc_fns_i         (rtc_fns     ),         
                                    
    .pps_width_i       (pps_width   ),
    .intxms_sel_i      (intxms_sel  ),      
                                    
    .pps_i             (pps_i       ),             
    .pts_std_o         (pts_std     ),         
    .pts_fns_o         (pts_fns     ),         
    .pps_o             (pps_o       ),              
    .intxms_o          (intxms_o    ) 
  );

endmodule
