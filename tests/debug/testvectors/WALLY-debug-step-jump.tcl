set TESTNAME WALLY-debug-step-jump
log_output build/log/$TESTNAME.log
debug_level 3
init
poll off

######################################################################
# Utility functions
######################################################################

# Utility function for scraping object dump files and grabbing label
# addresses.
proc get_address {filename label} {
    if {[catch {set fd [open $filename r]} err]} {
        error "Couldn't open $filename: $err"
    } else {
        puts "Successfully opened the file $filename"
    }

    # Iterate over every line and find the match. There should be only
    # one match.
    set regex "^(\[0-9a-fA-f\]{16})\\s+<${label}"
    while {[gets $fd line] != -1} {
        if {[regexp $regex $line match address]} {
            # Convert address to OpenOCD format (e.g., 0x80000010)
            return "0x[string range $address 0 15]"
        }
    }

    error "Label not find in $filename: $label"
}

# Reads a register and converts it's hexadecimal value into an
# integer value.
proc read_reg {register} {
    set regval [lindex [reg $register] 2]
    return [expr {$regval}]
}

proc message {STR} {
    global TESTNAME
    echo $TESTNAME:
    echo $STR
}

# --------------------------------------------------------------------
# Set up tests
# --------------------------------------------------------------------

# Grab tests
set objdump_file "build/$TESTNAME.elf.objdump"
set dosteps [get_address $objdump_file dosteps]
set test_end [get_address $objdump_file test_end]

# --------------------------------------------------------------------
# Begin tests
# --------------------------------------------------------------------

# Halt if ebreak did not halt
halt

set_reg [list dpc $dosteps]
#riscv dmi_write 0x16 0x700
#step

for {set i 0} {$i < 4} {incr i} {
    # li
    step

    # sw
    step

    # addi
    step

    # addi
    step

    # addi
    step

    # beqz
    step
}
set_reg [list dpc $test_end]
resume
