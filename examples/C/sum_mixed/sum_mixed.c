// sum_mixed.c
// David_Harris@hmc.edu 12 January 2022
// Call assembly language from C

#include <stdio.h>
#include "util.h"
extern int sum(int);

int main(void) {
    int s[1], expected[1];
    
    setStats(1);
    s[0] = sum(4);
    setStats(0);
    printf("s = %d\n", s[0]);
    expected[0] = 10;
    return verify(1, s, expected); // 0 means success
}
