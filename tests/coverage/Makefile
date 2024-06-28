CEXT		:= c
CPPEXT		:= cpp
AEXT		:= s
SEXT		:= S
SRCEXT 		:= \([$(CEXT)$(AEXT)$(SEXT)]\|$(CPPEXT)\)
#SRCS = $(wildcard *.S)
#PROGS = $(patsubst %.S,%,$(SRCS))
SRCDIR = .
SRCEXT = S
SOURCES		?= $(shell find $(SRCDIR) -type f -regex ".*\.$(SRCEXT)" | sort)
OBJEXT = elf
OBJECTS		:= $(SOURCES:.$(SEXT)=.$(OBJEXT))

all: $(OBJECTS)

%.elf.objdump: %.elf

# Change many things if bit width isn't 64
%.elf: $(SRCDIR)/%.$(SEXT) WALLY-init-lib.h Makefile
	riscv64-unknown-elf-gcc -g -o $@ -march=rv64gqc_zfa_zba_zbb_zbc_zbs_zfh_zicboz_zicbop_zicbom_zbkb_zbkx_zknd_zkne_zknh -mabi=lp64 -mcmodel=medany \
	    -nostartfiles -T../../examples/link/link.ld $<
	riscv64-unknown-elf-objdump -S -D $@ > $@.objdump
	riscv64-unknown-elf-elf2hex --bit-width 64 --input $@ --output $@.memfile
	extractFunctionRadix.sh $@.objdump
    
sim: %.elf
	spike +signature=%.signature.output +signature-granularity=8 %.elf
	diff --ignore-case %.signature.output %.reference_output || exit
	echo "Signature matches! Success!"

clean:
	rm -f *.elf *.objdump *.signature.output *.addr *.lab *.memfile



