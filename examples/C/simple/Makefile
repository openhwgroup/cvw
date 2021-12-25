TARGET = simple

$(TARGET).objdump: $(TARGET)
	riscv64-unknown-elf-objdump -S -D $(TARGET) > $(TARGET).objdump
    
$(TARGET): $(TARGET).c
	riscv64-unknown-elf-gcc -g -o $(TARGET) -march=rv64gc -mabi=lp64d -mcmodel=medany \
	    -O $(TARGET).c
#	    -O -T../../link/linkc.ld $(TARGET).c
#	    -nostartfiles -nostdlib $(TARGET).c
#	    -nostartfiles -nostdlib -T../../link/link.ld $(TARGET).c

clean:
	rm -f $(TARGET) $(TARGET).objdump
