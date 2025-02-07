TARGET = exercise_3.7

$(TARGET).objdump: $(TARGET)
	riscv64-unknown-elf-objdump -S -D $(TARGET) > $(TARGET).objdump
    
$(TARGET): $(TARGET).c Makefile
	riscv64-unknown-elf-gcc -o $(TARGET) -gdwarf-2 -O2\
	  -march=rv64gc -mabi=lp64d -mcmodel=medany \
	  -nostdlib -static -lm -fno-tree-loop-distribute-patterns \
	  -T../common/test.ld -I../common \
	  $(TARGET).c ../common/crt.S ../common/syscalls.c

clean:
	rm -f $(TARGET) $(TARGET).objdump