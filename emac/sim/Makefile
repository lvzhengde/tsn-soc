elfFile = emac 
waveFile = emac

sim:
	iverilog -o $(elfFile).out -s sim_emac -f comp.f  

vsim:
	vvp -n $(elfFile).out -fst

debug:
	gtkwave $(waveFile).fst

lint:
	verilator --lint-only --timing --top-module sim_emac -f comp.f

clean:
	rm -rf *.fst *.lxt *.vcd *.out *.dat log
