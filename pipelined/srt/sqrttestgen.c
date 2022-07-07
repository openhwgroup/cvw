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
  double mans[ENTRIES] = {1, 1.5, 1.25, 1.125, 1.0625,
			  1.75, 1.875, 1.99999,
			  1.1, 1.2, 1.01, 1.001, 1.0001,
			  1/1.1, 1/1.5, 1/1.25, 1/1.125};
  double exps[ENTRIES] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
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
    rFrac = sqrt(aFrac * pow(2, aExp - bias));
    rExp  = (int) (log(rFrac)/log(2) + bias);
    output(fptr, aExp, aFrac, rExp, rFrac);
  }
  
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
  fprintf(fptr, "%03x", aExp);
  printhex(fptr, aFrac);
  fprintf(fptr, "_");
  fprintf(fptr, "%03x", rExp);
  printhex(fptr, rFrac);
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
  
