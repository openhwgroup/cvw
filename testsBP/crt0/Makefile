TARGETDIR	:= bin
TARGET		:= $(TARGETDIR)/start
ROOT		:= ..
LIBRARY_DIRS	:= 
LIBRARY_FILES	:=

MARCH           :=-march=rv64ic
MABI            :=-mabi=lp64
LINK_FLAGS      :=$(MARCH) $(MABI) -nostartfiles

AFLAGS =$(MARCH) $(MABI) -march=rv64ic -mabi=lp64 -W
CFLAGS =$(MARCH) $(MABI) -march=rv64ic -mabi=lp64  -mcmodel=medany  -O2
AS=riscv64-unknown-elf-as
CC=riscv64-unknown-elf-gcc
AR=riscv64-unknown-elf-ar

all: libcrt0.a

%.o: %.s
	${AS} ${AFLAGS} -c $< -o $@

libcrt0.a: start.o pcnt_driver.o pre_main.o
	${AR} -r $@ $^

clean:
	rm -rf *.a *.o
