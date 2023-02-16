# Makefile added 1/20/22 David_Harris@hmc.edu
# Expanded and developed by Daniel Torres dtorres@hmc.edu
# Compile Embench for Wally

embench_dir = ../../addins/embench-iot

all: build 
run: size sim

allClean: clean all

build: buildspeed buildsize
buildspeed: build_speedopt_speed build_sizeopt_speed
buildsize: build_speedopt_size build_sizeopt_size

# uses the build_all.py python file to build the tests in addins/embench-iot/bd_speed/ optimized for speed and size
build_speedopt_speed:
	$(embench_dir)/build_all.py --builddir=bd_speedopt_speed --arch riscv32 --chip generic --board rv32wallyverilog --ldflags="-nostartfiles ../../../config/riscv32/boards/rv32wallyverilog/startup/crt0.S" --cflags="-O2 -nostartfiles" 
	find $(embench_dir)/bd_speedopt_speed/ -type f ! -name "*.*" | while read f; do cp "$$f" "$$f.elf"; done

build_sizeopt_speed:
	$(embench_dir)/build_all.py --builddir=bd_sizeopt_speed --arch riscv32 --chip generic --board rv32wallyverilog --ldflags="-nostartfiles ../../../config/riscv32/boards/rv32wallyverilog/startup/crt0.S" --cflags="-Os -nostartfiles" 
	find $(embench_dir)/bd_sizeopt_speed/ -type f ! -name "*.*" | while read f; do cp "$$f" "$$f.elf"; done

# uses the build_all.py python file to build the tests in addins/embench-iot/bd_speed/ optimized for speed and size
build_speedopt_size:
	$(embench_dir)/build_all.py --builddir=bd_speedopt_size --arch riscv32 --chip generic --board rv32wallyverilog --ldflags="-nostdlib -nostartfiles ../../../config/riscv32/boards/rv32wallyverilog/startup/dummy.S" --cflags="-O2 -msave-restore" --dummy-libs="libgcc libm libc crt0"

build_sizeopt_size:
	$(embench_dir)/build_all.py --builddir=bd_sizeopt_size --arch riscv32 --chip generic --board rv32wallyverilog --ldflags="-nostdlib -nostartfiles ../../../config/riscv32/boards/rv32wallyverilog/startup/dummy.S" --cflags="-Os -msave-restore" --dummy-libs="libgcc libm libc crt0"

# builds dependencies, then launches modelsim and finally runs python wrapper script to present results
sim: modelsim_build_memfile modelsim_run speed

# launches modelsim to simulate tests on wally
modelsim_run:
	(cd ../../sim/ && vsim -c -do "do wally-batch.do rv32gc embench")
	cd ../../benchmarks/embench/

# builds the objdump based on the compiled c elf files
objdump:
	find $(embench_dir)/bd_*_speed/ -type f -name "*.elf" | while read f; do riscv64-unknown-elf-objdump -S -D "$$f" > "$$f.objdump"; done

# build memfiles, objdump.lab and objdump.addr files
modelsim_build_memfile: objdump
	find $(embench_dir)/bd_*_speed/ -type f -name "*.elf" | while read f; do riscv64-unknown-elf-elf2hex --bit-width 32 --input "$$f" --output "$$f.memfile"; done
	find $(embench_dir)/bd_*_speed/ -type f -name "*.elf.objdump" | while read f; do extractFunctionRadix.sh $$f; done

# builds the tests for speed, runs them on spike and then launches python script to present results
# note that the speed python script benchmark_speed.py can get confused if there's both a .output file created from spike and modelsim
# you'll need to manually remove one of the two .output files, or run make clean
spike: buildspeed spike_run speed

# command to run spike on all of the benchmarks
spike_run:
	find $(embench_dir)/bd_*opt_speed/ -type f -name "*.elf" | while read f; do spike --isa=rv32imac +signature=$$f.spike.output +signature-granularity=4 $$f; done

# python wrapper to present results of embench size benchmark
size: buildsize
	$(embench_dir)/benchmark_size.py --builddir=bd_speedopt_size --json-output > wallySpeedOpt_size.json 
	$(embench_dir)/benchmark_size.py --builddir=bd_sizeopt_size --json-output > wallySizeOpt_size.json 

# python wrapper to present results of embench speed benchmark
speed:
	$(embench_dir)/benchmark_speed.py --builddir=bd_sizeopt_speed --target-module run_wally --cpu-mhz=1 --json-output > wallySizeOpt_speed.json 
	$(embench_dir)/benchmark_speed.py --builddir=bd_speedopt_speed --target-module run_wally --cpu-mhz=1 --json-output > wallySpeedOpt_speed.json 

# deletes all files
clean: 
	rm -rf $(embench_dir)/bd_*_speed/
	rm -rf $(embench_dir)/bd_*_size/

allclean: clean
	rm -rf $(embench_dir)/logs/

# riscv64-unknown-elf-gcc -O2 -g -nostartfiles -I/home/harris/riscv-wally/addins/embench-iot/support -I/home/harris/riscv-wally/addins/embench-iot/config/riscv32/boards/ri5cyverilator -I/home/harris/riscv-wally/addins/embench-iot/config/riscv32/chips/generic -I/home/harris/riscv-wally/addins/embench-iot/config/riscv32 -DCPU_MHZ=1 -DWARMUP_HEAT=1 -o main.o /home/harris/riscv-wally/addins/embench-iot/support/main.c