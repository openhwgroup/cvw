TARGET = hello

$(TARGET).objdump: $(TARGET)
	riscv64-unknown-elf-objdump -S -D $(TARGET) > $(TARGET).objdump
    
$(TARGET): $(TARGET).c Makefile
	riscv64-unknown-elf-gcc -o $(TARGET) -gdwarf-2 -O\
	  -march=rv64gc -mabi=lp64d -mcmodel=medany \
	  -nostdlib -static -lm -fno-tree-loop-distribute-patterns \
	  -T../common/test.ld -I../common \
	  $(TARGET).c ../common/crt.S ../common/syscalls.c
# Compiler flags:
#  -o $(TARGET) defines the name of the output file
#  -g generates debugging symbols for gdb
#  -O turns on basic optimization; -O3 turns on heavy optimization; omit for no optimization
#  -march=rv64gc -mabi=lp64d =mcmodel=medany generates code for RV64GC with doubles and long/ptrs = 64 bits
#  -static forces static linking (no dynamic shared libraries on bare metal)
#  -lm links the math library if necessary (when #include math.h)
#  -nostdlib avoids inserting standard startup files and default libraries 
#     because we are using crt.s on bare metal
#  -fno-tree-loop-distribute-patterns turns replacing loops with memcpy/memset in the std library 
#  -T specifies the linker file
#  -I specifies the include path (e.g. for util.h)
#  The last line defines the C files to compile.  
#    crt.S is needed as our startup file to initialize the processor
#    syscalls.c implements printf through the HTIF for Spike
# other flags from riscv-tests makefiles that don't seem to be important
#	  -ffast-math -DPREALLOCATE=1 -std=gnu99  \
#     -fno-common -fno-builtin-printf -nostartfiles -lgcc \

clean:
	rm -f $(TARGET) $(TARGET).objdump* $(TARGET).memfile
