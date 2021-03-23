TARGETDIR	:= bin
TARGET		:= $(TARGETDIR)/start
ROOT		:= ..
LIBRARY_DIRS	:= 
LIBRARY_FILES	:=
LINK_FLAGS      := -nostartfiles

AFLAGS =-march=rv64ifd -W
CFLAGS =-march=rv64ifd  -mcmodel=medany 
AS=riscv64-unknown-elf-as
CC=riscv64-unknown-elf-gcc
AR=riscv64-unknown-elf-ar

all: libcrt0.a

%.o: %.s
	${AS} ${AFLAGS} -c $< -o $@

libcrt0.a: start.o
	${AR} -r $@ $^

clean:
	rm -rf *.a *.o
