all: rvvidaemon

rvvidaemon: rvvidaemon.o
	gcc $^ /opt/riscv/ImperasDV-OpenHW/Imperas/lib/Linux64/ImperasLib/imperas.com/verification/riscv/1.0/model.so -o rvvidaemon

%.o:%.c
	gcc -c $^ -o $@

clean:
	rm *.o rvvidaemon
