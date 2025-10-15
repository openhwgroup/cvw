log_output build/log/WALLY-debug-02.log
debug_level 3
init
# Without this line it endlessly polls the processor, cluttering the
# testvectors.
poll off
halt
set pc1 [lindex [reg pc] 2]
while {$pc1 != 0x0000000080000000} {
	 set pc1 [lindex [reg pc] 2]
 	 puts "STUCK HERE!"
}
set_reg {dpc 0x80000002}
resume
#puts "Welp..."
