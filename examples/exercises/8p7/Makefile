TARGET = 8p7

$(TARGET).elf.objdump: $(TARGET).elf
	riscv64-unknown-elf-objdump -D $(TARGET).elf > $(TARGET).elf.objdump
    
$(TARGET).elf: $(TARGET).S Makefile
	riscv64-unknown-elf-gcc -g -o $(TARGET) -march=rv32im_zicsr -mabi=ilp32 -mcmodel=medany \
	    -nostartfiles -T../../link/link.ld $(TARGET).S -o $(TARGET).elf

# simulate with Spike
sim: $(TARGET).elf.objdump
	spike --isa=rv32i_zicsr -d $(TARGET).elf

clean:
	rm -f $(TARGET).elf*


