# Makefile added 1/20/22 David_Harris@hmc.edu
# Compile Embench for Wally

all: Makefile
	../../addins/embench-iot/build_all.py --arch riscv32 --chip generic --board ri5cyverilator --cflags "-O2 -march=rv32i -mabi=ilp32 -mcmodel=medany" --cc riscv64-unknown-elf-gcc 
	./benchmark_size.py 
	./benchmark_speed.py

# view with
# more `ls -t | head -1`

# --cflags "-O2 -g -nostartfiles"


#riscv64-unknown-elf-gcc -O2 -g -nostartfiles -I/home/harris/riscv-wally/addins/embench-iot/support -I/home/harris/riscv-wally/addins/embench-iot/config/riscv32/boards/ri5cyverilator -I/home/harris/riscv-wally/addins/embench-iot/config/riscv32/chips/generic -I/home/harris/riscv-wally/addins/embench-iot/config/riscv32 -DCPU_MHZ=1 -DWARMUP_HEAT=1 -o main.o /home/harris/riscv-wally/addins/embench-iot/support/main.c
