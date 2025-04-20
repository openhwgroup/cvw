CC = gcc
CFLAGS = -g

RISCV_CC = riscv64-unknown-elf-gcc
RISCV_OBJDUMP = riscv64-unknown-elf-objdump
COMMON_DIR = ../../C/common
RISCV_CFLAGS = -gdwarf-2 -march=rv64gc -mabi=lp64d -mcmodel=medany \
		-nostdlib -static -lm -fno-tree-loop-distribute-patterns \
		-nostartfiles -T$(COMMON_DIR)/test.ld -I$(COMMON_DIR)

TARGET = aes

.PHONY: all clean $(TARGET) $(TARGET).elf $(TARGET).objdump

all: $(TARGET) $(TARGET).elf $(TARGET).objdump

# Native build
$(TARGET): $(TARGET).c
	$(CC) $(CFLAGS) -o $@ $<

# RISC-V ELF build
$(TARGET).elf: $(TARGET).c Makefile
	$(RISCV_CC) $(RISCV_CFLAGS) -o $@.elf aes.c $(COMMON_DIR)/crt.S $(COMMON_DIR)/syscalls.c

clean:
	rm -f $(TARGET) $(TARGET).elf $(TARGET).objdump *~
