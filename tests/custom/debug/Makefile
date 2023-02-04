# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

TARGET = debug

%.elf.memfile: %.elf %.elf.objdump.adr
	riscv64-unknown-elf-elf2hex --bit-width $(if $(findstring rv64,$*),64,32) --input $< --output $@

%.elf.objdump.addr: %.elf.objdump
	extractFunctionRadix.sh $<

$(TARGET).objdump: $(TARGET).elf
	riscv64-unknown-elf-objdump -D $(TARGET).elf > $(TARGET).objdump
    
$(TARGET): $(TARGET).S Makefile
	riscv64-unknown-elf-gcc -g -o $(TARGET).elf -march=rv64gc -mabi=lp64 -mcmodel=medany \
	    -nostartfiles -T../../link/link.ld $(TARGET).S 

sim:
	spike +signature=$(TARGET).signature.output +signature-granularity=8 $(TARGET)
	diff --ignore-case $(TARGET).signature.output $(TARGET).reference_output || exit
	echo "Signature matches! Success!"

clean:
	rm -f $(TARGET).elf $(TARGET).objdump $(TARGET).objdump.adr %(TARGET).elf.memfile $(TARGET).signature.output



