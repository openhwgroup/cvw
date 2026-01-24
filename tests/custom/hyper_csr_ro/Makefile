TARGETDIR := bin
TARGET := $(TARGETDIR)/hyper_csr_ro.elf
ROOT := ..
LIBRARY_DIRS :=
LIBRARY_FILES :=

MARCH := -march=rv32gc
MABI := -mabi=ilp32
LINKER := linker32.x
LINK_FLAGS := $(MARCH) $(MABI) -nostdlib -nostartfiles

CFLAGS := $(MARCH) $(MABI) -mcmodel=medany -mstrict-align -O2
CC := riscv64-unknown-elf-gcc

include $(ROOT)/makefile.inc

WIDTH := 32
