/* testgen.c */

/* Written 10/31/96 by David Harris

   This program creates test vectors for mantissa component
   of an IEEE floating point divider.  It does dumb SRT division
   */

/* #includes */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

/* Constants */

#define ENTRIES  17
#define RANDOM_VECS 500

/* Prototypes */

void output(FILE *fptr, double a, double b, double r);
void printhex(FILE *fptr, double x);
double random_input(void);

/* Main */

void main(void)
{
  FILE *fptr;
  double a, b, r;
  double list[ENTRIES] = {1, 1.5, 1.25, 1.125, 1.0625,
			  1.75, 1.875, 1.99999,
			  1.1, 1.2, 1.01, 1.001, 1.0001,
			  1/1.1, 1/1.5, 1/1.25, 1/1.125};
  int i, j;

  if ((fptr = fopen("testvectors","w")) == NULL) {
    fprintf(stderr, "Couldn't write testvectors file\n");
    exit(1);
  }

  for (i=0; i<ENTRIES; i++) {
    b = list[i];
    for (j=0; j<ENTRIES; j++) {
      a = list[j];
      r = a/b;
      output(fptr, a, b, r);
    }
  }
  
  for (i = 0; i< RANDOM_VECS; i++) {
    a = random_input();
    b = random_input();
    r = a/b;
    output(fptr, a, b, r);
  }

  fclose(fptr);
}

/* Functions */

void output(FILE *fptr, double a, double b, double r)
{
  printhex(fptr, a);
  fprintf(fptr, "_");
  printhex(fptr, b);
  fprintf(fptr, "_");
  printhex(fptr, r);
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
  
