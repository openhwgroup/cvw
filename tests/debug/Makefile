# This Makefile compiles for 32 bit configurations exclusively for now
RISCV ?= /opt/riscv

CC = riscv64-unknown-elf-gcc
AS = riscv64-unknown-elf-as
LD = riscv64-unknown-elf-ld
OBJDUMP = riscv64-unknown-elf-objdump

SOURCE := $(shell find . -type f -name "*.S")
OBJ := $(SOURCE:.s=.o)

LDSCRIPT := ./link.ld

# RV32
# MARCH = -march=rv32imfdc_zicsr_zifencei
# MABI = -mabi=ilp32
# ASFLAGS := $(MARCH) $(MABI) -mcmodel=medany -nostartfiles -L $(RISCV)/riscv64-unknown-elf/lib -T$(LDSCRIPT)

# RV64
MARCH = -march=rv64gc_zicsr_zifencei
MABI = -mabi=lp64
ASFLAGS := $(MARCH) $(MABI) -mcmodel=medany -nostartfiles -L $(RISCV)/riscv64-unknown-elf/lib -T$(LDSCRIPT)

TARGET = program.elf

.PHONY: all clean sim32 sim64 debug32 debug64 bitbang32 bitbang64
all: $(TARGET).objdump

$(TARGET): $(SOURCE)
	$(CC) $(ASFLAGS) -o $@ $(SOURCE)

$(TARGET).objdump: $(TARGET)
	$(OBJDUMP) -s -D $< > $@

clean:
	@rm -f $(TARGET)
	@rm -f $(TARGET).objdump
	@rm -f $(TARGET).signature.output

sim32:
	spike --isa=rv32imfdc_zicsr +signature=$(TARGET).signature.output +signature-granularity=8 $(TARGET)

sim64:
	spike --isa=rv64gc_zicsr +signature=$(TARGET).signature.output +signature-granularity=8 $(TARGET)

debug32:
	spike -d --isa=rv32imfdc_zicsr +signature=$(TARGET).signature.output +signature-granularity=8 $(TARGET)

debug64:
	spike -d +signature=$(TARGET).signature.output +signature-granularity=8 $(TARGET)

bitbang32:
	spike --isa=rv32imfdc_zicsr --rbb-port=9824 +signature=$(TARGET).signature.output +signature-granularity=8 $(TARGET)

bitbang64:
	spike --isa=rv64gc_zicsr --rbb-port=9824 +signature=$(TARGET).signature.output +signature-granularity=8 $(TARGET)
