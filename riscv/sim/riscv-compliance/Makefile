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

RISCV_GCC      ?= $(RISCV_PREFIX)gcc
RISCV_GCC_OPTS ?= -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles
COMPLIANCE_DIR ?= $(ROOTDIR)/../../tc/riscv-compliance

#for each riscv-test-suite/isa
act_dir := $(ROOTDIR)/../../tc/riscv-compliance/riscv-test-suite/$(RISCV_ISA)
src_dir := $(act_dir)/src
work_dir := $(ROOTDIR)/work
work_dir_isa := $(work_dir)/$(RISCV_ISA)

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

SOURCES  = $(wildcard $(src_dir)/*.S)
ELFS     = $(SOURCES:$(src_dir)/%.S=$(work_dir_isa)/%.elf)

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

compile: $(ELFS)

$(ELFS): $(work_dir_isa)/%.elf: $(src_dir)/%.S
	mkdir -p $(work_dir_isa)
	$(RISCV_GCC) -march=$(RISCV_ISA) -mabi=ilp32 $(RISCV_GCC_OPTS) \
		-I$(COMPLIANCE_DIR)/riscv-test-env/ \
		-I$(COMPLIANCE_DIR)/riscv-test-env/p/ \
		-I$(TARGETDIR)/$(RISCV_TARGET)/ \
		-T$(COMPLIANCE_DIR)/riscv-test-env/p/link.ld $< \
		-o $@; 

clean:
	rm -rf $(work_dir) *.vcd *.fst

help:
	@echo "make"
	@echo "RISCV_TARGET='biriscv'"
	@echo "RISCV_DEVICE='rv32i|rv32im|...'"
	@echo "RISCV_ISA=$(RISCV_ISA_OPT)"
	@echo "make all_variant // all combinations"

