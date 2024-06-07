TARGETDIR	:= bin
TARGET		:= $(TARGETDIR)/fsbl
ROOT		:= ../../tests/custom
LIBRARY_DIRS	:= 
LIBRARY_FILES	:=

MARCH			:=-march=rv64imfdc
MABI            :=-mabi=lp64d
LINK_FLAGS      :=$(MARCH) $(MABI) -nostartfiles
LINKER			:=$(ROOT)/linker.x

AFLAGS =$(MARCH) $(MABI) -W
CFLAGS =$(MARCH) $(MABI) -mcmodel=medany -O2
AS=riscv64-unknown-elf-as
CC=riscv64-unknown-elf-gcc
AR=riscv64-unknown-elf-ar

all: libfsbl.a

%.o: %.s
	${AS} ${AFLAGS} -c $< -o $@

libfsbl.a: config_bsg_dmc.o config_pll.o
	${AR} -r $@ $^

clean:
	rm -rf *.a *.o
