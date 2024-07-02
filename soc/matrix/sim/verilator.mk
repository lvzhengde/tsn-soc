TEST_CASE ?= tc_m1s1
TARGET = bus_matrix

OUTDIR = out
VERILATOR_FLAGS :=  -Wno-fatal -top $(TEST_CASE) -Mdir $(OUTDIR) -cc -binary -build -j 2 --trace
VERILATOR_FLAGS +=  -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND

default: $(TARGET)

$(TARGET):
	@echo "# Compiling Verilog--using Verilator for lint only"
	verilator $(VERILATOR_FLAGS) -f input.vc  
	#@echo "# Run test case $(TEST_CASE)"
	#./$(OUTDIR)/V$(TEST_CASE)

clean:
	@rm -rf $(OUTDIR) *.out *.fst *.vcd
