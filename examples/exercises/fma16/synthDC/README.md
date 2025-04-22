# Synthesis 

This subdirectory contains synthesis scripts for use with Synopsys
(snps) Design Compiler (DC).  Synthesis commands are found in
`scripts/synth.tcl`.

## Example Usage
```bash
make synth FREQ=500 
```

## Environment Variables

- `FREQ`
  - Frequency in MHz.  Default is 500
  - The target standard cell library.  The default is sky130.
- `TECH`
	- Options:
    - sky90: skywater 90nm TT 25C
    - sky130: skywater 130nm TT 25C
- `SAIFPOWER`
  - Controls if power analysis is driven by switching factor or RTL modelsim simulation. When enabled requires a saif file named power.saif.  The default is 0.
  - Options:
    - 0: switching factor power analysis
    - 1: RTL simulation driven power analysis.

