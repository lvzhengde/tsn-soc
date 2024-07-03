TC ?= tc_m1s1
TARGET = bus_matrix

OUTDIR = out
VERILATOR_FLAGS :=  -Wno-fatal -top $(TC) -Mdir $(OUTDIR) -cc -binary -build -j 2 --trace
VERILATOR_FLAGS +=  -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND

default: $(TARGET)

$(TARGET):
	@echo "# Compiling Verilog--using Verilator for lint only"
	verilator $(VERILATOR_FLAGS) -f input.vc  
	#@echo "# Run test case $(TC)"
	#./$(OUTDIR)/V$(TC)

clean:
	@rm -rf $(OUTDIR) *.out *.fst *.vcd
