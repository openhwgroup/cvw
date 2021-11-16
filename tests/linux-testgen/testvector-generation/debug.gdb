define debug
    # Arguments
    set $tcpPort=$arg0    

    # GDB config
    set pagination off
    set logging overwrite on
    set logging redirect on
    set confirm off

    # Connect to QEMU session
    eval "target extended-remote :%d",$tcpPort
    
    # Symbol Files
    file ../buildroot-image-output/vmlinux

    # Run until Linux login prompt
    b do_idle
    ignore 1 2
    c

    kill
    q
end
