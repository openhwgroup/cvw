all: rvvidaemon

rvvidaemon: rvvidaemon.o
	gcc $^ -o rvvidaemon

%.o:%.c
	gcc -c $^ -o $@

clean:
	rm *.o rvvidaemon
