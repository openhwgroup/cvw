Synthesis for RISC-V Microprocessor System-on-Chip Design

This subdirectory contains synthesis scripts for use with Synopsys
(snps) Design Compiler (DC).  Synthesis commands are found in
scripts/synth.tcl.

Example Usage
make synth DESIGN=wallypipelinedcore FREQ=300

Libraries in .synopsys_dc.setup file
set s8lib $timing_lib/sky130_osu_sc_t12/12T_ms/lib


