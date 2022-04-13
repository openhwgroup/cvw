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
rawStateFile="$checkPtDir/stateGDB.txt"
rawUartStateFile="$checkPtDir/uartStateGDB.txt"
uartStateFile="$checkPtDir/checkpoint-UART"
rawPlicStateFile="$checkPtDir/plicStateGDB.txt"
plicStateFile="$checkPtDir/checkpoint-PLIC"
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

    mkdir -p $checkPtDir

    # Identify instruction in trace
    instr=$(sed "${instrs}q;d" "$traceFile")
    echo "Found ${instrs}th instr: ${instr}"
    pc=$(echo $instr | cut -d " " -f1)
    asm=$(echo $instr | cut -d " " -f2)
    occurences=$(($(head -$instrs "$traceFile" | grep -c "${pc} ${asm}")-1))
    echo "It occurs ${occurences} times before the ${instrs}th instr." 

    # Create GDB script because GDB is terrible at handling arguments / variables
    cat > genCheckpoint.gdb <<- end_of_script 
    set pagination off
    set logging overwrite on
    set logging redirect on
    set confirm off
    target extended-remote :$tcpPort
    maintenance packet Qqemu.PhyMemMode:1
    file $imageDir/vmlinux
    # Step over reset vector into actual code
    stepi 100
    shell echo \"GDB proceeding to checkpoint at $instrs instrs, pc $pc\"
    b *0x$pc
    ignore 1 $occurences
    c
    shell echo \"Reached checkpoint at $instrs instrs\"
    shell echo \"GDB storing CPU state to $rawStateFile\"
    set logging file $rawStateFile
    set logging on
    info all-registers
    set logging off
    shell echo \"GDB storing UART state to $rawUartStateFile\"
    # Save value of LCR
    set \$LCR=*0x10000003 & 0xff
    set logging file $rawUartStateFile
    set logging on
    # Change LCR to set DLAB=0 to be able to read RBR and IER
    set {char}0x10000003 &= ~0x80
    x/1xb 0x10000000
    x/1xb 0x10000001
    x/1xb 0x10000002
    # But log original value of LCR
    printf "0x10000003:\t0x%02x\n", \$LCR
    x/1xb 0x10000004
    x/1xb 0x10000005
    x/1xb 0x10000006
    x/1xb 0x10000007
    set logging off
    shell echo \"GDB storing PLIC state to $rawPlicStateFile\"
    shell echo \"Note: this dumping assumes a maximum of 63 PLIC sources\"
    set logging file $rawPlicStateFile
    set logging on
    # Priority Levels for sources 1 thru 63
    x/63xw 0x0C000004
    # Interrupt Enables for sources 1 thru 63 for contexts 0 and 1
    x/2xw 0x0C002000
    x/2xw 0x0C002080
    # Global Priority Threshold for contexts 0 and 1
    x/1xw 0x0C200000
    x/1xw 0x0C201000
    set logging off
    shell echo \"GDB storing RAM to $rawRamFile\"
    dump binary memory $rawRamFile 0x80000000 0x87ffffff
    kill
    q
end_of_script

    # GDB+QEMU
    echo "Starting QEMU in replay mode with attached GDB script at $(date +%H:%M:%S)"
    (qemu-system-riscv64 \
    -M virt -dtb $imageDir/wally-virt.dtb \
    -nographic \
    -bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio \
    -singlestep -rtc clock=vm -icount shift=0,align=off,sleep=on,rr=replay,rrfile=$recordFile \
    -gdb tcp::$tcpPort -S \
     1>./qemu-serial) \
    & riscv64-unknown-elf-gdb --quiet -x genCheckpoint.gdb

    echo "Completed GDB script at $(date +%H:%M:%S)"

    # Post-Process GDB outputs
    ./parseState.py "$checkPtDir"
    ./parseUartState.py "$checkPtDir"
    ./parsePlicState.py "$checkPtDir"
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

