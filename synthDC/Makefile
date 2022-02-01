#  
#  Makefile for synthesis
# 
NAME := synth

VARIANT := 18T_ms

default:
	@echo "Basic synthesis procedure for OSU/HMC/UNLV:"
	@echo " adapt Makefile to your liking..."
	@echo

synth:
	@sed -i 's/18T_ms/${VARIANT}/g' scripts/synth.tcl
	@sed -i 's/18T_ms/${VARIANT}/g' .synopsys_dc.setup
	@echo "DC Synthesis"
	@mkdir -p reports
	@mkdir -p mapped
	dc_shell-xg-t -64bit -f scripts/$(NAME).tcl | tee $(NAME).out
#	@cp mapped/*.sdc ../../outputs/
#	@cp mapped/*.vh ../../outputs/
#	@sed -i 's/${VARIANT}/18T_ms/g' scripts/synth.tcl
#	@sed -i 's/${VARIANT}/18T_ms/g' .synopsys_dc.setup

clean:
	rm -rf  alib-52 WORK mapped unmapped reports analyzed $(NAME).out
	mkdir mapped unmapped reports
	rm -f hdl/*
	rm -f default.svf
	rm -f command.log
	rm -f filenames*.log



