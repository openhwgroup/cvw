

CC     = gcc
CFLAGS = -O3 -Wno-format-overflow
IFLAGS = -I$(WALLY)/addins/berkeley-softfloat-3/source/include/
LIBS   = $(WALLY)/addins/berkeley-softfloat-3/build/Linux-x86_64-GCC/softfloat.a -lm -lquadmath
SRCS   = $(wildcard *.c)
PROGS = $(patsubst %.c,%,$(SRCS))

all:	$(PROGS)

%: %.c
	$(CC) $(CFLAGS) -DSOFTFLOAT_FAST_INT64 $(IFLAGS) $(LFLAGS) -o $@ $< $(LIBS)

clean:
	rm -f $(PROGS)
