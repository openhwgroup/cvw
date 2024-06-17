all: rvvidaemon

rvvidaemon: rvvidaemon.o
	gcc $^ /opt/riscv/ImperasDV-OpenHW/Imperas/lib/Linux64/ImperasLib/imperas.com/verification/riscv/1.0/model.so  -o rvvidaemon

%.o:%.c
	gcc -I/opt/riscv/ImperasDV-OpenHW/Imperas/ImpProprietary/include/host -c $^ -o $@

clean:
	rm *.o rvvidaemon
