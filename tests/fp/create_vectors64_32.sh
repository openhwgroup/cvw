#!/bin/sh

BUILD="./TestFloat-3e/build/Linux-x86_64-GCC"
OUTPUT="./vectors"

$BUILD/testfloat_gen -rnear_even f64_to_f32 > $OUTPUT/f64_f32_rne.tv
$BUILD/testfloat_gen -rminMag f64_to_f32 > $OUTPUT/f64_f32_rz.tv
$BUILD/testfloat_gen -rmax f64_to_f32 > $OUTPUT/f64_f32_ru.tv
$BUILD/testfloat_gen -rmin f64_to_f32 > $OUTPUT/f64_f32_rd.tv

$BUILD/testfloat_gen -rnear_even f64_to_i32 > $OUTPUT/f64_i32_rne.tv
$BUILD/testfloat_gen -rminMag f64_to_i32 > $OUTPUT/f64_i32_rz.tv
$BUILD/testfloat_gen -rmax f64_to_i32 > $OUTPUT/f64_i32_ru.tv
$BUILD/testfloat_gen -rmin f64_to_i32 > $OUTPUT/f64_i32_rd.tv

$BUILD/testfloat_gen -rnear_even f64_to_ui32 > $OUTPUT/f64_ui32_rne.tv
$BUILD/testfloat_gen -rminMag f64_to_ui32 > $OUTPUT/f64_ui32_rz.tv
$BUILD/testfloat_gen -rmax f64_to_ui32 > $OUTPUT/f64_ui32_ru.tv
$BUILD/testfloat_gen -rmin f64_to_ui32 > $OUTPUT/f64_ui32_rd.tv



