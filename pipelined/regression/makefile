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
	make -C $(ARCHDIR) XLEN=64 --jobs
	make -C $(WALLYDIR) --jobs
	make -C $(WALLYDIR) XLEN=64 --jobs
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
	echo $(shell echo $(strip $(subst rv,,$(findstring rv64,$*))) | head -c 2)
#ifeq (64,$(subst rv,,$(findstring rv64,$*)))
#ifeq (64,$(shell echo $(strip $(subst rv,,$(findstring rv64,$*))) | head -c 2))
#ifeq (64,$(subst rv,,$(findstring rv64,$*)))
#ifneq (,$(shell echo $(strip $(subst rv,,$(findstring rv64,$*))) | head -c 2))
	echo $(findstring rv64,$*)
	echo hello $* $(shell echo $(findstring rv64,$*) | head -c 4)
#ifneq (,$(findstring rv64,$*))
ifneq ('',$(shell echo $(findstring rv64,$*) | head -c 4))
	@echo got 64
#	echo riscv64-unknown-elf-elf2hex --bit-width 64 --input $< --output $@
else
	@echo got 32
#	echo riscv64-unknown-elf-elf2hex --bit-width 32 --input $< --output $@
endif

%.elf.objdump.addr: %.elf.objdump
	extractFunctionRadix.sh $<

#riscv64-unknown-elf-elf2hex --bit-width $(shell echo $* | head -c 4 | tail -c 2) --input $< --output $@
