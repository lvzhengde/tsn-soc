TEST_CASE ?= tc_m1s1

#make rules
default: iverilog

iverilog:
	make -f iverilog.mk TEST_CASE=$(TEST_CASE)

clean:
	make -f iverilog.mk $@
