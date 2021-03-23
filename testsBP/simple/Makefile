TARGETDIR	:= simple
TARGET		:= $(TARGETDIR)/$(TARGETDIR).elf
ROOT		:= ..
LIBRARY_DIRS	:= ${ROOT}/crt0
LIBRARY_FILES	:= crt0
LINK_FLAGS      := -nostartfiles -Wl,-Map=$(TARGET).map

CFLAGS =-march=rv64ifd  -Wa,-alhs -Wa,-L -mcmodel=medany  -mstrict-align
CC=riscv64-unknown-elf-gcc
DA=riscv64-unknown-elf-objdump -d


include $(ROOT)/makefile.inc


