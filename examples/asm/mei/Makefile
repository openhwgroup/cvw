TARGET = mei

$(TARGET).objdump: $(TARGET)
	riscv64-unknown-elf-objdump -D $(TARGET) > $(TARGET).objdump

%: %.S Makefile
	riscv64-unknown-elf-gcc -g -o $@ -march=rv64gc -mabi=lp64 -mcmodel=medany \
	    -nostartfiles -T../../link/link.ld $<

sim:
	spike -d +signature=$(TARGET).signature.output +signature-granularity=8 $(TARGET)
	diff --ignore-case $(TARGET).signature.output $(TARGET).reference_output || exit
	echo "Signature matches! Success!"

wally:
	wsim rv64gc --elf $(TARGET) --lockstepverbose

clean:
	rm -f $(TARGET) *.objdump* *.signature.output *.elf* *.memfile
