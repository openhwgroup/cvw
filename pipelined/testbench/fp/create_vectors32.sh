#!/bin/sh

BUILD="./TestFloat-3e/build/Linux-x86_64-GCC"
OUTPUT="./vectors"

$BUILD/testfloat_gen -rnear_even f32_add > $OUTPUT/f32_add_rne.tv
$BUILD/testfloat_gen -rminMag f32_add > $OUTPUT/f32_add_rz.tv
$BUILD/testfloat_gen -rmax f32_add > $OUTPUT/f32_add_ru.tv
$BUILD/testfloat_gen -rmin f32_add > $OUTPUT/f32_add_rd.tv

$BUILD/testfloat_gen -rnear_even f32_sub > $OUTPUT/f32_sub_rne.tv
$BUILD/testfloat_gen -rminMag f32_sub > $OUTPUT/f32_sub_rz.tv
$BUILD/testfloat_gen -rmax f32_sub > $OUTPUT/f32_sub_ru.tv
$BUILD/testfloat_gen -rmin f32_sub > $OUTPUT/f32_sub_rd.tv

$BUILD/testfloat_gen -rnear_even f32_div > $OUTPUT/f32_div_rne.tv
$BUILD/testfloat_gen -rminMag f32_div > $OUTPUT/f32_div_rz.tv
$BUILD/testfloat_gen -rmax f32_div > $OUTPUT/f32_div_ru.tv
$BUILD/testfloat_gen -rmin f32_div > $OUTPUT/f32_div_rd.tv

$BUILD/testfloat_gen -rnear_even f32_sqrt > $OUTPUT/f32_sqrt_rne.tv
$BUILD/testfloat_gen -rminMag f32_sqrt > $OUTPUT/f32_sqrt_rz.tv
$BUILD/testfloat_gen -rmax f32_sqrt > $OUTPUT/f32_sqrt_ru.tv
$BUILD/testfloat_gen -rmin f32_sqrt > $OUTPUT/f32_sqrt_rd.tv

$BUILD/testfloat_gen -rnear_even f32_mul > $OUTPUT/f32_mul_rne.tv
$BUILD/testfloat_gen -rminMag f32_mul > $OUTPUT/f32_mul_rz.tv
$BUILD/testfloat_gen -rmax f32_mul > $OUTPUT/f32_mul_ru.tv
$BUILD/testfloat_gen -rmin f32_mul > $OUTPUT/f32_mul_rd.tv
