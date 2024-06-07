TARGETDIR	:= lpddr_test
TARGET		:= $(TARGETDIR)/$(TARGETDIR).elf
ROOT		:= ..
LIBRARY_DIRS	:= ${ROOT}/crt0 ${ROOT}/../../soc/fsbl
LIBRARY_FILES	:= crt0 fsbl

MARCH           :=-march=rv64imfdczicbom
MABI            :=-mabi=lp64d
LINKER          := ${ROOT}/linker8000-0000.x
LINK_FLAGS      :=$(MARCH) $(MABI) -nostartfiles -Wl,-Map=$(TARGET).map

CFLAGS =$(MARCH) $(MABI) -Wa,-alhs -Wa,-L -mcmodel=medany  -mstrict-align -O2
AS=riscv64-unknown-elf-as
CC=riscv64-unknown-elf-gcc
DA=riscv64-unknown-elf-objdump -d

include $(ROOT)/makefile.inc
