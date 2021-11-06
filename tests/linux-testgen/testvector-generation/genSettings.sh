#!/bin/bash

# Warning! This is Tera-specific absolute path
# *** on the long term we'll want to include QEMU in the addins folder
export customQemu="/courses/e190ax/qemu_sim/rv64_initrd/qemu_experimental/qemu/build/qemu-system-riscv64"
export imageDir="../buildroot-image-output"
export outDir="../linux-testvectors"
export intermedDir="$outDir/intermediate-outputs"
export traceFile="all.txt"
export recordFile="all.qemu"
export tcpPort=1234
