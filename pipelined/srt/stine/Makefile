
CC      = gcc
CFLAGS  = -lm
LIBS    = 
OBJS4   = disp.o srt4div.o
OBJS2   = disp.o srt2div.o

all:		srt4div srt2div

disp.o:		disp.h disp.c
		$(CC) -g -c -o disp.o disp.c 

srt4div.o:	srt4div.c
		$(CC) -g -c -o srt4div.o srt4div.c

srt2div.o:	srt2div.c
		$(CC) -g -c -o srt2div.o srt2div.c

srt4div:  	$(OBJS4)
		$(CC) -g -O3 -o srt4div $(OBJS4) $(CFLAGS)

srt2div:  	$(OBJS2)
		$(CC) -g -O3 -o srt2div $(OBJS2) $(CFLAGS)

clean:
	rm -f *.o *~
	rm -f core
