#!/usr/bin/env python3

# Self compiling python -> SVF script
# When you execute this program, openocd_tcl_wrapper.SVF_Generator should generate a basic SVF file
# The output file will have the same path as this file with a ".svf" extension

# To make a new test, copy this file and write new test logic in main() below "### Write test program here ###"
# For available functions calls, see SVF_Generator in openocd_tcl_wrapper


# Hacky way to add $wally/bin to path so we can import openocd_tcl_wrapper from $wally/tests
import sys
import os
sys.path.insert(0, os.path.abspath("bin"))
sys.path.insert(0, os.path.abspath("../../../bin"))
from openocd_tcl_wrapper import SVF_Generator

def main():
    with SVF_Generator(writeout=True) as svf:
        ### Write test program here ###
        svf.comment("Check jtag id")
        svf.check_jtag_id(0x1002AC05)
        svf.comment("Activating DM")
        svf.activate_dm()
        svf.comment("Read DMStatus, compare bottom 8 bits to 0xa3")
        svf.read_dmi(0x11, 0xa3, mask=0xff)
        svf.comment("Reset hart")
        svf.reset_hart()
        svf.comment("Write 0x99, 0x88 to program buffer")
        svf.write_progbuf([0x99, 0x88])
        svf.comment("Execute Program Buffer")
        svf.exec_progbuf()



if __name__ == "__main__":
    main()
