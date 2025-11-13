sbst.objdump: sbst.elf
	riscv64-unknown-elf-objdump -D sbst.elf > sbst.objdump

sbst.elf: sbst.S  crt0.s  Makefile vectors.S
	riscv64-unknown-elf-gcc -o sbst.elf -march=rv32i_zicsr -mabi=ilp32 -mcmodel=medany \
	    -nostartfiles -O0  -static -T../../link/link_sbst.ld  sbst.S main.S crt0.s vectors.S pmp_handler.S

clean:
	rm -f sbst.elf sbst.objdump

#$(PROGRAM_NAME).elf: crt0.S main.S atpg_func.S hash.S common.S  csr_trap_handler.S pmp_handler.S #sbst_boot.S
#	$(RISCV_EXE_PREFIX)gcc $(CFLAGS) \
#	-O0  -static -nostdlib -ffreestanding -nostartfiles -nodefaultlibs \
#	-Wa,--warn,--size-check=error,-mcsr-check,--noexecstack,-misa-spec=20191213 \
#	-Xlinker -Map=$(PROGRAM_NAME).map -T link.ld -o $@ $^