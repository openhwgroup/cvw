all: rvvidaemon

rvvidaemon: rvvidaemon.o
	gcc $^ $(RISCV)/ImperasDV-OpenHW/lib/Linux64/ImperasLib/imperas.com/verification/riscv/1.0/model.so  -o rvvidaemon

%.o:%.c
	gcc -I$(RISCV)/ImperasDV-OpenHW/ImpProprietary/include/host -I$(RISCV)/ImperasDV-OpenHW/ImpPublic/include/host/rvvi/ -c $^ -o $@

clean:
	rm *.o rvvidaemon
