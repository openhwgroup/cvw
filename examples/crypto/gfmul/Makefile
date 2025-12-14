# Makefile

CC     = gcc
CFLAGS = -O3
LIBS   = 
SRCS   = $(wildcard *.c)

PROGS = $(patsubst %.c,%,$(SRCS))

all:	$(PROGS)

%: %.c
	$(CC) $(CFLAGS) $(IFLAGS) -o $@ $< $(LIBS)

clean: 
	rm -f $(PROGS)
