SRCS = $(wildcard *.S)
PROGS = $(patsubst %.S,%,$(SRCS))

all: $(PROGS)

%: %.S WALLY-init-lib.h Makefile
	echo $@
	riscv64-unknown-elf-gcc -g -o $@.elf -march=rv64gc -mabi=lp64 -mcmodel=medany \
	    -nostartfiles -T../../examples/link/link.ld $@.S 
	riscv64-unknown-elf-objdump -D $@.elf > $@.objdump
    
sim: %.elf
	spike +signature=%.signature.output +signature-granularity=8 %.elf
	diff --ignore-case %.signature.output %.reference_output || exit
	echo "Signature matches! Success!"

clean:
	rm -f *.elf *.objdump *.signature.output



