// sqrttest.c
// David_Harris@hmc.edu 21 September 2022
// 
// Compute square roots to make test cases for fdivsqrt

#include <stdio.h>
#include <stdint.h>
#include "softfloat.h"
#include "softfloat_types.h"
typedef union sp {
  uint32_t v;
  float f;
} sp;

void printF32 (char *msg, float32_t f) {
  sp conv;
  int i, j;
  conv.v = f.v; // use union to convert between hexadecimal and floating-point views
  printf("%s: ", msg);  // print out nicely
  printf("0x%04x_%04x = %g\n", (conv.v >> 16),(conv.v & 0xFFFF), conv.f);
}

void printF32hex(float32_t f) {
  sp conv;
  int i, j;
  conv.v = f.v; // use union to convert between hexadecimal and floating-point views
  printf("%08x", conv.v);  
}

void printFlags(void) {
  int NX = softfloat_exceptionFlags % 2;
  int UF = (softfloat_exceptionFlags >> 1) % 2;
  int OF = (softfloat_exceptionFlags >> 2) % 2;
  int DZ = (softfloat_exceptionFlags >> 3) % 2;
  int NV = (softfloat_exceptionFlags >> 4) % 2;
  printf ("Flags: Inexact %d Underflow %d Overflow %d DivideZero %d Invalid %d\n", 
          NX, UF, OF, DZ, NV);
}

void printFlagsHex(void) {
  printf("%02x", softfloat_exceptionFlags);
}

void softfloatInit(void) {
    // rounding modes: RNE: softfloat_round_near_even
    //                 RZ:  softfloat_round_minMag
    //                 RP:  softfloat_round_max
    //                 RM:  softfloat_round_min
    softfloat_roundingMode = softfloat_round_near_even; 
    softfloat_exceptionFlags = 0; // clear exceptions
    softfloat_detectTininess = softfloat_tininess_afterRounding; // RISC-V behavior for tininess
}

int main()
{
    float32_t x, y, z, r;

//3F908312
//3F98F5C3

//8683F7FF_FFC00000_10

//3F908312
    x.v = 0x3F800000;
    while (x.v < 0x40000000) {
      softfloatInit(); 
      r = f32_sqrt(x);
      printF32hex(x); printf("_");
      printF32hex(r); printf("_"); printFlagsHex(); printf("\n");
      x.v += 1;
    } 
}
