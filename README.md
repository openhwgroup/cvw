# riscv-wally
Configurable RISC-V Processor

Wally is a 5-stage pipelined processor configurable to support all the standard RISC-V options, incluidng RV32/64, A, C, F, D, and M extensions, FENCE.I, and the various privileged modes and CSRs.  It is written in SystemVerilog.  It passes the RISC-V Arch Tests and Imperas tests.  As of October 2021, it boots the first 10 million instructions of Buildroot Linux.

To use Wally on Linux:

```
git clone https://github.com/davidharrishmc/riscv-wally
cd riscv-wally
cd imperas-riscv-tests
make
cd ../addins
git clone https://github.com/riscv-non-isa/riscv-arch-test
git clone https://github.com/riscv-software-src/riscv-isa-sim
cd riscv-isa-sim
mkdir build
cd build
set RISCV=/cad/riscv/gcc/bin   (or whatever your path is)
../configure --prefix=$RISCV
make (this will take a while to build SPIKE)
sudo make install
cd ../../riscv-arch-test
cp ../riscv-isa-sim/arch_test_target/spike/Makefile.include .
edit Makefile.include
  change line with TARGETDIR to /home/harris/test/riscv-wally/addins/riscv-isa-sim/arch_test_target (or whatever your path is) ***fix
  add line export RISCV_PREFIX = riscv64-unknown-elf-  # this might not be needed if you have 32-bit versions of the riscv gcc compiler built separately
make
make XLEN=32
```

Notes:
Eventually download imperas-riscv-tests separately
Move our custom tests to another directory
Handle exe2memfile separately.
