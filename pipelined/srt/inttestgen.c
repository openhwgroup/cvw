/* testgen.c */

/* Written 10/31/96 by David Harris

   This program creates test vectors for mantissa component
   of an IEEE floating point divider. 
   */

/* #includes */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

/* Constants */

#define ENTRIES  10
#define RANDOM_VECS 500

/* Prototypes */

void output(FILE *fptr, long a, long b, long r, long rem);
void printhex(FILE *fptr, long x);
double random_input(void);

/* Main */

void main(void)
{
  FILE *fptr;
  long a, b, r, rem;
  long list[ENTRIES] = {1, 3, 5, 18, 25, 33, 42, 65, 103, 255};
  int i, j;

  if ((fptr = fopen("inttestvectors","w")) == NULL) {
    fprintf(stderr, "Couldn't write testvectors file\n");
    exit(1);
  }

  for (i=0; i<ENTRIES; i++) {
    b = list[i];
    for (j=0; j<ENTRIES; j++) {
      a = list[j];
      r = a/b;
      rem = a%b;
      output(fptr, a, b, r, rem);
    }
  }
  
//   for (i = 0; i< RANDOM_VECS; i++) {
//     a = random_input();
//     b = random_input();
//     r = a/b;
//     output(fptr, a, b, r);
//   }

  fclose(fptr);
}

/* Functions */

void output(FILE *fptr, long a, long b, long r, long rem)
{
  printhex(fptr, a);
  fprintf(fptr, "_");
  printhex(fptr, b);
  fprintf(fptr, "_");
  printhex(fptr, r);
  fprintf(fptr, "_");
  printhex(fptr, rem);
  fprintf(fptr, "\n");
}

void printhex(FILE *fptr, long m)
{
    fprintf(fptr, "%016llx", m);
}    

double random_input(void)
{
  return 1.0 + rand()/32767.0;
}
  
