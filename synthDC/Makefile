#  
#  Makefile for synthesis
# 
NAME := synth

# *** instead of variant can we select 130nm, 90nm, or 28nm?
VARIANT := 18T_ms
# defaults
export DESIGN ?= wallypipelinedcore
export FREQ ?= 500
export CONFIG ?= rv32e

time := $(shell date +%F-%H-%M)
hash := $(shell git rev-parse --short HEAD)
export OUTPUTDIR := runs/$(DESIGN)_$(CONFIG)_$(FREQ)_MHz_$(time)_$(hash)

default:
	@echo "Basic synthesis procedure for OSU/HMC/UNLV:"
	@echo " adapt Makefile to your liking..."
	@echo

synth:
#	@sed -i 's/18T_ms/${VARIANT}/g' scripts/synth.tcl
#	@sed -i 's/18T_ms/${VARIANT}/g' .synopsys_dc.setup
	@echo "DC Synthesis"
	@mkdir -p hdl/
	@mkdir -p $(OUTPUTDIR)
	@mkdir -p $(OUTPUTDIR)/reports
	@mkdir -p $(OUTPUTDIR)/mapped
	@mkdir -p $(OUTPUTDIR)/unmapped
	dc_shell-xg-t -64bit -f scripts/$(NAME).tcl | tee $(OUTPUTDIR)/$(NAME).out
#	@cp mapped/*.sdc ../../outputs/
#	@cp mapped/*.vh ../../outputs/
#	@sed -i 's/${VARIANT}/18T_ms/g' scripts/synth.tcl
#	@sed -i 's/${VARIANT}/18T_ms/g' .synopsys_dc.setup

clean:
	rm -rf  alib-52 WORK analyzed $(NAME).out
	rm -f hdl/*
	rm -f default.svf
	rm -f command.log
	rm -f filenames*.log



