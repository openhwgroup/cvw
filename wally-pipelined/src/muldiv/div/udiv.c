#include <stdio.h>
#include <math.h>
#include <inttypes.h>

int main() {

  uint64_t N;
  uint64_t D;
  uint64_t Q;

  D = 0xdf7f3844121bcc23;
  N = 0x10fd3dedadea5195;
  N = 0xffffffffffffffff;
  D = 0x0000000000000000;
  Q = N/D;

  printf("N = %" PRIx64 "\n", N);
  printf("D = %" PRIx64 "\n", D);
  printf("Q = %" PRIx64 "\n", Q);
  printf("R = %" PRIx64 "\n", N%D);  



}
