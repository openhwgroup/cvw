TARGET = pause

$(TARGET).objdump: $(TARGET)
	riscv64-unknown-elf-objdump -D $(TARGET) > $(TARGET).objdump
    
pause: pause.S Makefile
	riscv64-unknown-elf-gcc -o pause -march=rv32ia_zihintpause -mabi=ilp32 -mcmodel=medany \
	    -nostartfiles -T../../link/link.ld  pause.S

clean:
	rm -f $(TARGET) $(TARGET).objdump
