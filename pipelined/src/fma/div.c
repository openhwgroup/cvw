#include <stdio.h>
#include <stdint.h>
#include "softfloat.h"
#include "softfloat_types.h"

int float_rounding_mode = 0;

union dp {
  unsigned short x[4];
  double y;
} X;


int main()
{
    uint8_t rounding_mode;
    uint8_t exceptions;

    uint64_t n, d, result;
    float64_t   d_n, d_d, d_result;

    n = 0x3feffffffefffff6;
    d = 0xffeffffffffffffe;
    //n = 0x00000000400001ff;
    //d = 0x3ffffdfffffffbfe;    

    d_n.v = n;
    d_d.v = d;

    softfloat_roundingMode = rounding_mode;
    softfloat_exceptionFlags = 0;
    softfloat_detectTininess = softfloat_tininess_beforeRounding;

    d_result = f64_div(d_n, d_d);

    //result = d_result.v;    
    //exceptions = softfloat_exceptionFlags & 0x1f;

    X.x[3] = (d_result.v & 0xffff000000000000) >> 48;
    X.x[2] = (d_result.v & 0x0000ffff00000000) >> 32;    
    X.x[1] = (d_result.v & 0x00000000ffff0000) >> 16;
    X.x[0] = (d_result.v & 0x000000000000ffff);

    printf("Number = %.4x\n", X.x[3]);
    printf("Number = %.4x\n", X.x[2]);
    printf("Number = %.4x\n", X.x[1]);
    printf("Number = %.4x\n", X.x[0]);
    printf("Number = %1.25lg\n", X.y);    
    

    return 0;
}
