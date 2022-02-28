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
CONFIGFILES	?= $(shell find $(CONFIGDIR) -name rv*_*)
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


DIRS = rv32e rv32gc rv64ic rv64gc rv32ic
# DELDIRS = rv32e rv32gc rv64ic rv64gc rv32ic
# CONFIGSUBDIRS = _FPUoff _noMulDiv _noVirtMem _PMP0 _PMP16 _orig


del:
	@$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_orig;)
	@$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_FPUoff;)
	@$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_PMP16;)
	@$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_PMP0;)
	@$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_noVirtMem;)
	@$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_noMulDiv;)

configs: $(DIRS)
$(DIRS): 
	#turn off FPU 
	rm -rf $(CONFIGDIR)/$@_FPUoff
	cp -r $(CONFIGDIR)/$@ $(CONFIGDIR)/$@_FPUoff
	sed -i 's/1 *<< *3/0 << 3/' $(CONFIGDIR)/$@_FPUoff/wally-config.vh
	sed -i 's/1 *<< *5/0 << 5/' $(CONFIGDIR)/$@_FPUoff/wally-config.vh

	# PMP 16 
	rm -rf $(CONFIGDIR)/$@_PMP16
	cp -r $(CONFIGDIR)/$@_FPUoff $(CONFIGDIR)/$@_PMP16
	# sed -i 's/1 *<< *3/0 << 3/' $(CONFIGDIR)/$@_PMP16/wally-config.vh
	# sed -i 's/1 *<< *5/0 << 5/' $(CONFIGDIR)/$@_PMP16/wally-config.vh
	sed -i 's/PMP_ENTRIES \(64\|16\|0\)/PMP_ENTRIES 16/' $(CONFIGDIR)/$@_PMP16/wally-config.vh
	
	# PMP 0
	rm -rf $(CONFIGDIR)/$@_PMP0
	cp -r $(CONFIGDIR)/$@_FPUoff $(CONFIGDIR)/$@_PMP0
	# sed -i 's/1 *<< *3/0 << 3/' $(CONFIGDIR)/$@_PMP0/wally-config.vh
	# sed -i 's/1 *<< *5/0 << 5/' $(CONFIGDIR)/$@_PMP0/wally-config.vh
	sed -i 's/PMP_ENTRIES \(64\|16\|0\)/PMP_ENTRIES 0/' $(CONFIGDIR)/$@_PMP0/wally-config.vh
	
	# No Virtual Memory 
	rm -rf $(CONFIGDIR)/$@_noVirtMem
	# cp -r $(CONFIGDIR)/$@ $(CONFIGDIR)/$@_noVirtMem
	# sed -i 's/1 *<< *3/0 <_PMP0< 3/' $(CONFIGDIR)/$@_noVirtMem/wally-config.vh
	# sed -i 's/1 *<< *5/0 << 5/' $(CONFIGDIR)/$@_noVirtMem/wally-config.vh
	# sed -i 's/PMP_ENTRIES \(64\|16\|0\)/PMP_ENTRIES 0/' $(CONFIGDIR)/$@_noVirtMem/wally-config.vh
	sed -i 's/VIRTMEM_SUPPORTED 1/VIRTMEM_SUPPORTED 0/' $(CONFIGDIR)/$@_noVirtMem/wally-config.vh

	#no muldiv
	rm -rf $(CONFIGDIR)/$@_noMulDiv
	cp -r $(CONFIGDIR)/$@_noVirtMem $(CONFIGDIR)/$@_noMulDiv
	# sed -i 's/1 *<< *3/0 << 3/' $(CONFIGDIR)/$@_noMulDiv/wally-config.vh
	# sed -i 's/1 *<< *5/0 << 5/' $(CONFIGDIR)/$@_noMulDiv/wally-config.vh
	# sed -i 's/PMP_ENTRIES \(64\|16\|0\)/PMP_ENTRIES 0/' $(CONFIGDIR)/$@_noMulDiv/wally-config.vh
	# sed -i 's/VIRTMEM_SUPPORTED 1/VIRTMEM_SUPPORTED 0/' $(CONFIGDIR)/$@_noMulDiv/wally-config.vh
	sed -i 's/1 *<< *12/0 << 12/' $(CONFIGDIR)/$@_noMulDiv/wally-config.vh


allsynth: $(CONFIGFILESTRIM)

$(CONFIGFILESTRIM):
	make synth DESIGN=wallypipelinedcore CONFIG=$@ TECH=sky90 FREQ=500 MAXCORES=1 --jobs

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



