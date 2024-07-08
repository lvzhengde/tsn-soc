/*++
//  Description  : uart testcase, testbench top level
//  File         : testcase_parity_msb.v  
--*/

`timescale 1ns/10fs

module testcase_parity_msb;

  harness harness();
  defparam harness.uart_device.registers_stub.BASEADDR = 4'h2;

  reg   [15:0]   base_addr;
  reg   [3:0]    burst_len;
  reg   [15:0]   regval;
  reg   [15:0]   wr_buffer_val;
  reg   [3:0]    temp;
  integer        i;

  initial begin
    base_addr = 0;
    burst_len = 0;
    i = 0;

    #10;
    $display("uart simulation start!");
    $display("reset uart device.");
    harness.uart_device.clkgen.reset;
    $display("reset uart host.");
    harness.uart_host.clkgen.reset;

    //force parity transmission
    force harness.uart_host.parity_en = 1'b1;
    force harness.uart_device.uart_core.uart_regs.parity_en_o = 1'b1;
    force harness.uart_host.msb_first = 1'b1;
    force harness.uart_device.uart_core.uart_regs.msb_first_o = 1'b1;

    //single write/read
    #50000;
    $display("write to register, address offset = 8, register value = 16'h8888");
    base_addr = {4'h2, 12'h8};
    burst_len = 0;
    regval = 16'h8888;
    harness.uart_host.wr_buffer[0] = regval;
    harness.uart_host.write_register(base_addr, burst_len);

    //$stop;  //for debug purpose

    #5000;
    $display("read from previous regiser, address offset = 8");
    harness.uart_host.read_register(base_addr, burst_len);
    regval = harness.uart_host.rd_buffer[0];
    $display("readed register value = %h", regval);

    //$stop;  //for debug purpose

    #5000;

    //burst write/read
    $display("burst write to register, base address offset = 1, burst length = 16");
    base_addr = {4'h2, 12'h1};
    burst_len = 16 - 1;
    for(i = 0; i <= burst_len; i = i+1) begin
      temp = i + 1;
      regval = {4{temp}};
      if(temp == 4'h0) regval = 16'habcd;
      harness.uart_host.wr_buffer[i] = regval;
      $display("address index %h , written value = %h", i, regval);
    end
    harness.uart_host.write_register(base_addr, burst_len);

    //$stop;  //for debug purpose

    #5000;
    $display("burst read registers, base address offset = 1, burst length = 16");
    harness.uart_host.read_register(base_addr, burst_len);
    for(i = 0; i <= burst_len; i = i+1) begin
      wr_buffer_val = harness.uart_host.wr_buffer[i]; 
      regval = harness.uart_host.rd_buffer[i];
      $display("address index %h , readed value = %h", i, regval);
	  if(wr_buffer_val != regval) begin
        $display("readed value is different from written value");
        $display("SIMULATION FAIL!!!");
		$stop;
	  end
      else
        $display("readed value equal to written value");
    end

    #5000;
    $display("SIMULATION PASS!!!");		
    $finish;
  end

  initial
  begin
    $dumpfile("uartWave.fst");
    $dumpvars(0);
	//$dumpon;
	$dumpoff;
  end
 
endmodule
