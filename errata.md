# Textbook Errata

This document contains errata for [RISC-V System-on-Chip Design](https://www.amazon.com/RISC-V-Microprocessor-System-Chip-Design/dp/0323994989) published by Elsevier.

Please contribute by making a pull request to modify this document on GitHub.  Sort the errata by page number. Keep the correction as succinct as possible.

| Page | Location | Error | Correction  | Contributor | Date |
| ---- | -------- | ----- | ----------- | ----------- | ----|
| 31 | Ch. 2 opening paragraph | "RISC processor sign" | Replace with "RISC processor design". | Sotaro Fujimoto, Japan | 6/17/26 |
| 33 | Table 2.1 | The source register counts for J-type and U-type instructions are listed as 1. | Change both counts to 0. | Sotaro Fujimoto, Japan | 6/22/26 |
| 46 | 2.3.1 | "The trap handler and system call validates the parameters ..." | Replace with "The trap handler for the system call validates the parameters ...". | Sotaro Fujimoto, Japan | 6/22/26 |
| 133 | 3.7 | The ACT suite has been completely redesigned and no longer uses RISCOF.  |See the [riscv-arch-test](https://github.com/riscv-non-isa/riscv-arch-test) repository for updated information.|David Harris, Claremont, CA | 1/4/26 |
| 226 | 5.9.2 | cvw-arch-verif has been deprecated and no longer is in use | Replace with riscv-arch-test | David Harris, Claremont, CA | 1/4/26 |
| 227 | 5.11 | The ACT suite has been completely redesigned and no longer uses RISCOF.  *** Other big changes pending in this section. | n/a | David Harris, Claremont, CA | 1/4/26 |
| 367 | 8.4.1 | "Uses the CSRs (xtvect)" | Replace "xtvect" with "xtvec". | Sotaro Fujimoto, Japan | 6/19/26 |
| 885   | 23.2.2.4-5 | The ramspeed benchmark is no longer supported and has been removed from the Buildroot Linux image. | n/a | David Harris, Claremont, CA | 1/4/26 |
