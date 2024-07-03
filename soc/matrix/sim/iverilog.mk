TC ?= tc_m1s1
TARGET = bus_matrix

default: $(TARGET)

$(TARGET):
	@echo "# Compiling verilog"
	iverilog -o $(TARGET).out -s $(TC) -f input.vc 
	@echo "# Run test case $(TC)"
	vvp -n $(TARGET).out 

clean:
	@rm -rf  *.out *.fst *.vcd
