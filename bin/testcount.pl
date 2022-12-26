#!/bin/bash
# testcount.pl
# David_Harris@hmc.edu 25 December 2022
# Read the riscv-test-suite directories from riscv-arch-test
# and count how many tests are in each

for dir in `ls ${WALLY}/addins/riscv-arch-test/riscv-test-suite/rv*/*`
do
    dir=$(echo $dir | cut -d':' -f1)
    echo $dir
    for fn in `ls $dir/src/*.S`
    do
        result=`grep 'inst_' $fn | tail -n 1`
        num=$(echo $result| cut -d'_' -f 2 | cut -d':' -f 1)
        ((num++))
        fnbase=`basename $fn`
        echo "$fnbase: $num"
    done
done
