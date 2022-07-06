// softfloat_calc.c
// David_Harris@hmc.edu 27 February 2022
// 
// Use SoftFloat as a calculator

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "softfloat.h"
#include "softfloat_types.h"

typedef union hp {
  uint16_t v;
  float16_t h;
} hp;

typedef union sp {
  uint32_t v;
  float32_t ft;
  float f;
} sp;

typedef union dp {
  uint64_t v;
  double d;
} dp;


int opSize = 0;

void long2binstr(unsigned long  val, char *str, int bits) {
  int i, shamt;
  unsigned long mask, masked;

  if (val == 0) { // just return zero
    str[0] = '0';
    str[1] = 0; 
  } else {
    //    printf("long2binstr %lx %s %d\n", val, str, bits);
    for (i=0; (i<bits) && (val != 0); i++) {
      shamt = bits - i - 1;
      mask = 1;
      mask = (mask << shamt); 
      masked = val & ~mask; // mask off the bit
      if (masked != val) str[i] = '1';
      else str[i] = '0';
      //      printf("  Considering %016lx mask %016lx (%d) masked %016lx str[%d] %c\n", val, mask, shamt, masked, i, str[i]);
      val = masked;
      if (!val) str[i+1] = 0; // terminate when out of nonzero digits
    }
  } 
}

void printF16(char *msg, float16_t f) {
  hp convh;
  sp convf;
  long exp, fract;
  char sign;
  char sci[300], fractstr[200];
  float32_t temp;

  convh.v = f.v; // use union to convert between hexadecimal and floating-point views
  temp = f16_to_f32(convh.h);
  convf.ft = temp;

  fract = f.v & ((1<<10) - 1); long2binstr(fract, fractstr, 10);
  exp = (f.v >> 10) & ((1<<5) -1);
  sign = f.v >> 15 ? '-' : '+';
  //printf("%c %d %d  ", sign, exp, fract);
  if (exp == 0 && fract == 0) sprintf(sci, "%czero", sign);
  else if (exp == 0 && fract != 0) sprintf(sci, "Denorm: %c0.%s x 2^-14", sign, fractstr);
  else if (exp == 31 && fract == 0) sprintf(sci, "%cinf", sign);
  else if (exp == 31 && fract != 0) sprintf(sci, "NaN Payload: %c%s", sign, fractstr);
  else sprintf(sci, "%c1.%s x 2^%ld", sign, fractstr, exp-15);

  printf ("%s: 0x%04x = %g = %s: Biased Exp %ld Fract 0x%lx\n", 
    msg, convh.v, convf.f, sci, exp, fract);  // no easy way to print half prec.
}

void printF32(char *msg, float32_t f) {
  sp conv;
  long exp, fract;
  char sign;
  char sci[200], fractstr[200];

  conv.v = f.v; // use union to convert between hexadecimal and floating-point views

  fract = f.v & ((1<<23) - 1); long2binstr(fract, fractstr, 23);
  exp = (f.v >> 23) & ((1<<8) -1);
  sign = f.v >> 31 ? '-' : '+';
  //printf("%c %d %d  ", sign, exp, fract);
  if (exp == 0 && fract == 0) sprintf(sci, "%czero", sign);
  else if (exp == 0 && fract != 0) sprintf(sci, "Denorm: %c0.%s x 2^-126", sign, fractstr);
  else if (exp == 255 && fract == 0) sprintf(sci, "%cinf", sign);
  else if (exp == 255 && fract != 0) sprintf(sci, "NaN Payload: %c%s", sign, fractstr);
  else sprintf(sci, "%c1.%s x 2^%ld", sign, fractstr, exp-127);

  //printf ("%s: 0x%08x = %g\n", msg, conv.v, conv.f);
  printf("%s: ", msg);
  printf("0x%04x", (conv.v >> 16));
  printf("_");
  printf("%04x", (conv.v & 0xFF));
  printf(" = %g = %s: Biased Exp %ld Fract 0x%lx\n", conv.f, sci, exp, fract);
  //printf ("%s: 0x%08x = %g = %s: Biased Exp %d Fract 0x%lx\n", 
  //  msg, conv.v, conv.f, sci, exp, fract);  
}

void printF64(char *msg, float64_t f) {
  dp conv;
  long exp, fract;
  long mask;
  char sign;
  char sci[200], fractstr[200];

  conv.v = f.v; // use union to convert between hexadecimal and floating-point views

  mask = 1; mask = (mask << 52) - 1;
  fract = f.v & mask; long2binstr(fract, fractstr, 52);
  exp = (f.v >> 52) & ((1<<11) -1);
  sign = f.v >> 63 ? '-' : '+';
  //printf("%c %d %d  ", sign, exp, fract);
  if (exp == 0 && fract == 0) sprintf(sci, "%czero", sign);
  else if (exp == 0 && fract != 0) sprintf(sci, "Denorm: %c0.%s x 2^-1022", sign, fractstr);
  else if (exp == 2047 && fract == 0) sprintf(sci, "%cinf", sign);
  else if (exp == 2047 && fract != 0) sprintf(sci, "NaN Payload: %c%s", sign, fractstr);
  else sprintf(sci, "%c1.%s x 2^%ld", sign, fractstr, exp-1023);

  //printf ("%s: 0x%016lx = %lg\n", msg, conv.v, conv.d);
  printf("%s: ", msg);
  printf("0x%04lx", (conv.v >> 48));
  printf("_");
  printf("%04lx", (conv.v >> 32) & 0xFFFF);
  printf("_");
  printf("%04lx", (conv.v >> 16) & 0xFFFF);
  printf("_");  
  printf("%04lx", (conv.v & 0xFFFF));
  printf(" = %lg = %s: Biased Exp %ld Fract 0x%lx\n", conv.d, sci, exp, fract);
  //printf ("%s: 0x%016lx = %lg = %s: Biased Exp %d Fract 0x%lx\n", 
  //  msg, conv.v, conv.d, sci, exp, fract); 
}

void printFlags(void) {
  int NX = softfloat_exceptionFlags % 2;
  int UF = (softfloat_exceptionFlags >> 1) % 2;
  int OF = (softfloat_exceptionFlags >> 2) % 2;
  int DZ = (softfloat_exceptionFlags >> 3) % 2;
  int NV = (softfloat_exceptionFlags >> 4) % 2;
  printf ("exceptions: Inexact %d Underflow %d Overflow %d DivideZero %d Invalid %d\n", 
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

uint64_t parseNum(char *num) {
  uint64_t result;
  int size; // size of operands in bytes (2= half, 4=single, 8 = double)
  if (strlen(num) < 8) size = 2;
  else if (strlen(num) < 16) size = 4;
  else if (strlen(num) < 19) size = 8;
  else {
    printf("Error: only half, single, and double precision supported");
    exit(1);
  }
  if (opSize != 0) {
    if (size != opSize) {
      printf("Error: inconsistent operand sizes %d and %d\n", size, opSize);
      exit(1);
    } 
  } else {
    opSize = size;
    //printf ("Operand size is %d\n", opSize);
  }
  result = (uint64_t)strtoul(num, NULL, 16);
  //printf("Parsed %s as 0x%lx\n", num, result);
  return result;
}

char parseOp(char *op) {
  if (strlen(op) > 1) {
    printf ("Bad op %s must be 1 character\n", op);
    exit(1);
  } else {
    return op[0];
  }
}

char parseRound(char *rnd) {
  if      (strcmp(rnd, "RNE") == 0) return softfloat_round_near_even;
  else if (strcmp(rnd, "RZ") == 0)  return softfloat_round_minMag;
  else if (strcmp(rnd, "RP") == 0)  return softfloat_round_max;
  else if (strcmp(rnd, "RM") == 0)  return softfloat_round_min;
  else {
    printf("Rounding mode of %s is not known\n", rnd);
    exit(1);
  }
}

int main(int argc, char *argv[])
{
    uint64_t xn, yn, zn;
    char op1, op2;
    char cmd[200];

    softfloatInit(); 

    if (argc < 4 || argc > 7) {
      printf("Usage: %s x op y [RNE/RZ/RM/RP]  or  x x y + z [RNE/RZ/RM/RP]\n  Example: 0x3f800000 + 0x3fC00000\n  Use x for multiplication\n", argv[0]);
      exit(1);
    } else {
      softfloat_roundingMode = softfloat_round_near_even;
      xn = parseNum(argv[1]);
      yn = parseNum(argv[3]);
      op1 = parseOp(argv[2]);
      if (argc == 5) softfloat_roundingMode = parseRound(argv[4]);
      if (argc >= 6) {
        zn = parseNum(argv[5]);
        op2 = parseOp(argv[4]);
        if (argc == 7) softfloat_roundingMode = parseRound(argv[6]);
        if (op1 != 'x' || op2 != '+') {
          printf("Error: only x * y + z supported for 3-input operations, not %c %c\n", op1, op2);
        }
        else {
          if (opSize == 2) {
            float16_t x, y, z, r;
            x.v = xn; y.v = yn; z.v = zn;
            r = f16_mulAdd(x, y, z);
            printF16("X", x); printF16("Y", y); printF16("Z", z);
            printF16("result = X*Y+Z", r); printFlags();
          } else if (opSize == 4) {
            float32_t x, y, z, r;
            x.v = xn; y.v = yn; z.v = zn;
            r = f32_mulAdd(x, y, z);
            printF32("X", x); printF32("Y", y); printF32("Z", z);
            printF32("result = X*Y+Z", r); printFlags();
          } else { // opSize = 8
            float64_t x, y, z, r;
            x.v = xn; y.v = yn; z.v = zn;
            r = f64_mulAdd(x, y, z);
            printF64("X", x); printF64("Y", y); printF64("Z", z);
            printF64("result = X*Y+Z", r); printFlags();
          }
        }
      } else {
        if (opSize == 2) {
          float16_t x, y, r;
          x.v = xn; y.v = yn;
          switch (op1) {
            case 'x': r = f16_mul(x, y); break;
            case '+': r = f16_add(x, y); break;
            case '-': r = f16_sub(x, y); break;
            case '/': r = f16_div(x, y); break;
            case '%': r = f16_rem(x, y); break;
            default: printf("Unknown op %c\n", op1); exit(1);
          }
          printF16("X", x); printF16("Y", y); 
          sprintf(cmd, "0x%04x %c 0x%04x", x.v, op1, y.v);
          printF16(cmd, r); printFlags();
        } else if (opSize == 4) {
          float32_t x, y, r;
          x.v = xn; y.v = yn;
          switch (op1) {
            case 'x': r = f32_mul(x, y); break;
            case '+': r = f32_add(x, y); break;
            case '-': r = f32_sub(x, y); break;
            case '/': r = f32_div(x, y); break;
            case '%': r = f32_rem(x, y); break;
            default: printf("Unknown op %c\n", op1); exit(1);
          }
          printF32("X", x); printF32("Y", y); 
          sprintf(cmd, "0x%08x %c 0x%08x", x.v, op1, y.v);
          printF32(cmd, r); printFlags();

        } else { // opSize = 8
          float64_t x, y, r;
          x.v = xn; y.v = yn;
          switch (op1) {
            case 'x': r = f64_mul(x, y); break;
            case '+': r = f64_add(x, y); break;
            case '-': r = f64_sub(x, y); break;
            case '/': r = f64_div(x, y); break;
            case '%': r = f64_rem(x, y); break;
            default: printf("Unknown op %c\n", op1); exit(1);
          }
          printF64("X", x); printF64("Y", y); 
          sprintf(cmd, "0x%016lx %c 0x%016lx", x.v, op1, y.v);
          printF64(cmd, r); printFlags();

        }
      }
    }
}
