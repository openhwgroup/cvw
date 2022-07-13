/* testgen.c */

/* Written 2/19/2022 by David Harris

   This program creates test vectors for mantissa and exponent components
   of an IEEE floating point divider.
   Builds upon program that creates test vectors for mantissa component only.
   */

/* #includes */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

/* Constants */

#define ENTRIES  17
#define RANDOM_VECS 500
// #define BIAS 1023 // Bias is for double precision

/* Prototypes */

void output(FILE *fptr, int aSign, int aExp, double aFrac, int bSign, int bExp, double bFrac, int rSign, int rExp, double rFrac);
void printhex(FILE *fptr, double x);
double random_input(void);
double random_input_e(void);

/* Main */

void main(void)
{
  FILE *fptr;
  // aExp & bExp are exponents
  // aFrac & bFrac are mantissas
  // rFrac is result of fractional divsion
  // rExp is result of exponent division
  double aFrac, bFrac, rFrac;
  int    aExp,  bExp,  rExp;
  int    aSign, bSign, rSign;
  double mantissa[ENTRIES] = {1, 1.5, 1.25, 1.125, 1.0625,
			  1.75, 1.875, 1.99999,
			  1.1, 1.2, 1.01, 1.001, 1.0001,
			  1/1.1, 1/1.5, 1/1.25, 1/1.125};
  int exponent[ENTRIES] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17};
  int i, j;
  int bias = 1023;

  if ((fptr = fopen("testvectors","w")) == NULL) { 
    fprintf(stderr, "Couldn't write testvectors file\n");
    exit(1);
  }

  for (i=0; i<ENTRIES; i++) {
    bFrac = mantissa[i];
    bExp = exponent[i] + bias;
    bSign = i%2;
    for (j=0; j<ENTRIES; j++) {
      aFrac = mantissa[j];
      aExp = exponent[j] + bias;
      aSign = j%2;
      rFrac = aFrac/bFrac;
      rExp = aExp - bExp + bias;
      rSign = (i+j)%2;
      output(fptr, aSign, aExp, aFrac, bSign, bExp, bFrac, rSign, rExp, rFrac);
    }
  }
  
  // for (i = 0; i< RANDOM_VECS; i++) {
  //   aFrac = random_input();
  //   bFrac = random_input();
  //   aExp = random_input_e() + BIAS; // make new random input function for exponents
  //   bExp = random_input_e() + BIAS;
  //   rFrac = a/b;
  //   rEx[] = e1 - e2 + BIAS;
  //   output(fptr, aExp, aFrac, bExp, bFrac, rExp, rFrac);
  // }

  fclose(fptr);
}

/* Functions */

void output(FILE *fptr, int aSign, int aExp, double aFrac, int bSign, int bExp, double bFrac, int rSign, int rExp, double rFrac)
{
  // Print a in standard double format
  fprintf(fptr, "%03x", aExp|(aSign<<11));
  printhex(fptr, aFrac);
  fprintf(fptr, "_");

  // Print b in standard double format
  fprintf(fptr, "%03x", bExp|(bSign<<11));
  printhex(fptr, bFrac);
  fprintf(fptr, "_");

  // Print r in standard double format
  fprintf(fptr, "%03x", rExp|(rSign<<11));
  printhex(fptr, rFrac);
  fprintf(fptr, "_");

  // Spacing for testbench, value doesn't matter
  fprintf(fptr, "%016x", 0);
  fprintf(fptr, "\n");
}

void printhex(FILE *fptr, double m)
{
  int i, val, len;

    len = 52;
    while (m<1) m *= 2;
    while (m>2) m /= 2;
    for (i=0; i<len; i+=4) {
      m = m - floor(m);
      m = m * 16;
      val = (int)(m)%16;
      fprintf(fptr, "%x", val);
    }  

}    

double random_input(void)
{
  return 1.0 + rand()/32767.0;
}

double random_input_e(void)
{
  return rand() % 300 + 1;
}
  
