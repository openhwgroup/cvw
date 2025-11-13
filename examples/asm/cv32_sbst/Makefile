################################################################################
#                                 SETTINGS                                     #
################################################################################
#RISCV_COMPILER_MARCH:= rv32imfc
#RISCV_COMPILER_PATH:= /software/xpack-riscv-none-embed-gcc-10.2.0-1.1
#RISCV_COMPILER_PREFIX := riscv-none-embed-
#
#CFLAGS=  -march=${RISCV_COMPILER_MARCH}
#RISCV_EXE_PREFIX=${RISCV_COMPILER_PATH}/bin/${RISCV_COMPILER_PREFIX}
#PROGRAM_NAME=sbst
#
#################################################################################
##                                 TARGETS                                      #
#################################################################################
#.phony: clean
#all: $(PROGRAM_NAME).hex $(PROGRAM_NAME).lst
#
#$(PROGRAM_NAME).elf: crt0.S main.S atpg_func.S hash.S common.S  csr_trap_handler.S pmp_handler.S #sbst_boot.S
#	$(RISCV_EXE_PREFIX)gcc $(CFLAGS) \
#	-O0  -static -nostdlib -ffreestanding -nostartfiles -nodefaultlibs \
#	-Wa,--warn,--size-check=error,-mcsr-check,--noexecstack,-misa-spec=20191213 \
#	-Xlinker -Map=$(PROGRAM_NAME).map -T link.ld -o $@ $^
#
#%.lst: %.elf
#	$(RISCV_EXE_PREFIX)objdump -d $^ > $@
#
#%.hex: %.elf
#	$(RISCV_EXE_PREFIX)objcopy -O verilog $< $@
#	#sed -i 's/@0020/@001C/; s/@0021/@001D/; s/@0022/@001E/; s/@0023/@001F/' $@
#
#clean:
#	$(RM) $(PROGRAM_NAME).elf $(PROGRAM_NAME).hex $(PROGRAM_NAME).map *.o $(PROGRAM_NAME).lst


sbst.objdump: sbst.elf
	riscv64-unknown-elf-objdump -D sbst.elf > sbst.objdump

sbst.elf:  
	riscv64-unknown-elf-gcc -o sbst.elf -march=rv32i_zicsr -mabi=ilp32 -mcmodel=medany \
	    -nostartfiles -O0  -static -T./link_cv32e40p.ld crt0.S main.S atpg_func.S hash.S common.S  pmp_handler.S

clean:
	rm -f sbst.elf sbst.objdump sbst.elf.memfile sbst.elf.objdump*