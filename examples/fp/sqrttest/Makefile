# Makefile

CC     = gcc
CFLAGS = -O3
LIBS   = -lm
LFLAGS = -L.
IFLAGS = -I$(WALLY)/addins/berkeley-softfloat-3/source/include/
LIBS   = $(WALLY)/addins/berkeley-softfloat-3/build/Linux-x86_64-GCC/softfloat.a -lm -lquadmath
SRCS   = $(wildcard *.c)
PROGS = $(patsubst %.c,%,$(SRCS))

all:	$(PROGS)

%: %.c
	$(CC) $(CFLAGS) $(IFLAGS) $(LFLAGS) -o $@ $< $(LIBS)

clean: 
	rm -f $(PROGS)
