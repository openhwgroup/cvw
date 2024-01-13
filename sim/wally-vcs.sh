vcs -full64 +lint=all,noGCWM -sverilog -kdb +vc -Mupdate -line -lca -debug_access+all+reverse +define+ +incdir+../testbench +incdir+../config/rv64gc +incdir+../config/shared ../src/cvw.sv ../testbench/testbench.sv ../testbench/common/DCacheFlushFSM.sv ../testbench/common/checksignature.sv ../testbench/common/functionName.sv ../testbench/common/instr* ../testbench/common/loggers.sv ../testbench/common/ramxdetector.sv ../testbench/common/riscvassertions.sv ../testbench/common/watchdog.sv ../src/*/*.sv ../src/*/*/*.sv ../testbench/vcs-files/*.sv -o simv

./simv
