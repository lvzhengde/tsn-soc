TC ?= tc_slvh2d

#make rules
default: iverilog

iverilog:
	make -f iverilog.mk TC=$(TC)

lint:
	make -f verilator.mk TC=$(TC)

clean:
	@make -f iverilog.mk $@
	@make -f verilator.mk $@
