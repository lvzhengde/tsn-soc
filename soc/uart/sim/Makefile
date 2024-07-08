elfFile = uart
waveFile = uartWave

testcase:
	iverilog -o $(elfFile).out -s testcase -f comp.f  

testcase_baud_change:
	iverilog -o $(elfFile).out -s testcase_baud_change -f comp.f  
	
testcase_break_condition:
	iverilog -o $(elfFile).out -s testcase_break_condition -f comp.f  

testcase_msb_first:
	iverilog -o $(elfFile).out -s testcase_msb_first -f comp.f  
	
testcase_multiple_access:
	iverilog -o $(elfFile).out -s testcase_multiple_access -f comp.f  

testcase_parity_msb:
	iverilog -o $(elfFile).out -s testcase_parity_msb -f comp.f  

testcase_parity:
	iverilog -o $(elfFile).out -s testcase_parity -f comp.f  

vsim:
	vvp -n $(elfFile).out -fst

debug:
	gtkwave $(waveFile).fst

clean:
	rm -rf *.fst *.lxt *.vcd *.out
