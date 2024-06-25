TARGET = simple

$(TARGET).objdump: $(TARGET)
	riscv64-unknown-elf-objdump -S -D $(TARGET).elf > $(TARGET).objdump

    
$(TARGET): $(TARGET).c Makefile
	riscv64-unknown-elf-gcc -o $(TARGET).elf -g\
	  -march=rv64gc -mabi=lp64d -mcmodel=medany \
	  -nostdlib -static -lm -fno-tree-loop-distribute-patterns \
	  -Ttest.ld $(TARGET).c 

clean:
	rm -f $(TARGET).elf $(TARGET).objdump
