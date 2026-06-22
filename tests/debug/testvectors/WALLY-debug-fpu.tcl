log_output build/log/WALLY-debug-fpu.log
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

# --------------------------------------------------------------------
# Set up tests
# --------------------------------------------------------------------

# Grab tests
set objdump_file "build/WALLY-debug-fpu.elf.objdump"
set resume_addr0 [get_address $objdump_file resume_addr]

# --------------------------------------------------------------------
# Begin tests
# --------------------------------------------------------------------

for {set i 4} {$i > 0} {incr i -1} {
    halt
    set_reg [list dpc $resume_addr0]
    reg ft1
    resume
}
