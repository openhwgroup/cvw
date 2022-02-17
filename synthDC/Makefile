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

print:
	echo "files in $(CONFIGDIR) are $(CONFIGS)."

default:
	@echo "Basic synthesis procedure for Wally:"
	@echo "  Invoke with make synth"

test: rv%
	echo "Running test on $<"

rv%.log: rv%
	echo $<

flavors:
	rm -rf $(CONFIGDIR)/rv32em
	cp -r $(CONFIGDIR)/rv32e $(CONFIGDIR)/rv32em
	sed -i 's/h00000010/h00001010/' $(CONFIGDIR)/rv32em/wally-config.vh
	# rv32e, 32ic, 32gc 64ic, 64gc
	# 64gc - FPU
	# PMP16
	# PMP0
	# No virtual memory
	# Muldiv
	

allsynth: 
	make flavors
	make synth DESIGN=wallypipelinedcore CONFIG=rv32e TECH=sky90 FREQ=500 MAXCORES=1
	make synth DESIGN=wallypipelinedcore CONFIG=rv32em TECH=sky90 FREQ=500 MAXCORES=1

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



