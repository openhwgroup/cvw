#!/usr/bin/env bash
./build-coremark.sh

riscv64-unknown-elf-objdump -D coremark.bare.riscv > coremarkcodemod.bare.riscv.objdump 
cp coremarkcodemod.bare.riscv.objdump ~/riscv-wally/tests/imperas-riscv-tests/riscv-ovpsim-plus/examples/CoreMark/.
pushd ~/riscv-wally/tests/imperas-riscv-tests/riscv-ovpsim-plus/examples/CoreMark
./exe2memfile.pl coremarkcodemod.bare.riscv
popd
