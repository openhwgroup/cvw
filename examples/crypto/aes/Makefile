CC = gcc
CFLAGS = -g
VERBOSE ?= 0
CFLAGS += -DVERBOSE=$(VERBOSE)

RISCV_CC = riscv64-unknown-elf-gcc
RISCV_OBJDUMP = riscv64-unknown-elf-objdump
RISCV_CFLAGS = -g -DVERBOSE=0 -march=rv32gc -mabi=ilp32 -mcmodel=medany \
               -nostartfiles -T../../link/link.ld

TARGET = aes

.PHONY: all clean $(TARGET) $(TARGET).elf $(TARGET).objdump

all: $(TARGET) $(TARGET).elf $(TARGET).objdump

# Native build
$(TARGET): $(TARGET).c
	$(CC) $(CFLAGS) -o $@ $<

# RISC-V ELF build
$(TARGET).elf: $(TARGET).c Makefile
	$(RISCV_CC) $(RISCV_CFLAGS) -o $@ $<

# RISC-V objdump
$(TARGET).objdump: $(TARGET).elf
	$(RISCV_OBJDUMP) -D -M no-aliases $< > $@

clean:
	rm -f $(TARGET) $(TARGET).elf $(TARGET).objdump *~
