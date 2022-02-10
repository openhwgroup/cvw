Synthesis for RISC-V Microprocessor System-on-Chip Design

This subdirectory contains synthesis scripts for use with Synopsys
(snps) Design Compiler (DC).  Synthesis commands are found in
scripts/synth.tcl.

Example Usage
make synth DESIGN=wallypipelinedcore FREQ=300

environment variables

DESIGN
        Design provides the name of the output log.  Default is synth.

FREQ
        Frequency in Mhz.  Default is 500

CONFIG
        The wally configuration file.  Default is rv32e.
        Examples.
        rv32e
        rv64gc
        rv32gc

TECH
        The target standard cell library.  Default is 130.
        90: skywater 90nm tt 25C.
        130: skywater 130nm tt 25C.

SAIFPOWER
        Controls if power analysis is driven by switching factor or RTL modelsim simulation.
        When enabled requires a saif file named power.saif.
        Default is 0.
        0: switching factor power analysis
        1: RTL simulation driven power analysis.

Libraries in .synopsys_dc.setup file
set s8lib $timing_lib/sky130_osu_sc_t12/12T_ms/lib


