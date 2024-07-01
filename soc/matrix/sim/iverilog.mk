TEST_CASE ?= tc_m1s1
TARGET = bus_matrix

default: $(TARGET)

$(TARGET):
	@echo "# Compiling verilog"
	iverilog -o $(TARGET).out -s $(TEST_CASE) -f input.vc  
	@echo "# Run test case $(TEST_CASE)"
	vvp -n $(TARGET).out 

clean:
	@rm -rf  *.out *.fst *.vcd
