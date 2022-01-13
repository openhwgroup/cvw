// sum.c
// David_Harris@hmc.edu 24 December 2021
// Simple illustration of compiling C code

#include <stdio.h>  // supports printf
#include "util.h"   // supports verify

long sum(long N) {
  long result, i;
   result = 0;
   for (i=1; i<=N; i++) {
       result = result + i;
   }
   return result;
}

int main(void) {
    int s[1], expected[1];
    setStats(1);
    s[0] = sum(4);
    setStats(0);
    printf("s = %d\n", s[0]);
    expected[0] = 10;
    return verify(1, s, expected); // 0 means success
}