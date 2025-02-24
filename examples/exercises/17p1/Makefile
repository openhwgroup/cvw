TARGET = 17p1

$(TARGET).objdump: $(TARGET).elf
	riscv64-unknown-elf-objdump -D $(TARGET).elf > $(TARGET).objdump
    
$(TARGET).elf: $(TARGET).c Makefile
	riscv64-unknown-elf-gcc -g -o $(TARGET) -march=rv64gc_zbb -mabi=lp64 -mcmodel=medany \
	    -nostartfiles -T../../link/link.ld $(TARGET).c -o $(TARGET).elf

clean:
	rm -f $(TARGET).elf $(TARGET).objdump
