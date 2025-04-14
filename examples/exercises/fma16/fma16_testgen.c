// fma16_testgen.c
// David_Harris 8 February 2025
// Generate tests for 16-bit FMA
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "softfloat.h"
#include "softfloat_types.h"

typedef union sp {
  float32_t v;
  float f;
} sp;

// lists of tests, terminated with 0x8000
uint16_t easyExponents[] = {15, 0x8000};
uint16_t easyFracts[] = {0, 0x200, 0x8000}; // 1.0 and 1.1

void softfloatInit(void) {
    softfloat_roundingMode = softfloat_round_minMag; 
    softfloat_exceptionFlags = 0;
    softfloat_detectTininess = softfloat_tininess_beforeRounding;
}

float convFloat(float16_t f16) {
    float32_t f32;
    float res;
    sp r;

    // convert half to float for printing
    f32 = f16_to_f32(f16);
    r.v = f32;
    res = r.f;
    return res;
}

void genCase(FILE *fptr, float16_t x, float16_t y, float16_t z, int mul, int add, int negp, int negz, int roundingMode, int zeroAllowed, int infAllowed, int nanAllowed) {
    float16_t result;
    int op, flagVals;
    char calc[80], flags[80];
    float32_t x32, y32, z32, r32;
    float xf, yf, zf, rf;
    float16_t x2, z2;
    float16_t smallest;

    if (!mul) y.v = 0x3C00; // force y to 1 to avoid multiply
    if (!add) z.v = 0x0000; // force z to 0 to avoid add

    // Negated versions of x and z are used in the mulAdd call where necessary
    x2 = x;
    z2 = z;
    if (negp) x2.v ^= 0x8000; // flip sign of x to negate p
    if (negz) z2.v ^= 0x8000; // flip sign of z to negate z

    op = roundingMode << 4 | mul<<3 | add<<2 | negp<<1 | negz;
//    printf("op = %02x rm %d mul %d add %d negp %d negz %d\n", op, roundingMode, mul, add, negp, negz);
    softfloat_exceptionFlags = 0; // clear exceptions
    result = f16_mulAdd(x2, y, z2); // call SoftFloat to compute expected result

    // Extract expected flags from SoftFloat
    sprintf(flags, "NV: %d OF: %d UF: %d NX: %d", 
        (softfloat_exceptionFlags >> 4) % 2,
        (softfloat_exceptionFlags >> 2) % 2,
        (softfloat_exceptionFlags >> 1) % 2,
        (softfloat_exceptionFlags) % 2);
    // pack these four flags into one nibble, discarding DZ flag
    flagVals = softfloat_exceptionFlags & 0x7 | ((softfloat_exceptionFlags >> 1) & 0x8);

    // convert to floats for printing
    xf = convFloat(x);
    yf = convFloat(y);
    zf = convFloat(z);
    rf = convFloat(result);
    if (mul)
        if (add) sprintf(calc, "%f * %f + %f = %f", xf, yf, zf, rf);
        else     sprintf(calc, "%f * %f = %f", xf, yf, rf);
    else         sprintf(calc, "%f + %f = %f", xf, zf, rf);

    // omit denorms, which aren't required for this project
    smallest.v = 0x0400;
    float16_t resultmag = result;
    resultmag.v &= 0x7FFF; // take absolute value
    if (f16_lt(resultmag, smallest) && (resultmag.v != 0x0000)) fprintf (fptr, "// skip denorm: ");
    if ((softfloat_exceptionFlags >> 1) % 2) fprintf(fptr, "// skip underflow: ");

    // skip special cases if requested
    if (resultmag.v == 0x0000 && !zeroAllowed) fprintf(fptr, "// skip zero: ");
    if ((resultmag.v == 0x7C00 || resultmag.v == 0x7BFF) && !infAllowed)  fprintf(fptr, "// Skip inf: ");
    if (resultmag.v >  0x7C00 && !nanAllowed)  fprintf(fptr, "// Skip NaN: ");

    // print the test case
    fprintf(fptr, "%04x_%04x_%04x_%02x_%04x_%01x // %s %s\n", x.v, y.v, z.v, op, result.v, flagVals, calc, flags);
}

void prepTests(uint16_t *e, uint16_t *f, char *testName, char *desc, float16_t *cases, 
               FILE *fptr, int *numCases) {
    int i, j;

    // Loop over all of the exponents and fractions, generating and counting all cases
    fprintf(fptr, "%s", desc); fprintf(fptr, "\n");
    *numCases=0;
    for (i=0; e[i] != 0x8000; i++)
        for (j=0; f[j] != 0x8000; j++) {
            cases[*numCases].v = f[j] | e[i]<<10;
            *numCases = *numCases + 1;
        }
}

void genMulTests(uint16_t *e, uint16_t *f, int sgn, char *testName, char *desc, int roundingMode, int zeroAllowed, int infAllowed, int nanAllowed) {
    int i, j, k, numCases;
    float16_t x, y, z;
    float16_t cases[100000];
    FILE *fptr;
    char fn[80];
 
    sprintf(fn, "work/%s.tv", testName);
    if ((fptr = fopen(fn, "w")) == 0) {
        printf("Error opening to write file %s.  Does directory exist?\n", fn);
        exit(1);
    }
    prepTests(e, f, testName, desc, cases, fptr, &numCases);
    z.v = 0x0000;
    for (i=0; i < numCases; i++) { 
        x.v = cases[i].v;
        for (j=0; j<numCases; j++) {
            y.v = cases[j].v;
            for (k=0; k<=sgn; k++) {
                y.v ^= (k<<15);
                genCase(fptr, x, y, z, 1, 0, 0, 0, roundingMode, zeroAllowed, infAllowed, nanAllowed);
            }
        }
    }
    fclose(fptr);
}

int main()
{
    if (system("mkdir -p work") != 0) exit(1); // create work directory if it doesn't exist
    softfloatInit(); // configure softfloat modes
 
    // Test cases: multiplication
    genMulTests(easyExponents, easyFracts, 0, "fmul_0", "// Multiply with exponent of 0, significand of 1.0 and 1.1, RZ", 0, 0, 0, 0);

/*  // example of how to generate tests with a different rounding mode
    softfloat_roundingMode = softfloat_round_near_even; 
    genMulTests(easyExponents, easyFracts, 0, "fmul_0_rne", "// Multiply with exponent of 0, significand of 1.0 and 1.1, RNE", 1, 0, 0, 0); */

    // Add your cases here
  
    return 0;
}
