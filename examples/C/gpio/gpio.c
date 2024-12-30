// gpio.c
// David_Harris@hmc.edu 30 November 2024
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

// General-Purpose I/O (GPIO) example program illustrating compiled C code
// compile with make
// simulate with: wsim rv64gc --elf gpio --sim verilator

#include <stdio.h>  
#include "gpiolib.h"

int main(void) {
    printf("GPIO Example!\n\r");
    pinMode(0, INPUT);
    pinMode(1, OUTPUT);
    pinMode(2, OUTPUT);

    for (int i=0; i<10; i++) {
        // Read pin 0 and write it to pin 1
        int val = digitalRead(0);
        printf("Pin 0: %d\n", val);
        digitalWrite(1, val);
        
        // Toggle pin 2
        printf("Pin 2: %d\n", i%2);
        digitalWrite(2, i%2);
    }
}
