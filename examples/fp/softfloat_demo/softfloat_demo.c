// softfloat_demo.c
// David_Harris@hmc.edu 27 February 2022
// 
// Demonstrate using SoftFloat do compute a floating-point, then print results

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

void printFlags(void) {
  int NX = softfloat_exceptionFlags % 2;
  int UF = (softfloat_exceptionFlags >> 1) % 2;
  int OF = (softfloat_exceptionFlags >> 2) % 2;
  int DZ = (softfloat_exceptionFlags >> 3) % 2;
  int NV = (softfloat_exceptionFlags >> 4) % 2;
  printf ("Flags: Inexact %d Underflow %d Overflow %d DivideZero %d Invalid %d\n", 
          NX, UF, OF, DZ, NV);
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

    x.v = 0x3fc00000;
    y.v = 0x3fc00000;
    z.v = 0x00000001;

    softfloatInit(); 
    r = f32_mulAdd(x, y, z);
    printF32("X", x); printF32("Y", y); printF32("Z", z);
    printF32("result = X*Y+Z", r); printFlags();
}
