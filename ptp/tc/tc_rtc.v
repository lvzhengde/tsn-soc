/*++
//  testcase for ptpv2 real time counter
--*/

`include "ptpv2_defines.v"
`define WAVE_DUMP_FILE "./ptpv2.fst"
`define SIM_PPS

module tc_rtc;

  harness harness();
  //test use small intervals
  //defparam harness.ptpv2_endpoint.ptpv2_core_wrapper.ptpv2_core_inst.rtc_unit_inst.sync_io_inst.INT10MS = 24'd150000;        
  //defparam harness.ptpv2_endpoint.ptpv2_core_wrapper.ptpv2_core_inst.rtc_unit_inst.sync_io_inst.INTQ8MS = 24'd150000;        
  //defparam harness.lp_ptpv2_endpoint.ptpv2_core_wrapper.ptpv2_core_inst.rtc_unit_inst.sync_io_inst.INT10MS = 24'd150000;        
  //defparam harness.lp_ptpv2_endpoint.ptpv2_core_wrapper.ptpv2_core_inst.rtc_unit_inst.sync_io_inst.INTQ8MS = 24'd150000;        

  integer i;

  initial begin
    fork
      harness.ptpv2_endpoint.clkgen.reset;
      harness.lp_ptpv2_endpoint.clkgen.reset; 
    join   
    #700;

    //initial rtc 
    $display("initialize rtc with second offset 32'h1234_5678 !");
    harness.ptpv2_endpoint.ptp_agent.write_reg({`RTC_BLK_ADDR, `SC_OFST_ADDR0}, {16'b0, 16'h11});
    harness.ptpv2_endpoint.ptp_agent.write_reg({`RTC_BLK_ADDR, `SC_OFST_ADDR1}, 32'h1234_5678);
    harness.ptpv2_endpoint.ptp_agent.write_reg({`RTC_BLK_ADDR, `NS_OFST_ADDR}, 32'h0150_0000);
    harness.ptpv2_endpoint.ptp_agent.write_reg({`RTC_BLK_ADDR, `RTC_CTL_ADDR}, 32'h1);
    #10_0000;

    //clear rtc 
    $display("clear rtc !");
    harness.ptpv2_endpoint.ptp_agent.write_reg({`RTC_BLK_ADDR, `RTC_CTL_ADDR}, 32'h2);
    #10_0000;

    //reset sc_counter and ns_counter
    harness.ptpv2_endpoint.ptp_agent.write_reg({`RTC_BLK_ADDR, `SC_OFST_ADDR0}, {16'b0, 16'h11});
    harness.ptpv2_endpoint.ptp_agent.write_reg({`RTC_BLK_ADDR, `SC_OFST_ADDR1}, 32'h2222_3333);
    harness.ptpv2_endpoint.ptp_agent.write_reg({`RTC_BLK_ADDR, `NS_OFST_ADDR}, 32'h0);
    harness.ptpv2_endpoint.ptp_agent.write_reg({`RTC_BLK_ADDR, `RTC_CTL_ADDR}, 32'h1);

    //set tick_inc value
    //xge clock T = 6.4ns, 6.4 * 2^26 = 429496729.6, convert to
    //hexdecimal, 32'h1999_999a
    $display("set tick_inc value to 32'h1999_999a ! \n");
    harness.ptpv2_endpoint.ptp_agent.write_reg({`RTC_BLK_ADDR, `TICK_INC_ADDR}, 32'h1999_999a);
    #10_0000;

`ifdef SIM_PPS
    //wait 1.2 seconds
    $display("wait 1.2 seconds for pps output!");

    for(i = 1; i < 120; i=i+1) begin
      #1000_0000;
      $display("%f seconds elapsed!", i*0.01);
    end
`endif

    #10_0000;

    $finish;
  end

  //monitor pps output
  wire pps_out = harness.ptpv2_endpoint.ptpv2_core_wrapper.ptpv2_core_inst.pps_o;
  wire [79:0] rtc_std = harness.ptpv2_endpoint.ptpv2_core_wrapper.ptpv2_core_inst.rtc_std; 
  wire [79:0] pts_std = harness.ptpv2_endpoint.ptpv2_core_wrapper.ptpv2_core_inst.rtc_unit_inst.rtc_rgs_inst.pts_std_i;

  initial begin
    force harness.ptpv2_endpoint.pps_in = pps_out;
  end
  
`ifdef SIM_PPS
  always @(posedge pps_out) begin
    #20;
    $display("positive edge of pps output is detected!");
    $display("current ptpv2 rtc time = %h", rtc_std);
    #200;
    $display("timestamp of pps input = %h", pts_std);
    $display("\n");
  end
`endif

  reg  dump_on_flag;
  reg  dump_off_flag;

  initial
  begin
    $dumpfile(`WAVE_DUMP_FILE);
    $dumpvars(0, tc_rtc.harness.ptpv2_endpoint);

    $dumpon;
`ifdef SIM_PPS
    $dumpoff;

    dump_on_flag = 0;
    dump_off_flag = 1;

    while (1) begin
      if((rtc_std[31:0] > 32'd9_9900_0000 || rtc_std[31:0] < 32'd100_0000) && dump_off_flag == 1) begin
        $dumpon;
        dump_on_flag = 1;
        dump_off_flag = 0;
      end

      if((rtc_std[31:0] <= 32'd9_9900_0000 && rtc_std[31:0] >= 32'd100_0000) && dump_on_flag == 1) begin
        $dumpoff;
        dump_on_flag = 0;
        dump_off_flag = 1;
      end

      #10;
    end
`endif

  end    

endmodule
