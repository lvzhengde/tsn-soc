elfFile = ptpv2
waveFile = ptpv2

tc_rtc:
	iverilog -o $(elfFile).out -s tc_rtc -f comp.f  

tc_rapid_ptp_test:
	iverilog -o $(elfFile).out -s tc_rapid_ptp_test -f comp.f  
	
vsim:
	vvp -n $(elfFile).out -fst

debug:
	gtkwave $(waveFile).fst

lint:
	verilator --lint-only --timing --top-module tc_rtc -f comp.f

clean:
	rm -rf *.fst *.lxt *.vcd *.out *.dat
