define genCheckpoint
    # GDB config
    set pagination off
    set logging overwrite on
    set logging redirect on
    set confirm off

    # Argument Parsing
    set $tcpPort=$arg0
    set $instrCount=$arg1
    set $statePath=$arg2
    set $ramPath=$arg2
    set $checkPC=$arg3
    set $checkPCoccurences=$arg4
    eval "set $statePath = \"%s/stateGDB.txt\"", $statePath
    eval "set $ramPath = \"%s/ramGDB.bin\"", $ramPath

    # Connect to QEMU session
    eval "target extended-remote :%d",$tcpPort

    # QEMU Config
    maintenance packet Qqemu.PhyMemMode:1

    # Symbol file
    file ../buildroot-image-output/vmlinux

    # Step over reset vector into actual code
    stepi 100
    # Set breakpoint for where to stop
    b do_idle
    # Proceed to checkpoint 
    printf "GDB proceeding to checkpoint at %d instrs\n", $instrCount
    #stepi $instrCount-1000
    eval "b *0x%s",$checkPC
    ignore 2 $checkPCoccurences
    c
 
    printf "Reached checkpoint at %d instrs\n", $instrCount

    # Log all registers to a file
    printf "GDB storing state to %s\n", $statePath
    eval "set logging file %s", $statePath
    set logging on
    info all-registers
    set logging off

    # Log main memory to a file
    printf "GDB storing RAM to %s\n", $ramPath
    eval "dump binary memory %s 0x80000000 0xffffffff", $ramPath
    
    kill
    q
end
