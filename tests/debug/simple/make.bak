TARGET = simple

$(TARGET).objdump: $(TARGET)
	riscv64-unknown-elf-objdump -S -D $(TARGET) > $(TARGET).objdump
	spike $(TARGET)
    
$(TARGET): $(TARGET).c Makefile
	riscv64-unknown-elf-gcc -o $(TARGET) -g\
	  -march=rv64gc -mabi=lp64d -mcmodel=medany \
	  -nostdlib -static -lm -fno-tree-loop-distribute-patterns \
	  -T../../../examples/C/common/test.ld -I../../../examples/C/common/ \
	  $(TARGET).c ../../../examples/C/common/crt.S ../../../examples/C/common/syscalls.c

clean:
	rm -f $(TARGET) $(TARGET).objdump
