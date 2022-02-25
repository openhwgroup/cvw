SHELL = /bin/sh

CFLAG = -Wall -g
CC = clang

all: fixBinMem silencePipe

fixBinMem: fixBinMem.c
	${CC} ${CFLAGS} fixBinMem.c -o fixBinMem
	chmod +x fixBinMem

silencePipe: silencePipe.c
	${CC} ${CFLAGS} silencePipe.c -o silencePipe
	chmod +x silencePipe
clean:
	-rm -f fixBinMem
	-rm -f silencePipe
