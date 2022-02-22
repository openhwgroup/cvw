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

void output(FILE *fptr, int e1, double a, int e2, double b, int r_exp, double r_mantissa);
void printhex(FILE *fptr, double x);
double random_input(void);
double random_input_e(void);

/* Main */

void main(void)
{
  FILE *fptr;
  // e1 & e2 are exponents
  // a & b are mantissas
  // r_mantissa is result of mantissa divsion
  // r_exp is result of exponent division
  double a, b, r_mantissa, r_exp;
  int e1, e2;
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
    b = mantissa[i];
    e2 = exponent[i] + bias;
    for (j=0; j<ENTRIES; j++) {
      a = mantissa[j];
      e1 = exponent[j] + bias;
      r_mantissa = a/b;
      r_exp = e1 - e2 + bias;
      output(fptr, e1, a, e2, b, r_exp, r_mantissa);
    }
  }
  
  // for (i = 0; i< RANDOM_VECS; i++) {
  //   a = random_input();
  //   b = random_input();
  //   e1 = random_input_e() + BIAS; // make new random input function for exponents
  //   e2 = random_input_e() + BIAS;
  //   r_mantissa = a/b;
  //   r_exp = e1 - e2 + BIAS;
  //   output(fptr, e1, a, e2, b, r_exp, r_mantissa);
  // }

  fclose(fptr);
}

/* Functions */

void output(FILE *fptr, int e1, double a, int e2, double b, int r_exp, double r_mantissa)
{
  fprintf(fptr, "%03x", e1);
  //printhex(fptr, e1, exp);
  printhex(fptr, a);
  fprintf(fptr, "_");
  fprintf(fptr, "%03x", e2);
  //printhex(fptr, e2, exp);
  printhex(fptr, b);
  fprintf(fptr, "_");
  fprintf(fptr, "%03x", r_exp);
  //printhex(fptr, r_exp, exp);
  printhex(fptr, r_mantissa);
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
  
