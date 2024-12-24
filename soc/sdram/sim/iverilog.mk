TC ?= tc_simple
TARGET = test_sdram

default: $(TARGET)

$(TARGET):
	@echo "# Compiling Verilog"
	iverilog -o $(TARGET).out -s $(TC) -f input.vc 
	@echo "# Run test case $(TC)"
	vvp -n $(TARGET).out -fst 

clean:
	@rm -rf  *.out *.fst *.vcd
