.PHONY: profile run questa clean

OPT=
PARAMS?=-DVERILATOR=1 --no-trace-top
NONPROF?=--stats
VERILATOR_DIR=${WALLY}/sim/verilator
SOURCE=${WALLY}/config/shared/*.vh ${WALLY}/config/${WALLYCONF} ${WALLY}/src/cvw.sv ${WALLY}/testbench/testbench.sv ${WALLY}/testbench/common/*.sv ${WALLY}/src/*/*.sv ${WALLY}/src/*/*/*.sv

WALLYCONF?=rv64gc
TEST?=arch64i

default: run

profile: obj_dir_profiling/Vtestbench_$(WALLYCONF)
	$(VERILATOR_DIR)/obj_dir_profiling/Vtestbench_$(WALLYCONF) +TEST=$(TEST) 
	mv gmon.out gmon_$(WALLYCONF).out
	gprof $(VERILATOR_DIR)/obj_dir_profiling/Vtestbench_$(WALLYCONF) gmon_$(WALLYCONF).out > gmon_$(WALLYCONF).log
	verilator_profcfunc gmon_$(WALLYCONF).log > gmon_$(WALLYCONF).log2
	mkdir -p $(VERILATOR_DIR)/logs_profiling
	mv gmon_$(WALLYCONF)* $(VERILATOR_DIR)/logs_profiling
	echo "Please check $(VERILATOR_DIR)/logs_profiling/gmon_$(WALLYCONF)* for logs and output files."

run: wkdir/$(WALLYCONF)_$(TEST)/Vtestbench
	mkdir -p $(VERILATOR_DIR)/logs
	wkdir/$(WALLYCONF)_$(TEST)/Vtestbench +TEST=$(TEST) 2>&1 > $(VERILATOR_DIR)/logs/$(WALLYCONF)_$(TEST).log
	echo "Please check $(VERILATOR_DIR)/logs/$(WALLYCONF)_$(TEST).log for logs and output files."
	
wkdir/$(WALLYCONF)_$(TEST)/Vtestbench: $(SOURCE)
	verilator \
	--Mdir wkdir/$(WALLYCONF)_$(TEST) -o Vtestbench \
	--binary \
	$(OPT) $(PARAMS) $(NONPROF) \
	--timescale "1ns/1ns" --timing --top-module testbench  --relative-includes \
	"-I${WALLY}/config/shared" "-I${WALLY}/config/$(WALLYCONF)" \
	${WALLY}/sim/verilator/wrapper.c \
	${WALLY}/src/cvw.sv ${WALLY}/testbench/testbench.sv ${WALLY}/testbench/common/*.sv ${WALLY}/src/*/*.sv ${WALLY}/src/*/*/*.sv
	
obj_dir_profiling/Vtestbench_$(WALLYCONF): $(SOURCE)
	mkdir -p obj_dir_profiling
	verilator \
	--Mdir obj_dir_profiling -o Vtestbench_$(WALLYCONF) \
	--binary \
	--prof-cfuncs $(OPT) $(PARAMS) \
	--timescale "1ns/1ns" --timing --top-module testbench  --relative-includes \
	wrapper.c \
	"-I${WALLY}/config/shared" "-I${WALLY}/config/$(WALLYCONF)" ${WALLY}/src/cvw.sv ${WALLY}/testbench/testbench.sv ${WALLY}/testbench/common/*.sv ${WALLY}/src/*/*.sv ${WALLY}/src/*/*/*.sv

questa:
	vsim -c -do "do ${WALLY}/sim/wally-batch.do $(WALLYCONF) $(TEST)"

clean:
	rm -rf $(VERILATOR_DIR)/wkdir $(VERILATOR_DIR)/obj_dir_profiling $(VERILATOR_DIR)/logs $(VERILATOR_DIR)/logs_profiling