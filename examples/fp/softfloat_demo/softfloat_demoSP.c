// softfloat_demo3.c
// james.stine@okstate.edu 15 August 2023
// 
// Demonstrate using SoftFloat do compute a floating-point for quad, then print results

#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <quadmath.h> // GCC Quad-Math Library
#include "softfloat.h"
#include "softfloat_types.h"
typedef union sp {
  uint32_t v;
  float f;
} sp;

typedef union dp {
  uint64_t v;
  double d;
} dp;

typedef union qp {
  uint64_t v[2];
  __float128 q;
} qp;


void printF32 (char *msg, float32_t f) {
  sp conv;
  int i, j;
  conv.v = f.v; // use union to convert between hexadecimal and floating-point views
  printf("%s: ", msg);  // print out nicely
  printf("0x%04x_%04x = %g\n", (conv.v >> 16),(conv.v & 0xFFFF), conv.f);
}

void printF64 (char *msg, float64_t d) {
  dp conv;
  int i, j;
  conv.v = d.v; // use union to convert between hexadecimal and floating-point views
  printf("%s: ", msg);  // print out nicely
  printf("0x%08lx_%08lx = %g\n", (conv.v >> 32),(conv.v & 0xFFFFFFFF), conv.d);
}

void printF128 (char *msg, float128_t q) {
  qp conv;
  int i, j;
  char buf[64];
  conv.v[0] = q.v[0]; // use union to convert between hexadecimal and floating-point views
  conv.v[1] = q.v[1]; // use union to convert between hexadecimal and floating-point views  
  printf("%s: ", msg);  // print out nicely
  //printf("0x%016" PRIx64 "_%016" PRIx64 " = %1.15Qe\n", q.v[1], q.v[0], conv.q);
  quadmath_snprintf (buf, sizeof buf, "%1.15Qe", conv.q);
  printf("0x%016" PRIx64 "_%016" PRIx64 " = %s\n", q.v[1], q.v[0], buf);    
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

int main() {
  
  float32_t x, y, z;
  float32_t r;

  x.v = 0xBFFF988E;
  y.v = 0x3F8EFFFF;
  z.v = 0x40010000;

  softfloatInit();
  printF32("X", x); printF32("Y", y); printF32("Z", z);
  r = f32_mulAdd(x, y, z);
  printf("\n");
  printF32("r", r);
  
}
