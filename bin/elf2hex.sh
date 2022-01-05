#!/bin/sh

# james.stine@okstate.edu 4 Jan 2022
# Script to run elf2hex for memfile for
# Imperas and riscv-arch-test benchmarks

for file in work/rv64i_m/*/*.elf ; do
    memfile=${file%.elf}.elf.memfile
    echo riscv64-unknown-elf-elf2hex --bit-width 64 --input "$file" 
    riscv64-unknown-elf-elf2hex --bit-width 64 --input "$file" --output "$memfile"
done

for file in work/rv32i_m/*/*.elf ; do
    memfile=${file%.elf}.elf.memfile
    echo riscv64-unknown-elf-elf2hex --bit-width 32 --input "$file"
    riscv64-unknown-elf-elf2hex --bit-width 32 --input "$file" --output "$memfile"
done
