TARGETDIR	:= qsort
TARGET		:= $(TARGETDIR)/$(TARGETDIR).elf
ROOT		:= ..
LIBRARY_DIRS	:= ${ROOT}/crt0
LIBRARY_FILES	:= crt0

MARCH           :=-march=rv64ic
MABI            :=-mabi=lp64
LINK_FLAGS      :=$(MARCH) $(MABI) -nostartfiles -Wl,-Map=$(TARGET).map -L $(RISCV)/riscv64-unknown-elf/lib
LINKER          := ${ROOT}/linker8000-0000.x

CFLAGS =$(MARCH) $(MABI) -Wa,-alhs -Wa,-L -mcmodel=medany  -mstrict-align -O2

CC=riscv64-unknown-elf-gcc
DA=riscv64-unknown-elf-objdump -d


include $(ROOT)/makefile.inc


