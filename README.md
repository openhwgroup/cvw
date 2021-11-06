# riscv-wally
Configurable RISC-V Processor

Wally is a 5-stage pipelined processor configurable to support all the standard RISC-V options, incluidng RV32/64, A, C, F, D, and M extensions, FENCE.I, and the various privileged modes and CSRs.  It is written in SystemVerilog.  It passes the RISC-V Arch Tests and Imperas tests.  As of October 2021, it boots the first 10 million instructions of Buildroot Linux.

To use Wally on Linux:

```
git clone https://github.com/davidharrishmc/riscv-wally
cd riscv-wally
cd addins
*** can these clones be replaced with git submodule commands?
git clone https://github.com/riscv-non-isa/riscv-arch-test
git clone https://github.com/riscv-software-src/riscv-isa-sim
cd riscv-isa-sim
*** replace these with a copy from ../install/F and ../install/D containing the Makefile.includes already updated
cp -r arch_test_target/spike/device/rv32i_m/I arch_test_target/spike/device/rv32i_m/F
<edit arch_test_target/spike/device/rv32i_m/F/Makefile.include line 35 and change --isa=rv32i to --isa=rv32if>
cp -r arch_test_target/spike/device/rv64i_m/I arch_test_target/spike/device/rv64i_m/D
<edit arch_test_target/spike/device/rv64i_m/D/Makefile.include line 35 and change --isa=rv64i to --isa=rv64id>
mkdir build
cd build
set RISCV=/cad/riscv/gcc/bin   (or whatever your path is)
../configure --prefix=$RISCV
make (this will take a while to build SPIKE)
sudo make install
cd ../../riscv-arch-test
cp ../riscv-isa-sim/arch_test_target/spike/Makefile.include .
edit Makefile.include
  change line with TARGETDIR to /home/harris/riscv-wally/addins/riscv-isa-sim/arch_test_target (or whatever your path is) 
  add line export RISCV_PREFIX = riscv64-unknown-elf-  # this might not be needed if you have 32-bit versions of the riscv gcc compiler built separately
make
make XLEN=32
exe2memfile.pl work/*/*/*.elf  # converts ELF files to a format that can be read by Modelsim
cd ../../tests
cd imperas-riscv-tests
make
cd ../wally-riscv-arch-test
make
make XLEN=32
exe2memfile.pl work/*/*/*.elf  # converts ELF files to a format that can be read by Modelsim
cd ../../wally-pipelined/linux-testgen/linux-testvectors
./tvLinker.sh
```

Notes:
Eventually download imperas-riscv-tests separately
Move our custom tests to another directory
Eventually replace exe2memfile.pl with objcopy
