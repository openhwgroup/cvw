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

    # Create Output Directory
    echo "Elevating permissions to create $checkPtDir and stuff inside it"
    sudo mkdir -p $checkPtDir
    sudo chown -R cad:users $checkPtDir
    sudo chmod -R a+rw $checkPtDir
    sudo touch $outTraceFile
    sudo chmod a+rw $outTraceFile
    sudo touch $interruptsFile
    sudo chmod a+rw $interruptsFile
    sudo touch $rawStateFile
    sudo chmod a+rw $rawStateFile
    sudo touch $rawRamFile
    sudo chmod a+rw $rawRamFile
    sudo touch $ramFile
    sudo chmod a+rw $ramFile
    
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
    2>&1 1>./qemu-serial | ./parseQEMUtoGDB/parseQEMUtoGDB_run.py | ./parseGDBtoTrace/parseGDBtoTrace_run.py $interruptsFile | ./remove_dup.awk > $outTraceFile) \
    & riscv64-unknown-elf-gdb --quiet -ex "source genCheckpoint.gdb"
    echo "Completed GDB script at $(date +%H:%M:%S)"

    # Post-Process GDB outputs
    ./parseState.py "$checkPtDir"
    echo "Changing Endianness at $(date +%H:%M:%S)"
    make fixBinMem
    ./fixBinMem "$rawRamFile" "$ramFile"
    echo "Copying over a truncated trace"
    tail -n+$instrs $traceFile > $outTraceFile
    read -p "Checkpoint completed at $(date +%H:%M:%S)" -n 1 -r

    # Cleanup
    echo "Elevating permissions to restrict write access to $checkPtDir"
    sudo chown -R cad:users $checkPtDir
    sudo chmod -R go-w $checkPtDir
fi

