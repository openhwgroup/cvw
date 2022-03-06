SHELL = /bin/sh

CFLAG = -Wall -g
CC = gcc

all: fixBinMem

fixBinMem: fixBinMem.c
	${CC} ${CFLAGS} fixBinMem.c -o fixBinMem
	chmod +x fixBinMem

clean:
	-rm -f fixBinMem
