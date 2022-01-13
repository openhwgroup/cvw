// inline.c
// David_Harris@hmc.edu 12 January 2022
// Illustrates inline assembly language

#include <stdio.h>

int main(void) {
    long cycles;
    asm volatile("csrr %0, 0xB00" : "=r"(cycles)); // read mcycle register
    printf ("mcycle = %ld\n", cycles);
}
