#!/bin/bash
tcpPort=1238
imageDir=$RISCV/buildroot/output/images
tvDir=$RISCV/linux-testvectors
recordFile="$tvDir/all.qemu"
traceFile="$tvDir/all.txt"

# Parse Commandline Arg
if [ "$#" -ne 1 ]; then
    echo "genCheckpoint requires 1 argument: <num instrs>" >&2
    exit 1
fi
instrs=$1
if ! [ "$instrs" -eq "$instrs" ] 2> /dev/null
then
    echo "Error expected integer number of instructions, got $instrs" >&2
    exit 1
fi

checkPtDir="$tvDir/checkpoint$instrs"
outTraceFile="$checkPtDir/all.txt"
interruptsFile="$checkPtDir/interrupts.txt"
rawStateFile="$checkPtDir/stateGDB.txt"
rawRamFile="$checkPtDir/ramGDB.bin"
ramFile="$checkPtDir/ram.bin"

read -p "This scripts is going to create a checkpoint at $instrs instrs.
Is that what you wanted? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Creating checkpoint at $instrs instructions!"
    if [ ! -d "$tvDir" ]; then
        echo "Error: linux testvector directory $tvDir not found!">&2
        echo "Please create it. For example:">&2
        echo "    sudo mkdir -p $tvDir">&2
        exit 1
    fi
    test -w $tvDir
    if [ ! $? -eq 0 ]; then
        echo "Error: insuffcient write privileges for linux testvector directory $tvDir !">&2
        echo "Please chmod it. For example:">&2
        echo "    sudo chmod -R a+rw $tvDir">&2
        exit 1
    fi

    # Identify instruction in trace
    instr=$(sed "${instrs}q;d" "$traceFile")
    echo "Found ${instrs}th instr: ${instr}"
    pc=$(echo $instr | cut -d " " -f1)
    asm=$(echo $instr | cut -d " " -f2)
    occurences=$(($(head -$instrs "$traceFile" | grep -c "${pc} ${asm}")-1))
    echo "It occurs ${occurences} times before the ${instrs}th instr." 

    # Create GDB script because GDB is terrible at handling arguments / variables
    ./createGenCheckpointScript.py $tcpPort $imageDir/vmlinux $instrs $rawStateFile $rawRamFile $pc $occurences
    # GDB+QEMU
    echo "Starting QEMU in replay mode with attached GDB script at $(date +%H:%M:%S)"
    (qemu-system-riscv64 \
    -M virt -dtb $imageDir/wally-virt.dtb \
    -nographic \
    -bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio \
    -singlestep -rtc clock=vm -icount shift=0,align=off,sleep=on,rr=replay,rrfile=$recordFile \
    -gdb tcp::$tcpPort -S \
    2>&1 1>./qemu-serial | ./parseQEMUtoGDB.py | ./parseGDBtoTrace.py $interruptsFile | ./remove_dup.awk > $outTraceFile) \
    & riscv64-unknown-elf-gdb --quiet -ex "source genCheckpoint.gdb"
    echo "Completed GDB script at $(date +%H:%M:%S)"

    # Post-Process GDB outputs
    ./parseState.py "$checkPtDir"
    echo "Changing Endianness at $(date +%H:%M:%S)"
    make fixBinMem
    ./fixBinMem "$rawRamFile" "$ramFile"
    echo "Copying over a truncated trace"
    tail -n+$instrs $traceFile > $outTraceFile

    echo "Checkpoint completed at $(date +%H:%M:%S)"
    echo "You may want to restrict write access to $tvDir now and give cad ownership of it."
    echo "Run the following:"
    echo "    sudo chown -R cad:cad $tvDir"
    echo "    sudo chmod -R go-w $tvDir"
fi

