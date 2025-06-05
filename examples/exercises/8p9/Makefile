TARGET = 8p9

$(TARGET).elf.objdump: $(TARGET).elf
	riscv64-unknown-elf-objdump -D $(TARGET).elf > $(TARGET).elf.objdump
    
$(TARGET).elf: $(TARGET).S Makefile
	riscv64-unknown-elf-gcc -g -o $(TARGET) -march=rv32im_zicsr -mabi=ilp32 -mcmodel=medany \
	    -nostartfiles -T../../link/link.ld $(TARGET).S -o $(TARGET).elf

# simulate in ImperasDV lockstep
sim: $(TARGET).elf.objdump
	wsim rv32gc 8p9.elf --lockstepverbose > log

clean:
	rm -f $(TARGET).elf*


