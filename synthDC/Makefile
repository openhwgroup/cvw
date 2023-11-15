#####################
# Makefile
#
# Written: ssanghai@hmc.edu, mmasserfrye@hmc.edu, james.stine@okstate.edu 15 November 2023
#
# Purpose: Makefile to be used for synthesis using DC
#
# A component of the Wally configurable RISC-V project.
#
# Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
#
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
# Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
# except in compliance with the License, or, at your option, the Apache License version 2.0. You 
# may obtain a copy of the License at
#
# https:#solderpad.org/licenses/SHL-2.1/
#
# Unless required by applicable law or agreed to in writing, any work distributed under the 
# License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
# either express or implied. See the License for the specific language governing permissions 
# and limitations under the License.
################################################

NAME := synth
# defaults
export DESIGN ?= wallypipelinedcore
export FREQ ?= 10000
export CONFIG ?= rv64gc
export MOD ?= orig
# title to add a note in the synth's directory name
TITLE = 
# tsmc28, sky130, and sky90 presently supported
export TECH ?= sky130
# MAXCORES allows parallel compilation, which is faster but less CPU-efficient
# Avoid when doing sweeps of many optimization points in parallel
export MAXCORES ?= 1
# MAXOPT turns on flattening, boundary optimization, and retiming
# The output netlist is hard to interpret, but significantly better PPA
export MAXOPT ?= 0
export DRIVE ?= FLOP
export USESRAM ?= 0
export WIDTH ?= 32
export WRAPPER ?= 1
export SAIFPOWER ?= 0

time := $(shell date +%F-%H-%M)
hash := $(shell git rev-parse --short HEAD)
# This is done to create different naming conventions to help the PPA python 
# TODO: cleanup later to utilize better parsing/lexing
ifeq ($(WRAPPER), 0)
	export OUTPUTDIR := runs/$(DESIGN)_$(WIDTH)_$(CONFIG)_$(TECH)_$(FREQ)_MHz_$(time)_$(TITLE)_$(hash)
else
	export OUTPUTDIR := runs/$(DESIGN)_$(CONFIG)_$(MOD)_$(TECH)_$(FREQ)_MHz_$(time)_$(TITLE)_$(hash)
endif

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
# 	@$(foreach kval, $(k), sed -i 's/BPRED_SIZE.*/BPRED_SIZE $(kval)/g' $(CONFIGDIR)/rv64gc_bpred_$(kval)/config.vh;)
# 	@$(foreach kval, $(k), make synth DESIGN=wallypipelinedcore CONFIG=rv64gc_bpred_$(kval) TECH=sky90 FREQ=500 MAXCORES=4 --jobs;)

configs: $(CONFIG)
$(CONFIG):
	@echo $(CONFIG)
	cp -r $(OLDCONFIGDIR)/shared/*.vh $(CONFIGDIR)
	cp -r $(OLDCONFIGDIR)/$(CONFIG)/* $(CONFIGDIR)

# adjust DTIM and IROM to reasonable values depending on config	
ifneq ($(filter $(CONFIG), $(DIRS32)),)
	sed -i "s/DTIM_RANGE.*/DTIM_RANGE	= 34\'h01FF;/g" $(CONFIGDIR)/config.vh
	sed -i "s/IROM_RANGE.*/IROM_RANGE	= 34\'h01FF;/g" $(CONFIGDIR)/config.vh
else ifneq ($(filter $(CONFIG), $(DIRS64)),)
	sed -i "s/DTIM_RANGE.*/DTIM_RANGE	= 56\'h01FF;/g" $(CONFIGDIR)/config.vh
	sed -i "s/IROM_RANGE.*/IROM_RANGE	= 56\'h01FF;/g" $(CONFIGDIR)/config.vh
else 
    $(info $(CONFIG) does not exist in $(DIRS32) or $(DIRS64))
    @echo "Config not in list, RAM_RANGE will be unmodified"
endif

# if USESRAM = 1, set that in the config file, otherwise reduce sizes
ifeq ($(USESRAM), 1)
	sed -i 's/USE_SRAM.*/USE_SRAM = 1;/g' $(CONFIGDIR)/config.vh
else
	sed -i "s/WAYSIZEINBYTES.*/WAYSIZEINBYTES = 32\'d512;/g" $(CONFIGDIR)/config.vh
	sed -i "s/NUMWAYS.*/NUMWAYS =32\'d1;/g" $(CONFIGDIR)/config.vh
	sed -i "s/BPRED_SIZE.*/BPRED_SIZE =32\'d5;/g" $(CONFIGDIR)/config.vh
	sed -i "s/BTB_SIZE.*/BTB_SIZE = 32\'d5;/g" $(CONFIGDIR)/config.vh
ifneq ($(filter $(CONFIG), $(DIRS32)),)
	sed -i "s/BOOTROM_RANGE.*/BOOTROM_RANGE	 = 34\'h01FF;/g" $(CONFIGDIR)/config.vh
	sed -i "s/UNCORE_RAM_RANGE.*/UNCORE_RAM_RANGE	= 34\'h01FF;/g" $(CONFIGDIR)/config.vh
else ifneq ($(filter $(CONFIG), $(DIRS64)),)
	sed -i "s/BOOTROM_RANGE.*/BOOTROM_RANGE	 = 56\'h01FF;/g" $(CONFIGDIR)/config.vh
	sed -i "s/UNCORE_RAM_RANGE.*/UNCORE_RAM_RANGE	= 56\'h01FF;/g" $(CONFIGDIR)/config.vh
endif
endif
	
# adjust config if synthesizing with any modifications
# This code is subtle with ifneq.  It successively turns off a larger
# set of features in order of cycle time limiting.
# When mod = orig, all features are ON
# When mod = PMP0, the number of PMP entries is set to 0
# when mod = noPriv, the privileged unit and PMP are disabled
# when mod = noFPU, the FPU, privileged unit, and PMP are disabled
# when mod = noMulDiv, the MDU, FPU, privileged unit, and PMP are disabled.
# when mod = noAtomic, the Atomic, MDU, FPU, privileged unit, and PMP are disabled

ifneq ($(MOD), orig)
	# PMP 0
	sed -i 's/PMP_ENTRIES \(64\|16\|0\)/PMP_ENTRIES = 0;/' $(CONFIGDIR)/config.vh
ifneq ($(MOD), PMP0)
	# no priv
	sed -i 's/ZICSR_SUPPORTED *1/ZICSR_SUPPORTED = 0;/' $(CONFIGDIR)/config.vh
ifneq ($(MOD), noPriv)
	# turn off FPU 
	sed -i 's/1 *<< *3/0 << 3/' $(CONFIGDIR)/config.vh
	sed -i 's/1 *<< *5/0 << 5/' $(CONFIGDIR)/config.vh
ifneq ($(MOD), noFPU)
	# no muldiv
	sed -i 's/1 *<< *12/0 << 12/' $(CONFIGDIR)/config.vh
ifneq ($(MOD), noMulDiv)
	# no atomic
	sed -i 's/1 *<< *0/0 << 0/' $(CONFIGDIR)/config.vh
endif
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

synth: mkdirecs configs rundc # clean

rundc:
ifeq ($(TECH), tsmc28psyn)
	dc_shell-xg-t -64bit -topographical_mode -f scripts/$(NAME).tcl | tee $(OUTPUTDIR)/$(NAME).out
else
	dc_shell-xg-t -64bit -f scripts/$(NAME).tcl | tee $(OUTPUTDIR)/$(NAME).out	
endif


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
	
