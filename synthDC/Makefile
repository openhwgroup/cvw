#  
#  Makefile for synthesis
# Shreya Sanghai (ssanghai@hmc.edu) 2/28/2022
NAME := synth

# defaults
export DESIGN ?= wallypipelinedcore
export FREQ ?= 3000
export CONFIG ?= rv32e_FPUoff
TITLE = shreya
# sky130 and sky90 presently supported
export TECH ?= sky90
# MAXCORES allows parallel compilation, which is faster but less CPU-efficient
# Avoid when doing sweeps of many optimization points in parallel
export MAXCORES ?= 1
# MAXOPT turns on flattening, boundary optimization, and retiming
# The output netlist is hard to interpret, but significantly better PPA
export MAXOPT ?= 0
export DRIVE ?= FLOP

time := $(shell date +%F-%H-%M)
hash := $(shell git rev-parse --short HEAD)
export OUTPUTDIR := newRuns/$(DESIGN)_$(CONFIG)_$(TECH)nm_$(FREQ)_MHz_$(time)_$(TITLE)_$(hash)
export SAIFPOWER ?= 0

CONFIGDIR ?= ${WALLY}/pipelined/config
CONFIGFILES	?= $(shell find $(CONFIGDIR) -name rv*_*)
CONFIGFILESTRIM = $(notdir $(CONFIGFILES))
# FREQS = 25 50 100 150 200 250 300 350 400
k = 3 6 

ifeq ($(TECH), sky130)
	FREQS = 25 50 100 150 200 250 300 350 400
else ifeq ($(TECH), sky90)
	FREQS = 500 550 600 650 700 750 800 850 900 950 1000
endif

print:
	@echo $(FREQS)
	@echo $(CONFIGFILESTRIM)


default:
	@echo "Basic synthesis procedure for Wally:"
	@echo "  Invoke with make synth"

test: rv%
	echo "Running test on $<"

rv%.log: rv%
	echo $<


DIRS32 = rv32e rv32gc rv32ic 
DIRS64 = rv64ic rv64gc
DIRS = $(DIRS32) $(DIRS64)

# bpred:
# 	@$(foreach kval, $(k), rm -rf $(CONFIGDIR)/rv64gc_bpred_$(kval);)
# 	@$(foreach kval, $(k), cp -r $(CONFIGDIR)/rv64gc $(CONFIGDIR)/rv64gc_bpred_$(kval);)
# 	@$(foreach kval, $(k), sed -i 's/BPRED_SIZE.*/BPRED_SIZE $(kval)/g' $(CONFIGDIR)/rv64gc_bpred_$(kval)/wally-config.vh;)
# 	@$(foreach kval, $(k), make synth DESIGN=wallypipelinedcore CONFIG=rv64gc_bpred_$(kval) TECH=sky90 FREQ=500 MAXCORES=4 --jobs;)
copy: 
	@$(foreach dir, $(DIRS), rm -rf $(CONFIGDIR)/$(dir)_orig;)
	@$(foreach dir, $(DIRS), cp -r $(CONFIGDIR)/$(dir) $(CONFIGDIR)/$(dir)_orig;)
	@$(foreach dir, $(DIRS), sed -i 's/WAYSIZEINBYTES.*/WAYSIZEINBYTES 512/g' $(CONFIGDIR)/$(dir)_orig/wally-config.vh;)
	@$(foreach dir, $(DIRS), sed -i 's/NUMWAYS.*/NUMWAYS 1/g' $(CONFIGDIR)/$(dir)_orig/wally-config.vh;)
	@$(foreach dir, $(DIRS), sed -i 's/BPRED_SIZE.*/BPRED_SIZE 5/g' $(CONFIGDIR)/$(dir)_orig/wally-config.vh;)

	@$(foreach dir, $(DIRS32), sed -i "s/RAM_RANGE.*/RAM_RANGE	 34\'h01FF/g" $(CONFIGDIR)/$(dir)_orig/wally-config.vh ;)
	@$(foreach dir, $(DIRS64), sed -i "s/RAM_RANGE.*/RAM_RANGE	 56\'h01FF/g" $(CONFIGDIR)/$(dir)_orig/wally-config.vh ;)


del:
	rm -rf $(CONFIGDIR)/*_*

configs: $(DIRS)
$(DIRS):
	#turn off FPU 
	rm -rf $(CONFIGDIR)/$@_FPUoff
	cp -r $(CONFIGDIR)/$@_orig $(CONFIGDIR)/$@_FPUoff
	sed -i 's/1 *<< *3/0 << 3/' $(CONFIGDIR)/$@_FPUoff/wally-config.vh
	sed -i 's/1 *<< *5/0 << 5/' $(CONFIGDIR)/$@_FPUoff/wally-config.vh

	# PMP 16 
	rm -rf $(CONFIGDIR)/$@_PMP16
	cp -r $(CONFIGDIR)/$@_FPUoff $(CONFIGDIR)/$@_PMP16
	sed -i 's/PMP_ENTRIES \(64\|16\|0\)/PMP_ENTRIES 16/' $(CONFIGDIR)/$@_PMP16/wally-config.vh
	
	# PMP 0
	rm -rf $(CONFIGDIR)/$@_PMP0
	cp -r $(CONFIGDIR)/$@_FPUoff $(CONFIGDIR)/$@_PMP0
	sed -i 's/PMP_ENTRIES \(64\|16\|0\)/PMP_ENTRIES 0/' $(CONFIGDIR)/$@_PMP0/wally-config.vh
	
	#no muldiv
	rm -rf $(CONFIGDIR)/$@_noMulDiv
	cp -r $(CONFIGDIR)/$@_PMP0 $(CONFIGDIR)/$@_noMulDiv
	sed -i 's/1 *<< *12/0 << 12/' $(CONFIGDIR)/$@_noMulDiv/wally-config.vh

	#no priv
	rm -rf $(CONFIGDIR)/$@_noPriv
	cp -r $(CONFIGDIR)/$@_noMulDiv $(CONFIGDIR)/$@_noPriv
	sed -i 's/ZICSR_SUPPORTED *1/ZICSR_SUPPORTED 0/' $(CONFIGDIR)/$@_noPriv/wally-config.vh

freqs: 
	@$(foreach freq, $(FREQS), make synth DESIGN=wallypipelinedcore CONFIG=rv32e FREQ=$(freq) MAXCORES=1;)

allsynth: $(CONFIGFILESTRIM)

$(CONFIGFILESTRIM):
	make synth DESIGN=wallypipelinedcore CONFIG=$@ TECH=sky90 FREQ=3000 MAXCORES=1


synth: clean
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
	rm -f Synopsys_stack_trace_*.txt
	rm -f crte_*.txt

fresh:
	rm -rf  WORK
	rm -f hdl/*



