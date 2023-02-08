#  
# Makefile for synthesis
# Shreya Sanghai (ssanghai@hmc.edu) 2/28/2022
# Madeleine Masser-Frye (mmasserfrye@hmc.edu) 1/27/2023
NAME := synth

# defaults
export DESIGN ?= wallypipelinedcore
export FREQ ?= 10000
export CONFIG ?= rv64gc
export MOD ?= orig
# title to add a note in the synth's directory name
TITLE = 
# tsmc28, sky130, and sky90 presently supported
export TECH ?= tsmc28
# MAXCORES allows parallel compilation, which is faster but less CPU-efficient
# Avoid when doing sweeps of many optimization points in parallel
export MAXCORES ?= 1
# MAXOPT turns on flattening, boundary optimization, and retiming
# The output netlist is hard to interpret, but significantly better PPA
export MAXOPT ?= 0
export DRIVE ?= FLOP
export USESRAM ?= 1

time := $(shell date +%F-%H-%M)
hash := $(shell git rev-parse --short HEAD)
export OUTPUTDIR := runs/$(DESIGN)_$(CONFIG)_$(MOD)_$(TECH)nm_$(FREQ)_MHz_$(time)_$(TITLE)_$(hash)
export SAIFPOWER ?= 0

OLDCONFIGDIR ?= ${WALLY}/config
export CONFIGDIR ?= $(OUTPUTDIR)/config



default:
	@echo "  Basic synthesis procedure for Wally:"
	@echo "        Invoke with make synth"
	@echo "Use wallySynth.py to run a concurrent sweep "


DIRS32 = rv32e rv32gc rv32imc rv32i
DIRS64 = rv64i rv64gc
DIRS = $(DIRS32) $(DIRS64)

# k = 3 6 
# bpred:
# 	@$(foreach kval, $(k), rm -rf $(CONFIGDIR)/rv64gc_bpred_$(kval);)
# 	@$(foreach kval, $(k), cp -r $(CONFIGDIR)/rv64gc $(CONFIGDIR)/rv64gc_bpred_$(kval);)
# 	@$(foreach kval, $(k), sed -i 's/BPRED_SIZE.*/BPRED_SIZE $(kval)/g' $(CONFIGDIR)/rv64gc_bpred_$(kval)/wally-config.vh;)
# 	@$(foreach kval, $(k), make synth DESIGN=wallypipelinedcore CONFIG=rv64gc_bpred_$(kval) TECH=sky90 FREQ=500 MAXCORES=4 --jobs;)

configs: $(CONFIG)
$(CONFIG):
	@echo $(CONFIG)
	cp -r $(OLDCONFIGDIR)/shared/*.vh $(CONFIGDIR)
	cp -r $(OLDCONFIGDIR)/$(CONFIG)/* $(CONFIGDIR)

# adjust DTIM and IROM to reasonable values depending on config	
ifneq ($(filter $(CONFIG), $(DIRS32)),)
	sed -i "s/DTIM_RANGE.*/DTIM_RANGE	 34\'h01FF/g" $(CONFIGDIR)/wally-config.vh
	sed -i "s/IROM_RANGE.*/IROM_RANGE	 34\'h01FF/g" $(CONFIGDIR)/wally-config.vh
else ifneq ($(filter $(CONFIG), $(DIRS64)),)
	sed -i "s/DTIM_RANGE.*/DTIM_RANGE	 56\'h01FF/g" $(CONFIGDIR)/wally-config.vh
	sed -i "s/IROM_RANGE.*/IROM_RANGE	 56\'h01FF/g" $(CONFIGDIR)/wally-config.vh
else 
    $(info $(CONFIG) does not exist in $(DIRS32) or $(DIRS64))
    @echo "Config not in list, RAM_RANGE will be unmodified"
endif

# if USESRAM = 1, set that in the config file, otherwise reduce sizes
ifeq ($(USESRAM), 1)
	sed -i 's/USE_SRAM.*/USE_SRAM 1/g' $(CONFIGDIR)/wally-config.vh
else
	sed -i 's/WAYSIZEINBYTES.*/WAYSIZEINBYTES 512/g' $(CONFIGDIR)/wally-config.vh
	sed -i 's/NUMWAYS.*/NUMWAYS 1/g' $(CONFIGDIR)/wally-config.vh
	sed -i 's/BPRED_SIZE.*/BPRED_SIZE 5/g' $(CONFIGDIR)/wally-config.vh
ifneq ($(filter $(CONFIG), $(DIRS32)),)
	sed -i "s/BOOTROM_RANGE.*/BOOTROM_RANGE	 34\'h01FF/g" $(CONFIGDIR)/wally-config.vh
	sed -i "s/UNCORE_RAM_RANGE.*/UNCORE_RAM_RANGE	 34\'h01FF/g" $(CONFIGDIR)/wally-config.vh
else ifneq ($(filter $(CONFIG), $(DIRS64)),)
	sed -i "s/BOOTROM_RANGE.*/BOOTROM_RANGE	 56\'h01FF/g" $(CONFIGDIR)/wally-config.vh
	sed -i "s/UNCORE_RAM_RANGE.*/UNCORE_RAM_RANGE	 56\'h01FF/g" $(CONFIGDIR)/wally-config.vh
endif
endif
	
# adjust config if synthesizing with any modifications
ifneq ($(MOD), orig)
	# PMP 0
	sed -i 's/PMP_ENTRIES \(64\|16\|0\)/PMP_ENTRIES 0/' $(CONFIGDIR)/wally-config.vh
ifneq ($(MOD), PMP0)
	# no priv
	sed -i 's/ZICSR_SUPPORTED *1/ZICSR_SUPPORTED 0/' $(CONFIGDIR)/wally-config.vh
ifneq ($(MOD), noPriv)
	# turn off FPU 
	sed -i 's/1 *<< *3/0 << 3/' $(CONFIGDIR)/wally-config.vh
	sed -i 's/1 *<< *5/0 << 5/' $(CONFIGDIR)/wally-config.vh
ifneq ($(MOD), noFPU)
	# no muldiv
	sed -i 's/1 *<< *12/0 << 12/' $(CONFIGDIR)/wally-config.vh
endif
endif
endif
endif

ifeq ($(SAIFPOWER), 1)
	cp -f ../sim/power.saif .
endif


mkdirecs:
	@echo "DC Synthesis"
	@mkdir -p $(OUTPUTDIR)
	@mkdir -p $(OUTPUTDIR)/hdl
	@mkdir -p $(OUTPUTDIR)/config
	@mkdir -p $(OUTPUTDIR)/reports
	@mkdir -p $(OUTPUTDIR)/mapped
	@mkdir -p $(OUTPUTDIR)/unmapped


synth: mkdirecs configs rundc clean

rundc:
	dc_shell-xg-t -64bit -f scripts/$(NAME).tcl | tee $(OUTPUTDIR)/$(NAME).out
	
	
clean:
	rm -rf $(OUTPUTDIR)/hdl
	rm -rf $(OUTPUTDIR)/WORK
	rm -rf $(OUTPUTDIR)/alib-52
	rm -f default.svf
	rm -f command.log
	rm -f filenames*.log
	rm -f power.saif
	rm -f Synopsys_stack_trace_*.txt
	rm -f crte_*.txt