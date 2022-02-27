#  
#  Makefile for synthesis
# 
NAME := synth

# defaults
export DESIGN ?= wallypipelinedcore
export FREQ ?= 500
export CONFIG ?= rv32e
# sky130 and sky90 presently supported
export TECH ?= sky130
# MAXCORES allows parallel compilation, which is faster but less CPU-efficient
# Avoid when doing sweeps of many optimization points in parallel
export MAXCORES ?= 4
# MAXOPT turns on flattening, boundary optimization, and retiming
# The output netlist is hard to interpret, but significantly better PPA
export MAXOPT ?= 0

time := $(shell date +%F-%H-%M)
hash := $(shell git rev-parse --short HEAD)
export OUTPUTDIR := runs/$(DESIGN)_$(CONFIG)_$(TECH)nm_$(FREQ)_MHz_$(time)_$(hash)
export SAIFPOWER ?= 0

CONFIGDIR ?= ~/riscv-wally/pipelined/config
#CONFIGS	?= $(shell find $(CONFIGDIR) -name "rv*")
CONFIGS ?= ("rv32e", "rv32ic")
CONFIGFILES	?= $(shell find $(CONFIGDIR) -name *_*)
CONFIGFILESTRIM = $(notdir $(CONFIGFILES))
print:
	echo $(CONFIGFILESTRIM)

default:
	@echo "Basic synthesis procedure for Wally:"
	@echo "  Invoke with make synth"

test: rv%
	echo "Running test on $<"

rv%.log: rv%
	echo $<


DIRS = rv32e #rv32gc rv64ic rv64gc rv32ic
CONFIGSUBDIRS = _FPUoff _noMulDiv _noVirtMem _PMP0 _PMP16 _orig
CONFIGFILES	?= $(shell find $(CONFIGDIR) -type d -regex "*_*")
del:
	@$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_orig;)
	@$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_FPUoff;)
	@$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_PMP16;)
	@$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_PMP0;)
	@$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_noVirtMem;)
	@$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_noMulDiv;)

configs:
	# @$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_orig;)
	# @$(foreach dir, $(DIRS), cp -r $(CONFIGDIR)/$(dir) $(CONFIGDIR)/$(dir)_orig;)
	# turn off FPU 
	@$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_FPUoff;)
	@$(foreach dir, $(DIRS), cp -r $(CONFIGDIR)/$(dir) $(CONFIGDIR)/$(dir)_FPUoff;)
	@$(foreach dir, $(DIRS), sed -i 's/1 *<< *3/0 << 3/' $(CONFIGDIR)/$(dir)_FPUoff/wally-config.vh;)
	@$(foreach dir, $(DIRS), sed -i 's/1 *<< *5/0 << 5/' $(CONFIGDIR)/$(dir)_FPUoff/wally-config.vh;)

	# PMP 16 
	@$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_PMP16;)
	@$(foreach dir, $(DIRS), cp -r $(CONFIGDIR)/$(dir) $(CONFIGDIR)/$(dir)_PMP16;)
	@$(foreach dir, $(DIRS), sed -i 's/PMP_ENTRIES \(64\|16\|0\)/PMP_ENTRIES 16/' $(CONFIGDIR)/$(dir)_PMP16/wally-config.vh;)
	
	# PMP 0
	@$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_PMP0;)
	@$(foreach dir, $(DIRS), cp -r $(CONFIGDIR)/$(dir) $(CONFIGDIR)/$(dir)_PMP0;)
	@$(foreach dir, $(DIRS), sed -i 's/PMP_ENTRIES \(64\|16\|0\)/PMP_ENTRIES 0/' $(CONFIGDIR)/$(dir)_PMP0/wally-config.vh;)
	
	# No Virtual Memory 
	@$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_noVirtMem;)
	@$(foreach dir, $(DIRS), cp -r $(CONFIGDIR)/$(dir) $(CONFIGDIR)/$(dir)_noVirtMem;)
	@$(foreach dir, $(DIRS), sed -i 's/VIRTMEM_SUPPORTED 1/VIRTMEM_SUPPORTED 0/' $(CONFIGDIR)/$(dir)_noVirtMem/wally-config.vh;)

	#no muldiv
	@$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_noMulDiv;)
	@$(foreach dir, $(DIRS), cp -r $(CONFIGDIR)/$(dir) $(CONFIGDIR)/$(dir)_noMulDiv;)
	@$(foreach dir, $(DIRS), sed -i 's/1 *<< *12/0 << 12/' $(CONFIGDIR)/$(dir)_noMulDiv/wally-config.vh;)


# allsynth:
# 	make configs
# 	$(foreach dir, $(CONFIGFILESTRIM), \
# 	make synth DESIGN=wallypipelinedcore CONFIG=$(dir) TECH=sky90 FREQ=500 --jobs;)

allsynth: $(CONFIGFILESTRIM)

$(CONFIGFILESTRIM):
	make synth DESIGN=wallypipelinedcore CONFIG=$@ TECH=sky90 FREQ=500 --jobs

synth:
	@echo "DC Synthesis"
	@mkdir -p hdl/
	@mkdir -p $(OUTPUTDIR)
	@mkdir -p $(OUTPUTDIR)/reports
	@mkdir -p $(OUTPUTDIR)/mapped
	@mkdir -p $(OUTPUTDIR)/unmapped
ifeq ($(SAIFPOWER), 1)
	cp -f ../pipelined/regression/power.saif .
endif
	dc_shell-xg-t -64bit -f scripts/$(NAME).tcl | tee $(OUTPUTDIR)/$(NAME).out

clean:
	rm -rf  alib-52 WORK analyzed $(NAME).out
	rm -f hdl/*
	rm -f default.svf
	rm -f command.log
	rm -f filenames*.log
	rm -f power.saif



