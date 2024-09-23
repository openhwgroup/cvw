# Makefile

CC     = gcc
CFLAGS = -O3
LIBS   = -lm
LFLAGS = -L.
# Link against the riscv-isa-sim version of SoftFloat rather than 
# the regular version to get RISC-V NaN behavior
IFLAGS   = -I$(RISCV)/riscv-isa-sim/softfloat
LIBS   = $(RISCV)/riscv-isa-sim/build/libsoftfloat.a
#IFLAGS = -I../../../addins/berkeley-softfloat-3/source/include/
#LIBS   = ../../../addins/berkeley-softfloat-3/build/Linux-x86_64-GCC/softfloat.a
SRCS   = $(wildcard *.c)

PROGS = $(patsubst %.c,%,$(SRCS))

all:	$(PROGS)

%: %.c
	$(CC) $(CFLAGS) $(IFLAGS) $(LFLAGS) -o $@ $< $(LIBS)

clean: 
	rm -f $(PROGS)
