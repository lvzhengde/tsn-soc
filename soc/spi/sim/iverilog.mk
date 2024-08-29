TC ?= tc_regraw
TARGET = test_spi

default: $(TARGET)

$(TARGET):
	@echo "# Compiling Verilog"
	iverilog -o $(TARGET).out -s $(TC) -f input.vc 
	@echo "# Run test case $(TC)"
	vvp -n $(TARGET).out -fst 

clean:
	@rm -rf  *.out *.fst *.vcd
