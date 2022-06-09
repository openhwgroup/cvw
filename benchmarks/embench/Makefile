# Makefile added 1/20/22 David_Harris@hmc.edu
# Expanded and developed by Daniel Torres dtorres@hmc.edu
# Compile Embench for Wally

all: sim size

allClean: clean all

build: buildspeed buildsize

# uses the build_all.py python file to build the tests in addins/embench-iot/bd_speed/ optimized for speed
buildspeed:
	../../addins/embench-iot/build_all.py --builddir=bd_speed --arch riscv32 --chip generic --board rv32wallyverilog --ldflags="-nostartfiles ../../../config/riscv32/boards/rv32wallyverilog/startup/crt0.S" --cflags="-O2 -nostartfiles" 
	find ../../addins/embench-iot/bd_speed/ -type f ! -name "*.*" | while read f; do cp "$$f" "$$f.elf"; done

# uses the build_all.py python file to build the tests in addins/embench-iot/bd_speed/ optimized for size
buildsize:
	../../addins/embench-iot/build_all.py --builddir=bd_size --arch riscv32 --chip generic --board rv32wallyverilog --ldflags="-nostdlib -nostartfiles ../../../config/riscv32/boards/rv32wallyverilog/startup/dummy.S" --cflags="-Os -msave-restore" --dummy-libs="libgcc libm libc crt0"

# builds dependencies, then launches modelsim and finally runs python wrapper script to present results
sim: modelsim_build_memfile modelsim_run speed

# launches modelsim to simulate tests on wally
modelsim_run:
	(cd ../../pipelined/regression/ && vsim -c -do "do wally-pipelined-batch.do rv32gc embench")
	cd ../../benchmarks/embench/

# builds the objdump based on the compiled c elf files
objdump: buildspeed
	find ../../addins/embench-iot/bd_speed/ -type f -name "*.elf" | while read f; do riscv64-unknown-elf-objdump -S -D "$$f" > "$$f.objdump"; done

# build memfiles, objdump.lab and objdump.addr files
modelsim_build_memfile: objdump
	find ../../addins/embench-iot/bd_speed/ -type f -name "*.elf" | while read f; do riscv64-unknown-elf-elf2hex --bit-width 32 --input "$$f" --output "$$f.memfile"; done
	find ../../addins/embench-iot/bd_speed/ -type f -name "*.elf.objdump" | while read f; do extractFunctionRadix.sh $$f; done

# builds the tests for speed, runs them on spike and then launches python script to present results
# note that the speed python script benchmark_speed.py can get confused if there's both a .output file created from spike and modelsim
# you'll need to manually remove one of the two .output files, or run make clean
spike: buildspeed spikecmd speed

# command to run spike on all of the benchmarks
spike_run: buildspeed
	find ../../addins/embench-iot/bd_speed/ -type f -name "*.elf" | while read f; do spike --isa=rv32imac +signature=$$f.spike.output +signature-granularity=4 $$f; done

# python wrapper to present results of embench size benchmark
size: buildsize
	../../addins/embench-iot/benchmark_size.py --builddir=bd_size

# python wrapper to present results of embench speed benchmark
speed:
	../../addins/embench-iot/benchmark_speed.py --builddir=bd_speed --target-module run_wally --cpu-mhz=1

# deletes all files
clean: 
	rm -rf ../../addins/embench-iot/bd_speed/
	rm -rf ../../addins/embench-iot/bd_size/

allclean: clean
	rm -rf ../../addins/embench-iot/logs/

# riscv64-unknown-elf-gcc -O2 -g -nostartfiles -I/home/harris/riscv-wally/addins/embench-iot/support -I/home/harris/riscv-wally/addins/embench-iot/config/riscv32/boards/ri5cyverilator -I/home/harris/riscv-wally/addins/embench-iot/config/riscv32/chips/generic -I/home/harris/riscv-wally/addins/embench-iot/config/riscv32 -DCPU_MHZ=1 -DWARMUP_HEAT=1 -o main.o /home/harris/riscv-wally/addins/embench-iot/support/main.c