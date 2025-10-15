# This Makefile compiles for 32 bit configurations exclusively for now
RISCV ?= /opt/riscv

CC = riscv64-unknown-elf-gcc
AS = riscv64-unknown-elf-as
LD = riscv64-unknown-elf-ld
OBJDUMP = riscv64-unknown-elf-objdump
SOURCE := $(shell find . -type f -name "*.S")
BASENAMES := $(basename $(notdir $(SOURCE)))
OBJ := $(SOURCE:.s=.o)
LDSCRIPT := ./link.ld

# Build directories
BUILD := build
LOGSDIR := $(BUILD)/log

# RV32
# MARCH = -march=rv32imfdc_zicsr_zifencei
# MABI = -mabi=ilp32
# ASFLAGS := $(MARCH) $(MABI) -mcmodel=medany -nostartfiles -L $(RISCV)/riscv64-unknown-elf/lib -T$(LDSCRIPT)

# RV64
MARCH = -march=rv64gc_zicsr_zifencei
MABI = -mabi=lp64
ASFLAGS := $(MARCH) $(MABI) -mcmodel=medany -nostartfiles -L $(RISCV)/riscv64-unknown-elf/lib -T$(LDSCRIPT)

TARGET := $(BUILD)/$(BASENAMES).elf
TVDIR := testvectors
TVBUILDDIR := $(BUILD)/testvectors
TESTVECTORS := $(TVBUILDDIR)/$(BASENAMES).tv
#TARGET = program.elf

.PHONY: all clean sim32 sim64 debug32 debug64 bitbang32 bitbang64 generate dirs
all: dirs $(TARGET).objdump $(TESTVECTORS)

dirs:
	mkdir -p $(BUILD)
	mkdir -p $(LOGSDIR)
	mkdir -p $(TVBUILDDIR)

$(TARGET): $(SOURCE)
	$(CC) $(ASFLAGS) -o $@ $(SOURCE)

$(TARGET).objdump: $(TARGET)
	$(OBJDUMP) -s -D $< > $@

clean:
	@rm -f $(TARGET)
	@rm -f $(TARGET).objdump
	@rm -f $(TARGET).signature.output
	@rm -rf $(BUILD)

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

$(TESTVECTORS): $(TARGET)
	./debugtestgen.py -s $< -t $(TVDIR)/$(basename $(notdir $<)).tcl
	grep "41b" $(LOGSDIR)/$(basename $(notdir $<)).log | sed 's/.*41b \([^;]*\).*/\1/' > $@
