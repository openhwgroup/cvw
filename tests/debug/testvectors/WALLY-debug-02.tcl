log_output build/log/WALLY-debug-02.log
debug_level 3
init
# Without this line it endlessly polls the processor, cluttering the
# testvectors.
poll off
halt
# Registers x1-x31
reg ra
reg sp
reg gp
reg tp
reg t0
reg t1
reg t2
reg fp
reg s1
reg a0
reg a1
reg a2
reg a3
reg a4
reg a5
reg a6
reg a7
reg s2
reg s3
reg s4
reg s5
reg s6
reg s7
reg s8
reg s9
reg s10
reg s11
reg t3
reg t4
reg t5
reg t6
puts [reg pc]
set pc1 [lindex [reg pc] 2]
while {$pc1 != 0x00000000800001a4} {
	 puts [reg pc]
	 set pc1 [lindex [reg pc] 2]
 	 puts "STUCK HERE: $pc1"
}
set_reg {dpc 0x800001a6}
resume
#puts "Welp..."
