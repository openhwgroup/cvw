Coremark EEMBC Wrapper
======================

This repository provides the utility files to port [CoreMark EEMBC](https://www.eembc.org/coremark/) to RISC-V.

### Requirements

  - You must have installed the RISC-V tools

### Setup

  - `git submodule update --init`
  - Run the `./build-coremark.sh` script that does the following
    - Builds a version of Coremark for Linux or pk (coremark.riscv)
    - Builds a version of Coremark for bare-metal (coremark.bare.riscv)
    - Copies the output binaries into this directory

### Default Files

The default files target **RV64GC** and use minimal amount of compilation flags. Additionally, the `*.mak` file in the `riscv64`
folder setups `spike pk` as the default `run` rule.

Feel free to change these to suit your needs.
