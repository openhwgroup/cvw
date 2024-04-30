# Verilator Makefile for WALLY
# Kunlin Han, Rose Thompson, David Harris 2024
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

SHELL := /bin/bash
.PHONY: profile run questa clean

# verilator configurations
OPT=
PARAMS?=-DVERILATOR=1 --no-trace-top
NONPROF?=--stats
VERILATOR_DIR=${WALLY}/sim/verilator
SOURCE=${WALLY}/config/shared/*.vh ${WALLY}/config/${WALLYCONF} ${WALLY}/config/deriv/${WALLYCONF} ${WALLY}/src/cvw.sv ${WALLY}/testbench/*.sv ${WALLY}/testbench/common/*.sv ${WALLY}/src/*/*.sv ${WALLY}/src/*/*/*.sv
EXTRA_ARGS=


WALLYCONF?=rv64gc
TEST?=arch64i

# constants
# assume WALLY variable is correctly configured in the shell environment
WORKING_DIR=${WALLY}/sim/verilator
TARGET=$(WORKING_DIR)/target
# INCLUDE_PATH are pathes that Verilator should search for files it needs
INCLUDE_PATH="-I${WALLY}/config/shared" "-I${WALLY}/config/$(WALLYCONF)" "-I${WALLY}/config/deriv/$(WALLYCONF)"
# SOURCES are source files
SOURCES=${WALLY}/src/cvw.sv ${WALLY}/testbench/testbench.sv ${WALLY}/testbench/common/*.sv ${WALLY}/src/*/*.sv ${WALLY}/src/*/*/*.sv
# DEPENDENCIES are configuration files and source files, which leads to recompilation of executables
DEPENDENCIES=${WALLY}/config/shared/*.vh $(SOURCES)

default: run

run: wkdir/$(WALLYCONF)_$(TEST)/Vtestbench
	mkdir -p $(VERILATOR_DIR)/logs
	wkdir/$(WALLYCONF)_$(TEST)/Vtestbench +TEST=$(TEST)
	
profile: obj_dir_profiling/Vtestbench_$(WALLYCONF)
	$(VERILATOR_DIR)/obj_dir_profiling/Vtestbench_$(WALLYCONF) +TEST=$(TEST) 
	mv gmon.out gmon_$(WALLYCONF).out
	gprof $(VERILATOR_DIR)/obj_dir_profiling/Vtestbench_$(WALLYCONF) gmon_$(WALLYCONF).out > gmon_$(WALLYCONF).log
	verilator_profcfunc gmon_$(WALLYCONF).log > gmon_$(WALLYCONF).log2
	mkdir -p $(VERILATOR_DIR)/logs_profiling
	mv gmon_$(WALLYCONF)* $(VERILATOR_DIR)/logs_profiling
	echo "Please check $(VERILATOR_DIR)/logs_profiling/gmon_$(WALLYCONF)* for logs and output files."

wkdir/$(WALLYCONF)_$(TEST)/Vtestbench: $(DEPENDENCIES)
	mkdir -p wkdir/$(WALLYCONF)_$(TEST)
	verilator \
	--Mdir wkdir/$(WALLYCONF)_$(TEST) -o Vtestbench \
	--binary --trace \
	$(OPT) $(PARAMS) $(NONPROF) \
	$(EXTRA_ARGS) \
	--top-module testbench  --relative-includes \
	$(INCLUDE_PATH) \
	${WALLY}/sim/verilator/wrapper.c \
	$(SOURCES)

obj_dir_profiling/Vtestbench_$(WALLYCONF): $(DEPENDENCIES)
	mkdir -p obj_dir_profiling
	verilator \
	--Mdir obj_dir_profiling -o Vtestbench_$(WALLYCONF) \
	--binary \
	--prof-cfuncs $(OPT) $(PARAMS) \
	$(EXTRA_ARGS) \
	--top-module testbench  --relative-includes \
	$(INCLUDE_PATH) \
	${WALLY}/sim/verilator/wrapper.c \
	$(SOURCES)

clean:
	rm -rf $(VERILATOR_DIR)/wkdir $(VERILATOR_DIR)/obj_dir_profiling $(VERILATOR_DIR)/logs $(VERILATOR_DIR)/logs_profiling