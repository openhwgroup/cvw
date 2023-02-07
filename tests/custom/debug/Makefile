# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

TARGET = debug

$(TARGET).signature.output: $(TARGET).elf.memfile $(TARGET).elf
	spike --isa=rv64gc +signature=$(TARGET).signature.output +signature-granularity=4 $(TARGET).elf
#	diff --ignore-case $(TARGET).signature.output $(TARGET).reference_output || exit
#	echo "Signature matches! Success!"
	mkdir -p ../work 
	cp -f * ../work

$(TARGET).elf.memfile:$(TARGET).elf $(TARGET).elf.objdump.addr
	riscv64-unknown-elf-elf2hex --bit-width 64 --input $< --output $@

$(TARGET).elf.objdump.addr: $(TARGET).elf.objdump
	extractFunctionRadix.sh $<

$(TARGET).elf.objdump: $(TARGET).elf
	riscv64-unknown-elf-objdump -D $(TARGET).elf > $(TARGET).elf.objdump
    
$(TARGET).elf: $(TARGET).S Makefile
	riscv64-unknown-elf-gcc -g -o $(TARGET).elf -march=rv64gc -mabi=lp64 -mcmodel=medany \
	    -nostartfiles -T$(WALLY)/examples/link/link.ld $(TARGET).S 


clean:
	rm -f $(TARGET).elf $(TARGET).elf.* *.signature.output



