define genTrace
    # Arguments
    set $tcpPort=$arg0    
    set $vmlinux=$arg1

    # GDB config
    set pagination off
    set logging overwrite on
    set logging redirect on
    set confirm off

    # Connect to QEMU session
    eval "target extended-remote :%d",$tcpPort
    
    # Symbol Files
    eval "file %s",$vmlinux

    # Run until Linux login prompt
    b do_idle
    ignore 1 2
    c

    kill
    q
end
