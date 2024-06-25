#all:
#	./covergen.py
#	cd ../riscof; make wally-riscv-arch-test
#	cd ../../sim; make memfiles

CEXT		:= c
CPPEXT		:= cpp
AEXT		:= s
SEXT		:= S
SRCEXT 		:= \([$(CEXT)$(AEXT)$(SEXT)]\|$(CPPEXT)\)
#SRCS = $(wildcard *.S)
#PROGS = $(patsubst %.S,%,$(SRCS))
SRCDIR = ${WALLY}/tests/functcov/rv64/I
SRCEXT = S
SOURCES		?= $(shell find $(SRCDIR) -type f -regex ".*\.$(SRCEXT)" | sort)
OBJEXT = elf
OBJECTS		:= $(SOURCES:.$(SEXT)=.$(OBJEXT))

all: 
	./covergen.py
	make build

build: $(OBJECTS)

%.elf.objdump: %.elf

# Change many things if bit width isn't 64
$(SRCDIR)/%.elf: $(SRCDIR)/%.$(SEXT) 
	riscv64-unknown-elf-gcc -g -o $@ -march=rv64gqc_zfa_zba_zbb_zbc_zbs_zfh_zicboz_zicbop_zicbom -mabi=lp64 -mcmodel=medany \
	    -nostartfiles -T${WALLY}/examples/link/link.ld $<
	riscv64-unknown-elf-objdump -S -D $@ > $@.objdump
	riscv64-unknown-elf-elf2hex --bit-width 64 --input $@ --output $@.memfile
	extractFunctionRadix.sh $@.objdump
    
clean:
	rm -f ${SRCDIR}/*.elf ${SRCDIR}/*.objdump ${SRCDIR}/*.addr *${SRCDIR}/.lab ${SRCDIR}/*.memfile



