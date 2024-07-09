all: rvvidaemon

rvvidaemon: rvvidaemon.o
	gcc $^ /opt/riscv/ImperasDV-OpenHW/lib/Linux64/ImperasLib/imperas.com/verification/riscv/1.0/model.so  -o rvvidaemon

%.o:%.c
	gcc -I/opt/riscv/ImperasDV-OpenHW/ImpProprietary/include/host -I/opt/riscv/ImperasDV-OpenHW/ImpPublic/include/host/rvvi/ -c $^ -o $@

clean:
	rm *.o rvvidaemon
