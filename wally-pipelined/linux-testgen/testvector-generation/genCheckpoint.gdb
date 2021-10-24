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
    set $ramPath=$arg3
    set $checkPC=$arg4
    set $checkPCoccurences=$arg5
    eval "set $statePath = \"%s/stateGDB.txt\"", $statePath
    eval "set $ramPath = \"%s/ramGDB.txt\"", $ramPath

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
    b *$checkPC
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
    eval "set logging file %s", $ramPath
    set logging on
    x/134217728xb 0x80000000
    set logging off
    
    kill
    q
end
