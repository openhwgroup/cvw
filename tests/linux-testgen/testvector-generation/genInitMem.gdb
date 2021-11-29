define genInitMem 
    # GDB config
    set pagination off
    set logging overwrite on
    set logging redirect on
    set confirm off

    # Argument Parsing
    set $tcpPort=$arg0
    set $bootmemPath=$arg1
    set $untrimmedBootmemPath=$arg1
    set $ramPath=$arg1
    eval "set $bootmemPath = \"%s/bootmemGDB.txt\"", $bootmemPath
    eval "set $untrimmedBootmemPath = \"%s/untrimmedBootmemGDB.txt\"", $untrimmedBootmemPath
    eval "set $ramPath = \"%s/ramGDB.txt\"", $ramPath

    # Connect to QEMU session
    eval "target extended-remote :%d",$tcpPort

    # QEMU Config
    maintenance packet Qqemu.PhyMemMode:1

    printf "Creating %s\n",$bootmemPath
    eval "set logging file %s", $bootmemPath
    set logging on
    x/4096xb 0x1000
    set logging off

    printf "Creating %s\n",$untrimmedBootmemPath
    printf "Warning - please verify that the second half of %s is all 0s\n",$untrimmedBootmemPath
    eval "set logging file %s", $untrimmedBootmemPath
    set logging on
    x/8192xb 0x1000
    set logging off

    printf "Creating %s\n", $ramPath
    eval "set logging file %s", $ramPath
    set logging on
    x/134217728xb 0x80000000
    set logging off
    
    kill
    q
end
