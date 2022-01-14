#!/bin/sh

BUILD="./TestFloat-3e/build/Linux-x86_64-GCC"
OUTPUT="./vectors"

$BUILD/testfloat_gen -rnear_even f32_to_f64 > $OUTPUT/f32_f64_rne.tv
$BUILD/testfloat_gen -rminMag f32_to_f64 > $OUTPUT/f32_f64_rz.tv
$BUILD/testfloat_gen -rmax f32_to_f64 > $OUTPUT/f32_f64_ru.tv
$BUILD/testfloat_gen -rmin f32_to_f64 > $OUTPUT/f32_f64_rd.tv

$BUILD/testfloat_gen -rnear_even f32_to_i64 > $OUTPUT/f32_i64_rne.tv
$BUILD/testfloat_gen -rminMag f32_to_i64 > $OUTPUT/f32_i64_rz.tv
$BUILD/testfloat_gen -rmax f32_to_i64 > $OUTPUT/f32_i64_ru.tv
$BUILD/testfloat_gen -rmin f32_to_i64 > $OUTPUT/f32_i64_rd.tv

$BUILD/testfloat_gen -rnear_even f32_to_ui64 > $OUTPUT/f32_ui64_rne.tv
$BUILD/testfloat_gen -rminMag f32_to_ui64 > $OUTPUT/f32_ui64_rz.tv
$BUILD/testfloat_gen -rmax f32_to_ui64 > $OUTPUT/f32_ui64_ru.tv
$BUILD/testfloat_gen -rmin f32_to_ui64 > $OUTPUT/f32_ui64_rd.tv

