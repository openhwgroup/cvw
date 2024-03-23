# Common Variables
ifndef IMPERAS_HOME
$(error IMPERAS_HOME is not set)
endif

IMPERAS_HOME := $(IMPERAS_HOME)
LIB =
CONFIG_VARIANT ?= rv64i
SOURCE_PATH =+incdir+../config/$(CONFIG_VARIANT) +incdir+../config/deriv/$(CONFIG_VARIANT) +incdir+../config/shared +incdir+../testbench +incdir+/$(IMPERAS_HOME)/ImpProprietary/include/host +incdir+/$(IMPERAS_HOME)/ImpPublic/source/host/rvvi +incdir+$(IMPERAS_HOME)/ImpPublic/include/host +incdir+$(IMPERAS_HOME)/ImpProprietary/include/host
SIMFILES := $(IMPERAS_HOME)/ImpPublic/source/host/rvvi/rvviApiPkg.sv \
	    $(IMPERAS_HOME)/ImpPublic/source/host/rvvi/rvviTrace.sv \
	    $(IMPERAS_HOME)/ImpProprietary/source/host/idv/idvApiPkg.sv \
	    $(IMPERAS_HOME)/ImpProprietary/source/host/idv/idvPkg.sv \
	    $(IMPERAS_HOME)/ImpProprietary/source/host/idv/idvApiPkg.sv \
	    $(IMPERAS_HOME)/ImpProprietary/source/host/idv/trace2api.sv \
	    $(IMPERAS_HOME)/ImpProprietary/source/host/idv/trace2log.sv \
	    $(IMPERAS_HOME)/ImpProprietary/source/host/idv/trace2bin.sv \
		../src/cvw.sv ../testbench/testbench.sv ../src/*/*.sv ../src/*/*/*.sv ../testbench/common/*.sv
OUTPUT = sim_out

# VCS specific
#VCS = vcs +v2k +lint=all,noGCWM -simprofile -sverilog +vc -Mupdate -line -full64 -kdb -lca -debug_access+all+reverse +define+FPGA=$(FPGA) +define+P=$(P) +define+USE_IMPERAS_DV=$(USE_IMPERAS_DV) +define+RVVI_API_VERSION=$(RVVI_API_VERSION) +define+IDV_MAX_ERRORS=$(RVVI_API_VERSION) 
VCS = vcs +v2k +lint=all,noGCWM -simprofile -sverilog +vc -Mupdate -line -full64 -kdb -lca -debug_access+all+reverse  +define+USE_IMPERAS_DV -v2k_generate +define+P.ZICSR_SUPPORTED=1 

# Cadence Xcelium (xrun) specific
XRUN = xrun -sv -uvm -access +rwc -timescale 1ns/1ns

# QuestaSim specific
QUESTASIM = vsim -c -do "run -all; quit" -voptargs+acc

# Verilator specific
VERILATOR = verilator -Wall --cc --trace --build -Wno-ASSIGNDLY -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-ENUMVALUE

# Target for compiling and running with VCS
vcs: clean
	$(VCS) $(SOURCE_PATH) $(SIMFILES) -o $(OUTPUT)
	./$(OUTPUT) | tee program.out

# Target for compiling and running with Xcelium (xrun)
xrun: clean
	$(XRUN) $(SOURCE_PATH) $(SIMFILES) -R | tee program.out

# Target for compiling and running with QuestaSim
questasim: clean
	vlib work
	vlog $(SOURCE_PATH) $(SIMFILES)
	$(QUESTASIM) work.$(TOP_MODULE)

# Target for compiling and running with Verilator for rv32i
verilate: clean
	$(VERILATOR) $(SIMFILES) --exe --top-module testbench -CFLAGS "-DTEST_CONFIG=\\\"$(CONFIG_VARIANT)\\\"" -I../config/shared -I../config/$(CONFIG_VARIANT) ../testbench/common/*.sv --relative-includes ../testbench/testbench.sv
	./obj_dir/Vtop

# Clean up generated files
clean:
	rm -rf obj_dir work transcript vsim.wlf $(OUTPUT) *.vcd csrc ucli.key vc_hdrs.h program.out
	rm -rf simv* *.daidir dve *.vpd *.dump DVEfiles/ verdi* novas* *fsdb* *.vg *.rep *.db *.chk *.log *.out profileReport* simprofile_dir*

.PHONY: vcs xrun questasim verilate clean

