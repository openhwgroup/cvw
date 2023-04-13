//
// softfloat_div.c
// james.stine@okstate.edu 12 April 2023
// 
// Demonstrate using SoftFloat to compute 754 fp divide, then print results
// (adapted from original C built by David Harris)
//

#include <stdio.h>
#include <stdint.h>
#include "softfloat.h"
#include "softfloat_types.h"
typedef union sp {
  uint32_t v;
  unsigned short x[2];
  float f;
} sp;

void printF32 (char *msg, float32_t f) {
  sp conv;
  int i, j;
  conv.v = f.v; // use union to convert between hexadecimal and floating-point views
  printf("%s: ", msg);  // print out nicely
  printf("0x%04x_%04x = %1.15g\n", (conv.v >> 16),(conv.v & 0xFFFF), conv.f);
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
    // RNE: softfloat_round_near_even
    // RZ:  softfloat_round_minMag
    // RU:  softfloat_round_max
    // RD:  softfloat_round_min
    // RM: softfloat_round_near_maxMag   
    softfloat_roundingMode = softfloat_round_near_even; 
    softfloat_exceptionFlags = 0; // clear exceptions
    softfloat_detectTininess = softfloat_tininess_afterRounding; // RISC-V behavior for tininess
}

int main() {

  // float32_t is typedef in SoftFloat
  float32_t x, y, r1, r2;
  sp convx, convy;

  // Choose two random values
  convx.f = 1.30308703073;
  convy.f = 1.903038030370;
  // Convert to SoftFloat format
  x.v = (convx.x[1] << 16) + convx.x[0];
  y.v = (convy.x[1] << 16) + convy.x[0];  

  printf("Example using SoftFloat\n");
  
  softfloatInit();
  r1 = f32_div(x, y);
  printf("-------\n");
  printF32("X", x);
  printF32("Y", y); 
  printF32("result = X/Y", r1);
  printFlags();

  r2 = f32_sqrt(x);
  printf("-------\n");    
  printF32("X", x);
  printF32("result = sqrt(X)", r2);
  printFlags();  

}
