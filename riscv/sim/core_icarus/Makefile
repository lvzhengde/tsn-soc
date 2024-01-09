###############################################################################
# Variables: Program ELF
###############################################################################
TEST_PATH ?= ../../tc/core_icarus
ELF_FILE ?= $(TEST_PATH)/test.elf

OBJCOPY ?= riscv32-unknown-elf-objcopy
ifeq ($(shell which $(OBJCOPY)),)
  ${error $(OBJCOPY) missing from PATH}
endif
ifeq ($(shell which iverilog),)
  ${error iverilog missing from PATH - Icarus Verilog required}
endif


###############################################################################
# Variables: Defaults
###############################################################################
SRC_V          ?= ./file_list.txt
TRACE          ?= 1
EXE            ?= core_sim.out

###############################################################################
# Variables: Verilog
###############################################################################
VFLAGS      += -DTRACE=$(TRACE)
VFLAGS      += -Dverilog_sim

###############################################################################
# Variables: Lists of objects, source and deps
###############################################################################
BUILD_DIR      ?= build/

###############################################################################
# Rules
###############################################################################
all: run

$(BUILD_DIR):
	@mkdir -p $@

$(BUILD_DIR)/tcm.bin: $(ELF_FILE) | $(BUILD_DIR)
	$(OBJCOPY) $< -O binary $@

$(BUILD_DIR)/$(EXE): $(SRC_V) | $(BUILD_DIR)
	@echo "# Compiling verilog"
	iverilog $(VFLAGS) -o $@ -f $(SRC_V)

run: $(BUILD_DIR)/$(EXE) $(BUILD_DIR)/tcm.bin
	vvp -n $(BUILD_DIR)/$(EXE) -fst

lint:
	verilator $(VFLAGS) --lint-only --timing  -f $(SRC_V)

view:
	gtkwave waveform.fst  

clean:
	rm -rf $(BUILD_DIR) *.vcd *.fst

