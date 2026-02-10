TARGET = mei

all: $(TARGETS)

%.objdump: %
	riscv64-unknown-elf-objdump -D $< > $@

%: %.S Makefile
	riscv64-unknown-elf-gcc -g -o $@ -march=rv64gc -mabi=lp64 -mcmodel=medany \
	    -nostartfiles -T../../link/link.ld $<

sim:
	spike +signature=$(TARGET).signature.output +signature-granularity=8 $(TARGET)
	diff --ignore-case $(TARGET).signature.output $(TARGET).reference_output || exit
	echo "Signature matches! Success!"

clean:
	rm -f $(TARGETS) *.objdump *.signature.output
