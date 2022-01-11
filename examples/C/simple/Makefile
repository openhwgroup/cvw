TARGET = simple

$(TARGET).objdump: $(TARGET)
	riscv64-unknown-elf-objdump -S -D $(TARGET) > $(TARGET).objdump
    
$(TARGET): $(TARGET).c Makefile
	riscv64-unknown-elf-gcc -g -o $(TARGET) -march=rv64gc -mabi=lp64d -mcmodel=medany \
	  -DPREALLOCATE=1 -mcmodel=medany -static -std=gnu99 -O2 -ffast-math -fno-common \
	  -fno-builtin-printf -fno-tree-loop-distribute-patterns \
	  -static -nostdlib -nostartfiles -lm -lgcc -T../common/test.ld \
	  -I../common \
	  -O0 $(TARGET).c \
	  ../common/crt.S ../common/syscalls.c

clean:
	rm -f $(TARGET) $(TARGET).objdump
