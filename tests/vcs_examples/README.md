# VCS Testbench Setup
Steps to configure and run the testbench using Synopsys VCS. Follow these instructions to Synopsys VCS simulation.

## Dependencies
- Verilator (tested with Verilator 5.021 devel rev v5.020-16-g7507c5f56)
- Synopsys VCS 

## Running Simulations
```bash
cd cvw/tests/vcs_examples
cd /block_level_tests/generic  ##select specific test directory
cd flop  or cd flop_empty
```
### Verilator
To simulate with Verilator, follow these steps:
   ```bash
   make verilate
   ```
### VCS
   ```bash
   make vcs
   ```
## Cleaning Build Artifacts
To clean up all generated files and prepare for a fresh simulation, run:
```bash
make clean
```
