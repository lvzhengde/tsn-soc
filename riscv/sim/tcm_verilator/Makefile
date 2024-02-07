export ROOTDIR  = $(shell pwd)
work_dir := $(ROOTDIR)/work

#gnu tool chain
RISCV_PATH := $(RISCV)
RISCV_GCC     := $(abspath $(RISCV_PATH)/bin/riscv32-unknown-elf-gcc)
RISCV_AS      := $(abspath $(RISCV_PATH)/bin/riscv32-unknown-elf-as)
RISCV_GXX     := $(abspath $(RISCV_PATH)/bin/riscv32-unknown-elf-g++)
RISCV_OBJDUMP := $(abspath $(RISCV_PATH)/bin/riscv32-unknown-elf-objdump)
RISCV_GDB     := $(abspath $(RISCV_PATH)/bin/riscv32-unknown-elf-gdb)
RISCV_AR      := $(abspath $(RISCV_PATH)/bin/riscv32-unknown-elf-ar)
RISCV_OBJCOPY := $(abspath $(RISCV_PATH)/bin/riscv32-unknown-elf-objcopy)
RISCV_READELF := $(abspath $(RISCV_PATH)/bin/riscv32-unknown-elf-readelf)

#riscv32 arch
RISCV_ARCH := rv32im
RISCV_ABI := ilp32
RISCV_MCMODEL := medlow

#C program setting
TARGET = c_demo.elf
SW_DIR = ../../tc/c_demo/sw
TC_DIR = ../../tc/tcm_verilator

C_SRCS := $(SW_DIR)/demo.c
ASM_SRCS += $(SW_DIR)/start.S
ASM_SRCS += $(SW_DIR)/trap_entry.S
C_SRCS += $(SW_DIR)/init.c
C_SRCS += $(SW_DIR)/trap_handler.c

LINKER_SCRIPT := $(TC_DIR)/link.lds

INCLUDES += -I$(SW_DIR)
LDFLAGS += -T $(LINKER_SCRIPT) -nostartfiles -Wl,--gc-sections -Wl,--check-sections

ASM_OBJS := $(ASM_SRCS:$(SW_DIR)/%.S=$(work_dir)/%.o)
C_OBJS := $(C_SRCS:$(SW_DIR)/%.c=$(work_dir)/%.o)

LINK_OBJS += $(ASM_OBJS) $(C_OBJS)
LINK_DEPS += $(LINKER_SCRIPT)

CLEAN_OBJS += $(TARGET) $(LINK_OBJS) $(TARGET).dump tcm.bin

CFLAGS += -DSIMULATION
CFLAGS += -march=$(RISCV_ARCH)
CFLAGS += -mabi=$(RISCV_ABI)
CFLAGS += -mcmodel=$(RISCV_MCMODEL) -ffunction-sections -fdata-sections -fno-builtin-printf -fno-builtin-malloc

#make rules
default: $(TARGET)

$(TARGET): $(LINK_OBJS) $(LINK_DEPS) Makefile
	$(RISCV_GCC) $(CFLAGS) $(INCLUDES) $(LINK_OBJS) -o $@ $(LDFLAGS)
	$(RISCV_OBJCOPY) -O binary $@ tcm.bin
	$(RISCV_OBJDUMP) --disassemble-all $@ > $@.dump

$(ASM_OBJS): $(work_dir)/%.o: $(SW_DIR)/%.S 
	mkdir -p $(work_dir)
	$(RISCV_GCC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

$(C_OBJS): $(work_dir)/%.o: $(SW_DIR)/%.c 
	mkdir -p $(work_dir)
	$(RISCV_GCC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

.PHONY: clean
clean:
	rm -rf work build logs $(CLEAN_OBJS) *.out *.fst *.vcd

