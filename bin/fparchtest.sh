#!/bin/bash
#
# fparchtest.sh
# David_Harris@hmc.edu 26 December 2023
#
# Drive the riscv-isac and riscv-ctg tools to generate floating-point tests

# Set up with (not retested)
# cd ~/repos
# git clone https://github.com/riscv/riscv-ctg.git
# git clone https://github.com/riscv/riscv-isac.git
# pip3 install git+https://github.com/riscv/riscv-ctg.git
# pip3 install git+https://github.com/riscv/riscv-isac.git
# Put ~/.local/bin in $PATH to find riscv_isac and riscv_ctg

#riscv_isac --verbose debug  normalize -c $RISCVCTG/sample_cgfs/dataset.cgf -c $RISCVCTG/sample_cgfs/sample_cgfs_fext/RV32F/fadd.s.cgf -o $RISCVCTG/tests/normalizedfadd.cgf -x 32
#riscv_isac --verbose debug  normalize -c $RISCVCTG/sample_cgfs/dataset.cgf -c $RISCVCTG/sample_cgfs/sample_cgfs_fext/RV32H/fadd_b1.s.cgf -o $RISCVCTG/tests/normalizedfadd16_b1.cgf -x 32
riscv_ctg -cf $RISCVCTG/tests/normalizedfadd16_b1.cgf -d $RISCVCTG/tests --base-isa rv32i --verbose debug
#riscv_ctg -cf $RISCVCTG/sample_cgfs/dataset.cgf -cf  $RISCVCTG/sample_cgfs/rv32im.cgf -d $RISCVCTG/tests --base-isa rv32i # --verbose debug
