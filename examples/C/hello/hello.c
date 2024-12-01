// hello.c
// David_Harris@hmc.edu 30 November 2024

// Hello World program illustrating compiled C code printing via the UART
// The Wally team has modified the Berkeley syscalls.c (in examples/C/common)
// to print via UART rather than the syscall interface.  This is supported
// on both Spike and Wally.  It assumes the PC16550-compatible UART is at 
// the default SiFive address of 0x10000000.
// Note that there seem to be some discrepancies between the UART and Spike
// such that using \n\r for new lines works best.

// compile with make
// simulate with: wsim rv64gc hello.elf --sim verilator

#include <stdio.h>  

int main(void) {
    printf("Hello Wally!\n\r");
    for (int i = 0; i < 10; i++) {
        printf("%d ", i);
    }
    printf("\n\r");
}