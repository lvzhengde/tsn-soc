TC ?= tc_simple

#make rules
default: iverilog

iverilog:
	make -f iverilog.mk TC=$(TC)

lint:
	make -f verilator.mk TC=$(TC)

clean:
	@make -f iverilog.mk $@
	@make -f verilator.mk $@
