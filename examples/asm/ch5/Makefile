ch5.debug: ch5
	riscv64-unknown-elf-objdump -D ch5 > ch5.debug

ch5: ch5.S Makefile
	riscv64-unknown-elf-gcc -nodefaultlibs -nostartfiles -o ch5 ch5.S
# -ffreestanding 
# -nostdlib 

clean: 
	rm -f ch5 ch5.debug