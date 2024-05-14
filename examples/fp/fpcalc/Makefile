# Makefile

CC     = gcc
CFLAGS = -O3 -Wno-format-overflow
# Link against the riscv-isa-sim version of SoftFloat rather than 
# the regular version to get RISC-V NaN behavior
IFLAGS   = -I$(RISCV)/riscv-isa-sim/softfloat
LIBS   = $(RISCV)/riscv-isa-sim/build/libsoftfloat.a -lm -lquadmath
#IFLAGS = -I../../../addins/SoftFloat-3e/source/include/
#LIBS   = ../../../addins/SoftFloat-3e/build/Linux-x86_64-GCC/softfloat.a -lm -lquadmath
SRCS   = $(wildcard *.c)

PROGS = $(patsubst %.c,%,$(SRCS))

all:	$(PROGS)

%: %.c
	$(CC) $(CFLAGS) -DSOFTFLOAT_FAST_INT64 $(IFLAGS) $(LFLAGS) -o $@ $< $(LIBS)

clean: 
	rm -f $(PROGS)
