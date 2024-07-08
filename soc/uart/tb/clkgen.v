/*++
//  Description  : clock and reset generation
//  File         : clkgen.v  
--*/

`timescale 1ns/10fs

module clkgen (
  output reg   clk,
  output reg   rst_n
);
  parameter    T_CLK   = 8;
  
  //clock and reset initialization
  initial begin
    clk    = 0;
    rst_n  = 1;
  end
  
  // clock generation
  always #(T_CLK/2)   clk = ~clk;
                          
  // task for reset operation
  task reset;
  begin
      #55
      rst_n    = 0;

      #355 
      rst_n    = 1;
  end
  endtask 
  
endmodule
