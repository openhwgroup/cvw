TARGET = matrixMult

$(TARGET).objdump: $(TARGET)
	riscv64-unknown-elf-objdump -S -D $(TARGET) > $(TARGET).objdump
	spike $(TARGET)
    
$(TARGET): $(TARGET).c Makefile
	riscv64-unknown-elf-gcc -o $(TARGET) -g -O2\
	  -march=rv64gc -mabi=lp64d -mcmodel=medany \
	  -nostdlib -static -lm -fno-tree-loop-distribute-patterns \
	  -T../common/test.ld -I../common \
	  $(TARGET).c ../common/crt.S ../common/syscalls.c