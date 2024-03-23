# Makefile for running a design with Verilator and VCS

# Variables
DESIGN_FILE = top_flop.sv
VERILATOR_TESTBENCH = tb_flop.cpp
VCS_TESTBENCH = tb_flop.sv
TOP_MODULE = top_flop # Specify your top-level module name here
BUILD_DIR = obj_dir
SOURCE_PATH = +incdir+../../../../../src/generic/flop/ 
SIMFILES = ../../../../../src/generic/flop/*.sv

# Verilator specific
VERILATOR = verilator
VERILATOR_FLAGS = -Wall --cc --exe --trace --timing -Wno-SYMRSVDWORD

# VCS specific
VCS = vcs
# Enable code coverage and specify the directory for coverage results
VCS_FLAGS = -full64 -sverilog +v2k -debug_acc+all+dmptf -debug_region+cell+encrypt 
CODE_COV_FLAGS= -cm line+cond+fsm+tgl+branch -cm_dir COVERAGE
# To handle the ASLR-related behavior/message
SIM_FLAGS = -no_save

# Default target
all:
	@echo "Specify 'make verilate' for Verilator or 'make vcs' for VCS."


# Verilate and run with Verilator
verilate: clean_verilate
	$(VERILATOR) $(VERILATOR_FLAGS)  --top-module $(TOP_MODULE) --relative-includes $(DESIGN_FILE)


# Compile and run with VCS with code coverage
vcs: clean_vcs
	mkdir -p $(BUILD_DIR) # Ensure the build directory exists
	mkdir -p $(BUILD_DIR)/coverage # Ensure the coverage directory exists as well
	# To specify a different top-level module, replace $(TOP_MODULE) with your module name in the VCS command below
	# $(VCS) $(VCS_FLAGS) $(SOURCE_PATH) $(SIMFILES) $(CODE_COV_FLAGS) $(DESIGN_FILE) $(VCS_TESTBENCH) -o $(BUILD_DIR)/vcs_simv
	$(VCS) $(VCS_FLAGS)  $(DESIGN_FILE) $(VCS_TESTBENCH) -o $(BUILD_DIR)/vcs_simv
	./$(BUILD_DIR)/vcs_simv $(SIM_FLAGS)
	# Generate and view the coverage report
	#urg -lca -dir COVERAGE.vdb 

# To pass parameters to your simulation, you can use the +define+NAME=VALUE syntax with VCS.
# For example, to define a parameter named PARAM with a value of 10, add '+define+PARAM=10' to the VCS_FLAGS variable.

# Clean up Verilator generated files
clean_verilate:
	rm -rf $(BUILD_DIR)

# Clean up VCS generated files and coverage reports
clean_vcs:
	rm -rf csrc $(BUILD_DIR)/vcs_simv.daidir $(BUILD_DIR)/vcs_simv ucli.key vc_hdrs.h $(BUILD_DIR)/coverage

# Clean up all generated files
clean: clean_verilate clean_vcs
	rm -rf *.vcd

.PHONY: all verilate vcs clean clean_verilate clean_vcs

