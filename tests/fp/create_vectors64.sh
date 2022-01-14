#!/bin/sh

BUILD="./TestFloat-3e/build/Linux-x86_64-GCC"
OUTPUT="./vectors"

$BUILD/testfloat_gen -rnear_even f64_add > $OUTPUT/f64_add_rne.tv
$BUILD/testfloat_gen -rminMag f64_add > $OUTPUT/f64_add_rz.tv
$BUILD/testfloat_gen -rmax f64_add > $OUTPUT/f64_add_ru.tv
$BUILD/testfloat_gen -rmin f64_add > $OUTPUT/f64_add_rd.tv

$BUILD/testfloat_gen -rnear_even f64_sub > $OUTPUT/f64_sub_rne.tv
$BUILD/testfloat_gen -rminMag f64_sub > $OUTPUT/f64_sub_rz.tv
$BUILD/testfloat_gen -rmax f64_sub > $OUTPUT/f64_sub_ru.tv
$BUILD/testfloat_gen -rmin f64_sub > $OUTPUT/f64_sub_rd.tv

$BUILD/testfloat_gen -rnear_even f64_div > $OUTPUT/f64_div_rne.tv
$BUILD/testfloat_gen -rminMag f64_div > $OUTPUT/f64_div_rz.tv
$BUILD/testfloat_gen -rmax f64_div > $OUTPUT/f64_div_ru.tv
$BUILD/testfloat_gen -rmin f64_div > $OUTPUT/f64_div_rd.tv

$BUILD/testfloat_gen -rnear_even f64_sqrt > $OUTPUT/f64_sqrt_rne.tv
$BUILD/testfloat_gen -rminMag f64_sqrt > $OUTPUT/f64_sqrt_rz.tv
$BUILD/testfloat_gen -rmax f64_sqrt > $OUTPUT/f64_sqrt_ru.tv
$BUILD/testfloat_gen -rmin f64_sqrt > $OUTPUT/f64_sqrt_rd.tv

$BUILD/testfloat_gen -rnear_even f64_mul > $OUTPUT/f64_mul_rne.tv
$BUILD/testfloat_gen -rminMag f64_mul > $OUTPUT/f64_mul_rz.tv
$BUILD/testfloat_gen -rmax f64_mul > $OUTPUT/f64_mul_ru.tv
$BUILD/testfloat_gen -rmin f64_mul > $OUTPUT/f64_mul_rd.tv

