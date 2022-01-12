TARGET = sum

$(TARGET).objdump: $(TARGET)
	riscv64-unknown-elf-objdump -S $(TARGET) > $(TARGET).objdump
    
$(TARGET): $(TARGET).c Makefile
	riscv64-unknown-elf-gcc -o $(TARGET) -g -O \
	  -march=rv64gc -mabi=lp64d -mcmodel=medany \
	  -nostartfiles -T../common/test.ld -I../common \
	  $(TARGET).c ../common/crt.S ../common/syscalls.c
# Compiler flags:
#  -o $(TARGET) defines the name of the output file
#  -g generates debugging symbols for gdb
#  -O turns on basic optimization
#  -march=rv64gc -mabi=lp64d =mcmodel=medany generates code for RV64GC with doubles and long/ptrs = 64 bits
#  -nostartfiles avoids inserting standard startup files because we are using crt.s
#  -T specifies the linker file
#  -I specifies the include path (e.g. for util.h)
#  The last line defines the C files to compile.  
#    crt.S is needed as our startup file to initialize the processor
#    syscalls.c implements printf through the HTIF for Spike
# other flags from riscv-tests makefiles that don't seem to be important
#	  -ffast-math -DPREALLOCATE=1 -std=gnu99 -fno-tree-loop-distribute-patterns 
#     -fno-common -static  -fno-builtin-printf -nostdlib -lm -lgcc 

clean:
	rm -f $(TARGET) $(TARGET).objdump
