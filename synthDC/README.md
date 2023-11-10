Synthesis for RISC-V Microprocessor System-on-Chip Design

This subdirectory contains synthesis scripts for use with Synopsys
(snps) Design Compiler (DC).  Synthesis commands are found in
scripts/synth.tcl.

Example Usage
make synth DESIGN=wallypipelinedcore FREQ=500

environment variables

DESIGN
        Design provides the name of the output log.  Default is synth.

FREQ
        Frequency in MHz.  Default is 500

CONFIG
        The Wally configuration file.  The default is rv32e.
        Examples: rv32e, rv64gc, rv32gc

TECH
        The target standard cell library.  The default is sky130.
        sky90: skywater 90nm TT 25C
        sky130: skywater 130nm TT 25C

SAIFPOWER
        Controls if power analysis is driven by switching factor or
	RTL modelsim simulation. When enabled requires a saif file
	named power.saif.  The default is 0.
        0: switching factor power analysis
        1: RTL simulation driven power analysis.

-----
Extra Tool (PPA)

To run ppa analysis that hones into target frequency, you can type:
python3 ppa/ppaSynth.py from the synthDC directory.  This runs a sweep
across all modules listed at the bottom of the ppaSynth.py file.



