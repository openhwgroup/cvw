
CC     = gcc
CFLAGS = -lm
LIBS   = 
OBJS   = disp.o srt4div.o

srt4div:  	$(OBJS)
		$(CC) -g -O3 -o srt4div $(OBJS) $(CFLAGS)

disp.o:		disp.h disp.c
		$(CC) -g -c -o disp.o disp.c $(CFLAGS)

srt4div.o:	srt4div.c
		$(CC) -g -c -o srt4div.o srt4div.c $(CFLAGS)

clean:
	rm -f *.o *~
	rm -f core
