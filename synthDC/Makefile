#  
#  Makefile for synthesis
# 
NAME := synth

# defaults
export DESIGN ?= wallypipelinedcore
export FREQ ?= 500
export CONFIG ?= rv32e
export TECH ?= sky130

time := $(shell date +%F-%H-%M)
hash := $(shell git rev-parse --short HEAD)
export OUTPUTDIR := runs/$(DESIGN)_$(CONFIG)_$(TECH)nm_$(FREQ)_MHz_$(time)_$(hash)
export SAIFPOWER ?= 0

default:
	@echo "Basic synthesis procedure for OSU/HMC/UNLV:"
	@echo " adapt Makefile to your liking..."
	@echo

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



