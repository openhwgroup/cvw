#include <stdio.h>
#include <math.h>
#include <inttypes.h>

int main() {

  uint64_t N;
  uint64_t D;
  uint64_t Q;
  double val;
  uint64_t val2;

  int exponent;
  int base;

  base = 2;
  exponent = 32;
  val2 = 1;
  while (exponent != 0) {
    val2 *= base;
    exponent --;
  }
  
  val = pow(2.0, 64) - 1;
  N = 0xdf7f3844121bcc23;
  D = 0x10fd3dedadea5195;

  printf("N = %" PRIx64 "\n", N);
  printf("D = %" PRIx64 "\n", D);
  printf("Q = %" PRIx64 "\n", Q);
  printf("R = %" PRIx64 "\n", N%D);

  printf("val = %" PRIx64 "\n", val2-1);  



}
