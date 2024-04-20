# Verilator Makefile for WALLY
# Kunlin Han, Rose Thompson, David Harris 2024
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

SHELL := /bin/bash
.PHONY: profile run questa clean

# verilator configurations
OPT=
PARAMS?=-DVERILATOR=1 --no-trace-top
NONPROF?=--stats
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

profile: obj_dir_profiling/Vtestbench_$(WALLYCONF)
	$(WORKING_DIR)/obj_dir_profiling/Vtestbench_$(WALLYCONF) +TEST=$(TEST) 
	mv gmon.out gmon_$(WALLYCONF).out
	gprof $(WORKING_DIR)/obj_dir_profiling/Vtestbench_$(WALLYCONF) gmon_$(WALLYCONF).out > gmon_$(WALLYCONF).log
	verilator_profcfunc gmon_$(WALLYCONF).log > gmon_$(WALLYCONF).log2
	mkdir -p $(WORKING_DIR)/logs_profiling
	mv gmon_$(WALLYCONF)* $(WORKING_DIR)/logs_profiling
	echo "Please check $(WORKING_DIR)/logs_profiling/gmon_$(WALLYCONF)* for logs and output files."

run: obj_dir_non_profiling/Vtestbench_$(WALLYCONF)
	mkdir -p $(WORKING_DIR)/logs
#	time $(WORKING_DIR)/obj_dir_non_profiling/Vtestbench_$(WALLYCONF) +TEST=$(TEST) 2>&1 > $(WORKING_DIR)/logs/$(WALLYCONF)_$(TEST).log
	time $(WORKING_DIR)/obj_dir_non_profiling/Vtestbench_$(WALLYCONF) +TEST=$(TEST)
#	echo "Please check $(WORKING_DIR)/logs/$(WALLYCONF)_$(TEST).log for logs and output files."
	
obj_dir_non_profiling/Vtestbench_$(WALLYCONF): $(DEPENDENCIES)
	mkdir -p obj_dir_non_profiling
	time verilator \
	--Mdir obj_dir_non_profiling -o Vtestbench_$(WALLYCONF) \
	-cc --binary \
	$(OPT) $(PARAMS) $(NONPROF) \
	--timescale "1ns/1ns" --timing --top-module testbench  --relative-includes \
	$(INCLUDE_PATH) \
	wrapper.c \
	$(SOURCES)
	
obj_dir_profiling/Vtestbench_$(WALLYCONF): $(DEPENDENCIES)
	mkdir -p obj_dir_profiling
	time verilator \
	--Mdir obj_dir_profiling -o Vtestbench_$(WALLYCONF) \
	-cc --binary \
	--prof-cfuncs $(OPT) $(PARAMS) \
	--timescale "1ns/1ns" --timing --top-module testbench  --relative-includes \
	$(INCLUDE_PATH) \
	wrapper.c \
	$(SOURCES)

questa:
	time vsim -c -do "do ${WALLY}/sim/wally-batch.do $(WALLYCONF) $(TEST)"

clean:
	rm -rf $(WORKING_DIR)/obj_dir_non_profiling $(WORKING_DIR)/obj_dir_profiling $(WORKING_DIR)/logs $(WORKING_DIR)/logs_profiling