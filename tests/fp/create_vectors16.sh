#!/bin/sh

BUILD="./TestFloat-3e/build/Linux-x86_64-GCC"
OUTPUT="./vectors"

$BUILD/testfloat_gen -rnear_even f16_add > $OUTPUT/f16_add_rne.tv
$BUILD/testfloat_gen -rminMag f16_add > $OUTPUT/f16_add_rz.tv
$BUILD/testfloat_gen -rmin f16_add > $OUTPUT/f16_add_ru.tv
$BUILD/testfloat_gen -rmax f16_add > $OUTPUT/f16_add_rd.tv

$BUILD/testfloat_gen -rnear_even f16_sub > $OUTPUT/f16_sub_rne.tv
$BUILD/testfloat_gen -rminMag f16_sub > $OUTPUT/f16_sub_rz.tv
$BUILD/testfloat_gen -rmin f16_sub > $OUTPUT/f16_sub_ru.tv
$BUILD/testfloat_gen -rmax f16_sub > $OUTPUT/f16_sub_rd.tv

$BUILD/testfloat_gen -rnear_even f16_div > $OUTPUT/f16_div_rne.tv
$BUILD/testfloat_gen -rminMag f16_div > $OUTPUT/f16_div_rz.tv
$BUILD/testfloat_gen -rmin f16_div > $OUTPUT/f16_div_ru.tv
$BUILD/testfloat_gen -rmax f16_div > $OUTPUT/f16_div_rd.tv

$BUILD/testfloat_gen -rnear_even f16_sqrt > $OUTPUT/f16_sqrt_rne.tv
$BUILD/testfloat_gen -rminMag f16_sqrt > $OUTPUT/f16_sqrt_rz.tv
$BUILD/testfloat_gen -rmin f16_sqrt > $OUTPUT/f16_sqrt_ru.tv
$BUILD/testfloat_gen -rmax f16_sqrt > $OUTPUT/f16_sqrt_rd.tv

$BUILD/testfloat_gen -rnear_even f16_mul > $OUTPUT/f16_mul_rne.tv
$BUILD/testfloat_gen -rminMag f16_mul > $OUTPUT/f16_mul_rz.tv
$BUILD/testfloat_gen -rmax f16_mul > $OUTPUT/f16_mul_ru.tv
$BUILD/testfloat_gen -rmin f16_mul > $OUTPUT/f16_mul_rd.tv


