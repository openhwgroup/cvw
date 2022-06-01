# Makefile added 1/20/22 David_Harris@hmc.edu
# Expanded and developed by dtorres@hmc.edu
# Compile Embench for Wally

all: build sim

allClean: clean all

build: buildspeed buildsize

buildspeed:
	../../addins/embench-iot/build_all.py --builddir=bd_speed --arch riscv32 --chip generic --board rv32wallyverilog --ldflags="-nostartfiles ../../../config/riscv32/boards/rv32wallyverilog/startup/crt0.S" --cflags="-nostartfiles" 
	find ../../addins/embench-iot/bd_speed/ -type f ! -name "*.*" | while read f; do cp "$$f" "$$f.elf"; done

buildsize:
	../../addins/embench-iot/build_all.py --builddir=bd_size --arch riscv32 --chip generic --board rv32wallyverilog --ldflags="-nostdlib -nostartfiles ../../../config/riscv32/boards/rv32wallyverilog/startup/dummy.S" --cflags="-msave-restore" --dummy-libs="libgcc libm libc crt0"

sim: modelSimBuild speed

# vsim:
# 	cd ../../pipelined/regression/
# 	vsim -c -do "do wally-pipelined-batch.do rv32gc embench"
# 	cd ../../benchmarks/embench/

modelSimBuild: buildspeed objdump
	find ../../addins/embench-iot/bd_speed/ -type f -name "*.elf" | while read f; do riscv64-unknown-elf-elf2hex --bit-width 32 --input "$$f" --output "$$f.memfile"; done
	find ../../addins/embench-iot/bd_speed/ -type f -name "*.elf.objdump" | while read f; do extractFunctionRadix.sh $$f; done

size:
	../../addins/embench-iot/benchmark_size.py --builddir=bd_size

speed:
	../../addins/embench-iot/benchmark_speed.py --builddir=bd_speed --target-module run_wally --cpu-mhz=1

objdump: buildspeed
	find ../../addins/embench-iot/bd_speed/ -type f -name "*.elf" | while read f; do riscv64-unknown-elf-objdump -S -D "$$f" > "$$f.objdump"; done

clean: 
	rm -rf ../../addins/embench-iot/bd_speed/
	rm -rf ../../addins/embench-iot/bd_size/

allclean: clean
	rm -rf ../../addins/embench-iot/logs/

# std:
# 	../../addins/embench-iot/build_all.py --builddir=bd_std --arch riscv32 --chip generic --board rv32wallyverilog --cc riscv64-unknown-elf-gcc --cflags="-v -c -O2 -ffunction-sections -march=rv32imac -mabi=ilp32" --ldflags="-Wl,-gc-sections -v -march=rv32imac -mabi=ilp32 ../../../../../benchmarks/embench/tohost.S -T../../../config/riscv32/boards/rv32wallyverilog/link.ld" --user-libs="-lm" 
# 	riscv64-unknown-elf-objdump -D ../../addins/embench-iot/bd_std/src/aha-mont64/aha-mont64 > ../../addins/embench-iot/bd_std/src/aha-mont64/aha-mont64.objdump
# --dummy-libs="libgcc libm libc"
# --cflags "-O2 -g -nostartfiles"
# ../../addins/embench-iot/build_all.py --arch riscv32 --chip generic --board rv32wallyverilog --cc riscv64-unknown-elf-gcc --cflags="-c -Os -ffunction-sections -nostdlib -march=rv32imac -mabi=ilp32" --ldflags="-Wl,-gc-sections -nostdlib -march=rv32imac -mabi=ilp32 -T../../../config/riscv32/boards/rv32wallyverilog/link.ld" --dummy-libs="libgcc libm libc"
# --user-libs="-lm" 
# riscv64-unknown-elf-gcc -O2 -g -nostartfiles -I/home/harris/riscv-wally/addins/embench-iot/support -I/home/harris/riscv-wally/addins/embench-iot/config/riscv32/boards/ri5cyverilator -I/home/harris/riscv-wally/addins/embench-iot/config/riscv32/chips/generic -I/home/harris/riscv-wally/addins/embench-iot/config/riscv32 -DCPU_MHZ=1 -DWARMUP_HEAT=1 -o main.o /home/harris/riscv-wally/addins/embench-iot/support/main.c

# find ../../addins/embench-iot/bd_speed/ -type f -name "*.elf.objdump.lab" | while read f; do grep -n "begin_signature" $f | cut -f1 -d:
