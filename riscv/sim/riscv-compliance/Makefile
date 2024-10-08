pipe:= |
empty:=
space:= $(empty) $(empty)

export RISCV_TARGET ?= biriscv
export RISCV_DEVICE ?= rv32i
export RISCV_PREFIX ?= riscv32-unknown-elf-

RISCV_ISA_ALL = $(shell ls $(ROOTDIR)/../../tc/riscv-compliance/riscv-target/$(RISCV_TARGET)/device)
RISCV_ISA_OPT = $(subst $(space),$(pipe),$(RISCV_ISA_ALL))

ifeq ($(RISCV_ISA),)
    RISCV_ISA = rv32i
    DEFAULT_TARGET=all_variant
else
    DEFAULT_TARGET=variant
endif

export ROOTDIR  = $(shell pwd)
export TARGETDIR ?= $(ROOTDIR)/../../tc/riscv-compliance/riscv-target

#gnu and verilog simulation tools
RISCV_GCC      ?= $(RISCV_PREFIX)gcc
RISCV_GCC_OPTS ?= -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles
COMPLIANCE_DIR ?= $(ROOTDIR)/../../tc/riscv-compliance

OBJCOPY ?= $(RISCV_PREFIX)objcopy
ifeq ($(shell which $(OBJCOPY)),)
  ${error $(OBJCOPY) missing from PATH}
endif
ifeq ($(shell which iverilog),)
  ${error iverilog missing from PATH - Icarus Verilog required}
endif

#Verilog Variables
SRC_V       ?= ./file_list.txt
TRACE       ?= 1
EXE         ?= riscv_sim.out

VFLAGS      += -DTRACE=$(TRACE)
VFLAGS      += -Dverilog_sim

#for each riscv-test-suite/isa
act_dir := $(ROOTDIR)/../../tc/riscv-compliance/riscv-test-suite/$(RISCV_ISA)
src_dir := $(act_dir)/src
work_dir := $(ROOTDIR)/work
work_dir_isa := $(work_dir)/$(RISCV_ISA)

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

SOURCES  = $(wildcard $(src_dir)/*.S)
ELFS     = $(SOURCES:$(src_dir)/%.S=$(work_dir_isa)/elf/%.elf)

default: $(DEFAULT_TARGET)

variant: compile      #just compile, simulation handled by Python script        

all_variant:
	for isa in $(RISCV_ISA_ALL); do \
		echo $$isa; \
		$(MAKE) RISCV_TARGET=$(RISCV_TARGET) RISCV_DEVICE=$$isa RISCV_ISA=$$isa variant; \
                rc=$$?; \
                if [ $$rc -ne 0 ]; then \
			exit $$rc; \
		fi \
	done
	@echo "# Compiling verilog"
	iverilog $(VFLAGS) -o $(EXE) -f $(SRC_V)

compile: $(ELFS)

$(ELFS): $(work_dir_isa)/elf/%.elf: $(src_dir)/%.S
	mkdir -p $(work_dir_isa)/elf
	mkdir -p $(work_dir_isa)/signature
	$(RISCV_GCC) -march=$(RISCV_ISA) -mabi=ilp32 $(RISCV_GCC_OPTS) \
		-I$(COMPLIANCE_DIR)/riscv-test-env/ \
		-I$(COMPLIANCE_DIR)/riscv-test-env/p/ \
		-I$(TARGETDIR)/$(RISCV_TARGET)/ \
		-T$(COMPLIANCE_DIR)/riscv-test-env/p/link.ld $< \
		-o $@; 

clean:
	@rm -rf $(work_dir) *.vcd *.fst *.out *.bin *.objdump *.output

help:
	@echo "make"
	@echo "RISCV_TARGET='biriscv'"
	@echo "RISCV_DEVICE='rv32i|rv32im|...'"
	@echo "RISCV_ISA=$(RISCV_ISA_OPT)"
	@echo "make all_variant // all combinations"

