/* sqrttestgen.c */

/* Written 19 October 2021 David_Harris@hmc.edu

   This program creates test vectors for mantissa component
   of an IEEE floating point square root. 
   */

/* #includes */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

/* Constants */

#define ENTRIES  17
#define RANDOM_VECS 500

/* Prototypes */

void output(FILE *fptr, int aExp, double aFrac, int rExp, double rFrac);
void printhex(FILE *fptr, double x);
double random_input(void);

/* Main */

void main(void)
{
  FILE *fptr;
  double aFrac, rFrac;
  int    aExp,  rExp;
  double mans[ENTRIES] = {1, 1849.0/1024, 1.25, 1.125, 1.0625,
			  1.75, 1.875, 1.99999,
			  1.1, 1.2, 1.01, 1.001, 1.0001,
			  2/1.1, 2/1.5, 2/1.25, 2/1.125};
  double exps[ENTRIES] = {0, 0, 2, 3, 4, 5, 6, 7, 8, 9, 10,
        11, 12, 13, 14, 15, 16};
  int i;
  int bias = 1023;

  if ((fptr = fopen("sqrttestvectors","w")) == NULL) {
    fprintf(stderr, "Couldn't write sqrttestvectors file\n");
    exit(1);
  }

  for (i=0; i<ENTRIES; i++) {
    aFrac = mans[i];
    aExp  = exps[i] + bias;
    rFrac = sqrt(aFrac * pow(2, exps[i]));
    rExp  = (int) (log(rFrac)/log(2) + bias);
    output(fptr, aExp, aFrac, rExp, rFrac);
  }

  //                                  WS
  // Test 1: sqrt(1) = 1              0000 0000 0000 00
  // Test 2: sqrt(1849/1024) = 43/32  0000 1100 1110 01
  // Test 3: sqrt(5)                  0000 0100 0000 00
  // Test 4: sqrt(9) = 3              1111 1001 0000 00
  // Test 5: sqrt(17)                 0000 0001 0000 00
  // Test 6: sqrt(56)                 1111 1110 0000 00
  // Test 7: sqrt(120)                0000 1110 0000 00
  
  // for (i = 0; i< RANDOM_VECS; i++) {
  //   a = random_input();
  //   r = sqrt(a);
  //   output(fptr, a, r);
  // }

  fclose(fptr);
}

/* Functions */

void output(FILE *fptr, int aExp, double aFrac, int rExp, double rFrac)
{
  // Print a in standard double format
  fprintf(fptr, "%03x", aExp);
  printhex(fptr, aFrac);
  fprintf(fptr, "_");

  // Spacing for testbench, value doesn't matter
  fprintf(fptr, "%016x", 0);
  fprintf(fptr, "_");

  // Print r in standard double format
  fprintf(fptr, "%03x", rExp);
  printhex(fptr, rFrac);
  fprintf(fptr, "_");

  // Spacing for testbench, value doesn't matter
  fprintf(fptr, "%016x", 0);
  fprintf(fptr, "\n");
}

void printhex(FILE *fptr, double m)
{
  int i, val;

  while (m<1) m *= 2;
  while (m>2) m /= 2;
  for (i=0; i<52; i+=4) {
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
  
