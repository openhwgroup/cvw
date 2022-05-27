# Makefile added 1/20/22 David_Harris@hmc.edu
# Compile Embench for Wally

all: build sim

allClean: clean all

build:
	../../addins/embench-iot/build_all.py --builddir=bd_speed --arch riscv32 --chip generic --board rv32wallyverilog --ldflags="-nostartfiles ../../../config/riscv32/boards/rv32wallyverilog/startup/crt0.S" --cflags="-nostartfiles" 
	find ../../addins/embench-iot/bd_speed/ -type f ! -name "*.*" | while read f; do cp "$$f" "$$f.elf"; done
	../../addins/embench-iot/build_all.py --builddir=bd_size --arch riscv32 --chip generic --board rv32wallyverilog --ldflags="-nostdlib -nostartfiles" --cflags="-msave-restore" --dummy-libs="libgcc libm libc crt0"

sim: modelSimBuild size speed

modelSimBuild: objdump
	find ../../addins/embench-iot/bd_speed/ -type f -name "*.elf" | while read f; do riscv64-unknown-elf-elf2hex --bit-width 32 --input "$$f" --output "$$f.memfile"; done
	find ../../addins/embench-iot/bd_speed/ -type f -name "*.elf.objdump" | while read f; do extractFunctionRadix.sh $$f; done

size:
	../../addins/embench-iot/benchmark_size.py --builddir=bd_size

speed:
	../../addins/embench-iot/benchmark_speed.py --builddir=bd_speed --target-module run_wally --cpu-mhz=50

objdump:
	find ../../addins/embench-iot/bd_speed/ -type f -name "*.elf" | while read f; do riscv64-unknown-elf-objdump -S "$$f" > "$$f.objdump"; done

clean: 
	rm -rf ../../addins/embench-iot/bd_speed/
	rm -rf ../../addins/embench-iot/bd_size/

# std:
# 	../../addins/embench-iot/build_all.py --builddir=bd_std --arch riscv32 --chip generic --board rv32wallyverilog --cc riscv64-unknown-elf-gcc --cflags="-v -c -O2 -ffunction-sections -march=rv32imac -mabi=ilp32" --ldflags="-Wl,-gc-sections -v -march=rv32imac -mabi=ilp32 ../../../../../benchmarks/embench/tohost.S -T../../../config/riscv32/boards/rv32wallyverilog/link.ld" --user-libs="-lm" 
# 	riscv64-unknown-elf-objdump -D ../../addins/embench-iot/bd_std/src/aha-mont64/aha-mont64 > ../../addins/embench-iot/bd_std/src/aha-mont64/aha-mont64.objdump
# --dummy-libs="libgcc libm libc"
# --cflags "-O2 -g -nostartfiles"
# ../../addins/embench-iot/build_all.py --arch riscv32 --chip generic --board rv32wallyverilog --cc riscv64-unknown-elf-gcc --cflags="-c -Os -ffunction-sections -nostdlib -march=rv32imac -mabi=ilp32" --ldflags="-Wl,-gc-sections -nostdlib -march=rv32imac -mabi=ilp32 -T../../../config/riscv32/boards/rv32wallyverilog/link.ld" --dummy-libs="libgcc libm libc"
# --user-libs="-lm" 
# riscv64-unknown-elf-gcc -O2 -g -nostartfiles -I/home/harris/riscv-wally/addins/embench-iot/support -I/home/harris/riscv-wally/addins/embench-iot/config/riscv32/boards/ri5cyverilator -I/home/harris/riscv-wally/addins/embench-iot/config/riscv32/chips/generic -I/home/harris/riscv-wally/addins/embench-iot/config/riscv32 -DCPU_MHZ=1 -DWARMUP_HEAT=1 -o main.o /home/harris/riscv-wally/addins/embench-iot/support/main.c
