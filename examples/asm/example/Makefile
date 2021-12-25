example.objdump: example
	riscv64-unknown-elf-objdump -D example > example.objdump
    
example: example.S
	riscv64-unknown-elf-gcc -o example -march=rv32i -mabi=ilp32 -mcmodel=medany \
	    -nostartfiles -nostdlib -T../../link/link.ld  example.S

clean:
	rm -f example example.objdump
