ROOT	:= ../..
SUFFIX	:= work
ARCHDIR	:= $(ROOT)/addins/riscv-arch-test
WALLYDIR:= $(ROOT)/tests/wally-riscv-arch-test
IMPERASDIR	:= $(ROOT)/tests/imperas-riscv-tests
DIR1	:= $(ROOT)/addins/riscv-arch-test/$(SUFFIX)
DIR2	:= $(ROOT)/tests/wally-riscv-arch-test/$(SUFFIX)
DIR3	:= $(ROOT)/tests/imperas-riscv-tests/$(SUFFIX)
ALLDIRS := $(DIR1) $(DIR2) $(DIR3)


#ALLDIRS	:= .

ELFFILES	?= $(shell find $(ALLDIRS) -type f -regex ".*\.elf")
MEMFILES ?= $(ELFFILES:.elf=.elf.memfile)
ADDRFILES ?= $(ELFFILES:.elf=.elf.objdump.addr)

print:
	echo "files in $(ALLDIRS) are $(ELFFILES)."
	echo "memfiles are $(MEMFILES)"

.PHONY: all
#.NOTPARALLEL: all
all: elfs wally-sim-files

wally-sim-files: $(MEMFILES) $(ADDRFILES)
	echo "$@"

.PHONY: elfs
elfs:
	make -C $(ARCHDIR) --jobs
	make -C $(ARCHDIR) XLEN=32 --jobs
	make -C $(WALLYDIR) --jobs
	make -C $(WALLYDIR) XLEN=32 --jobs
	make -C $(IMPERASDIR) --jobs
	make -C $(IMPERASDIR) XLEN=64 --jobs

# notes to self on how this works.
# The find command locates all of the *.elf files in directory DIR1.  A list of .memfiles and
# .addr files are generated from the .elf.  These are used as targets.
# % is a wildcard in a make target which is then referenced as % in the depenecies and $*
# in the recipe.
# because elf2hex requires a bit width we use findstring to figure out if the compiled directory
# is XLEN=64 or 32. This is hacky and will likely break in the future.
# the .addr is a separate target so make can split into more jobs and more parallism.
%.elf.memfile: %.elf
	riscv64-unknown-elf-elf2hex --bit-width $(if $(findstring rv64,$*),64,32) --input $< --output $@

%.elf.objdump.addr: %.elf.objdump
	extractFunctionRadix.sh $<

#riscv64-unknown-elf-elf2hex --bit-width $(shell echo $* | head -c 4 | tail -c 2) --input $< --output $@
