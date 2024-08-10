TARGETDIR	:= bin
TARGET		:= $(TARGETDIR)/start
ROOT		:= ..
LIBRARY_DIRS	:= 
LIBRARY_FILES	:=

MARCH           :=-march=rv64imfdc
MABI            :=-mabi=lp64d
LINK_FLAGS      :=$(MARCH) $(MABI) -nostartfiles -L $(RISCV)/riscv64-unknown-elf/lib
LINKER          := ${ROOT}/linker.x

AFLAGS =$(MARCH) $(MABI) -W
CFLAGS =$(MARCH) $(MABI) -mcmodel=medany  -O2
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
