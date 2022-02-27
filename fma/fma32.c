#include <stdio.h>
#include <stdint.h>
#include "softfloat.h"
#include "softfloat_types.h"

int float_rounding_mode = 0;

union sp {
  unsigned short x[2];
  float y;
} X;


int main()
{
    uint8_t rounding_mode;
    uint8_t exceptions;

    uint32_t multiplier, multiplicand, addend, result;
    float32_t f_multiplier, f_multiplicand, f_addend, f_result;

    multiplier = 0xbf800000;
    multiplicand = 0xbf800000;
    addend = 0xffaaaaaa;

    f_multiplier.v = multiplier;
    f_multiplicand.v = multiplicand;
    f_addend.v = addend;

    softfloat_roundingMode = rounding_mode;
    softfloat_exceptionFlags = 0;
    softfloat_detectTininess = softfloat_tininess_beforeRounding;

    f_result = f32_mulAdd(f_multiplier, f_multiplicand, f_addend);

    result = f_result.v;    
    exceptions = softfloat_exceptionFlags & 0x1f;

    printf("%x\n", f_result.v);

    // Print out SP number
    X.x[1] = (f_result.v & 0xffff0000) >> 16;
    X.x[0] = (f_result.v & 0x0000ffff);
    printf("Number = %f\n", X.y);

    return 0;
}
