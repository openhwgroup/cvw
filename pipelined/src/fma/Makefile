# Makefile

CC     = gcc
CFLAGS = -O3
LIBS   = -lm
LFLAGS = -L. 
IFLAGS = -I../../../addins/SoftFloat-3e/source/include/
LIBS   = ../../../addins/SoftFloat-3e/build/Linux-x86_64-GCC/softfloat.a
SRCS   = $(wildcard *.c)

PROGS = $(patsubst %.c,%,$(SRCS))

all:	$(PROGS)

%: %.c
	$(CC) $(CFLAGS) $(IFLAGS) $(LFLAGS) -o $@ $< $(LIBS)

clean: 
	rm -f $(PROGS)
