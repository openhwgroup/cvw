# Verilator Makefile for WALLY
# Kunlin Han, Rose Thompson, David Harris 2024
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

SHELL := /bin/bash
.PHONY: profile run questa clean

# verilator configurations
OPT=--assert
PARAMS?=--no-trace-top
NONPROF?=--stats
VERILATOR_DIR=${WALLY}/sim/verilator
SOURCE=${WALLY}/config/shared/*.vh ${WALLY}/config/${WALLYCONF} ${WALLY}/config/deriv/${WALLYCONF} ${WALLY}/src/cvw.sv ${WALLY}/testbench/*.sv ${WALLY}/testbench/common/*.sv ${WALLY}/src/*/*.sv ${WALLY}/src/*/*/*.sv
PLUS_ARGS=
PARAM_ARGS=
DEFINE_ARGS=
EXPANDED_PARAM_ARGS:=$(patsubst %,-G%,$(PARAM_ARGS))

WALLYCONF?=rv64gc
TEST?=arch64i
TESTBENCH?=testbench

# constants
# assume WALLY variable is correctly configured in the shell environment
# INCLUDE_PATH are pathes that Verilator should search for files it needs
INCLUDE_PATH="-I${WALLY}/config/shared" "-I${WALLY}/config/$(WALLYCONF)" "-I${WALLY}/config/deriv/$(WALLYCONF)"
# SOURCES are source files
SOURCES=${WALLY}/src/cvw.sv ${WALLY}/testbench/${TESTBENCH}.sv ${WALLY}/testbench/common/*.sv ${WALLY}/src/*/*.sv ${WALLY}/src/*/*/*.sv ${WALLY}/addins/verilog-ethernet/*/*.sv ${WALLY}/addins/verilog-ethernet/*/*/*/*.sv
# DEPENDENCIES are configuration files and source files, which leads to recompilation of executables
DEPENDENCIES=${WALLY}/config/shared/*.vh $(SOURCES)

WORKDIR = $(VERILATOR_DIR)/wkdir/$(WALLYCONF)_$(TEST)

# regular testbench requires a wrapper defining getenvval
ifeq ($(TESTBENCH), testbench)
	WRAPPER=${WALLY}/sim/verilator/wrapper.c
	ARGTEST=+TEST=$(TEST)
else
	WRAPPER=
	ARGTEST=
endif

default: run

run: $(WORKDIR)/V${TESTBENCH}
	mkdir -p $(VERILATOR_DIR)/logs
	$(WORKDIR)/V${TESTBENCH} ${ARGTEST} $(PLUS_ARGS)

profile: obj_dir_profiling/V${TESTBENCH}_$(WALLYCONF)
	$(VERILATOR_DIR)/obj_dir_profiling/V${TESTBENCH}_$(WALLYCONF) ${ARGTEST}
	mv gmon.out gmon_$(WALLYCONF).out
	gprof $(VERILATOR_DIR)/obj_dir_profiling/V${TESTBENCH}_$(WALLYCONF) gmon_$(WALLYCONF).out > gmon_$(WALLYCONF).log
	verilator_profcfunc gmon_$(WALLYCONF).log > gmon_$(WALLYCONF).log2
	mkdir -p $(VERILATOR_DIR)/logs_profiling
	mv gmon_$(WALLYCONF)* $(VERILATOR_DIR)/logs_profiling
	echo "Please check $(VERILATOR_DIR)/logs_profiling/gmon_$(WALLYCONF)* for logs and output files."

$(WORKDIR)/V${TESTBENCH}: $(DEPENDENCIES)
	mkdir -p $(WORKDIR)
	verilator \
	--Mdir $(WORKDIR) -o V${TESTBENCH} \
	--binary --trace \
	$(OPT) $(PARAMS) $(NONPROF) \
	--top-module ${TESTBENCH}  --relative-includes \
	$(INCLUDE_PATH) \
	${WRAPPER} \
	${DEFINE_ARGS} \
	${EXPANDED_PARAM_ARGS} \
	$(SOURCES)

obj_dir_profiling/V${TESTBENCH}_$(WALLYCONF): $(DEPENDENCIES)
	mkdir -p obj_dir_profiling
	verilator \
	--Mdir obj_dir_profiling -o V${TESTBENCH}_$(WALLYCONF) \
	--binary \
	--prof-cfuncs $(OPT) $(PARAMS) \
	--top-module ${TESTBENCH}  --relative-includes \
	$(INCLUDE_PATH) \
	${WRAPPER} \
	${DEFINE_ARGS} \
	${EXPANDED_PARAM_ARGS} \
	$(SOURCES)

clean:
	rm -rf $(VERILATOR_DIR)/wkdir $(VERILATOR_DIR)/obj_dir_profiling $(VERILATOR_DIR)/logs $(VERILATOR_DIR)/logs_profiling
