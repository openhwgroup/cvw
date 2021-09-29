define createCheckpoint 
    # GDB config
    set pagination off
    set logging overwrite on
    set logging redirect on
    set confirm off

    # QEMU must also use TCP port 1240
    target extended-remote :1240

    # Argument Parsing
    set $statePath=$arg1
    set $ramPath=$arg1
    eval "set $statePath = \"%s/stateGDB.txt\"", $statePath
    eval "set $ramPath = \"%s/ramGDB.txt\"", $ramPath

    # Symbol file
    file ../buildroot-image-output/vmlinux

    # Step over reset vector into actual code
    stepi 1000
    # Set breakpoint for where to stop
    b do_idle
    # Proceed to checkpoint 
    printf "GDB proceeding to checkpoint at %d instrs\n", $arg0
    stepi $arg0-1000
 
    printf "Reached checkpoint at %d instrs\n", $arg0

    # Log all registers to a file
    printf "GDB storing state to %s\n", $statePath
    set logging file $statePath
    set logging on
    info all-registers
    set logging off

    # Log main memory to a file
    printf "GDB storing RAM to %s\n", $ramPath
    set logging file ../linux-testvectors/intermediate-outputs/ramGDB.txt
    set logging on
    x/134217728xb 0x80000000
    set logging off
    
    # Continue to checkpoint; stop on the 3rd time
    # Should reach login prompt by then
    printf "GDB continuing execution to login prompt\n"
    ignore 1 2
    c
    
    printf "GDB reached login prompt!\n"
    kill
    q
end
