# riscv-wally
Configurable RISC-V Processor

Wally is a 5-stage pipelined processor configurable to support all the standard RISC-V options, incluidng RV32/64, A, C, F, D, and M extensions, FENCE.I, and the various privileged modes and CSRs.  It is written in SystemVerilog.  It passes the RISC-V Arch Tests and Imperas tests.  As of October 2021, it boots the first 10 million instructions of Buildroot Linux.

To use Wally on Linux:

git clone https://github.com/davidharrishmc/riscv-wally

cd riscv-wally

cd imperas-riscv-tests
make
cd ../addins
git clone https://github.com/riscv-non-isa/riscv-arch-test


Notes:
Eventually download imperas-riscv-tests separately
Move our custom tests to another directory
Handle exe2memfile separately.
