#!/bin/bash

set -e

BASEDIR=$PWD

# run the compile
echo "Start compilation"

#make -C ../../addins/coremark PORT_DIR=$BASEDIR/riscv64-baremetal compile RISCV=/courses/e190ax/riscvcompiler XCFLAGS="-march=rv64im"
#mv ../../addins/coremark/coremark.bare.riscv $BASEDIR
make -C coremark PORT_DIR=$BASEDIR/riscv64-baremetal compile RISCV=/courses/e190ax/riscvcompiler XCFLAGS="-march=rv64im"
mv coremark/coremark.bare.riscv $BASEDIR
riscv64-unknown-elf-objdump -D coremark.bare.riscv > coremark.bare.riscv.objdump #> coremarkcodemod.bare.riscv.objdump 
exe2memfile.pl coremark.bare.riscv
