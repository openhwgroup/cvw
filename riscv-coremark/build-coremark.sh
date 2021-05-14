#!/bin/bash

set -e

BASEDIR=$PWD
CM_FOLDER=coremark
RISCV=/home/ehedenberg/riscvcompiler
XCFLAGS="-march=rv64im"
cd $BASEDIR/$CM_FOLDER

# run the compile
echo "Start compilation"
#make PORT_DIR=../riscv64 compile RISCV=$RISCV
#mv coremark.riscv ../

make PORT_DIR=../riscv64-baremetal compile RISCV=$RISCV XCFLAGS=$XCFLAGS
mv coremark.bare.riscv ../
