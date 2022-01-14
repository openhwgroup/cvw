#!/bin/sh

BUILD="./TestFloat-3e/build/Linux-x86_64-GCC"
OUTPUT="./vectors"

$BUILD/testfloat_gen -rnear_even -i32_to_f64 > $OUTPUT/i32_f64_rne.tv
$BUILD/testfloat_gen -rminMag -i32_to_f64 > $OUTPUT/i32_f64_rz.tv
$BUILD/testfloat_gen -rmax -i32_to_f64 > $OUTPUT/i32_f64_ru.tv
$BUILD/testfloat_gen -rmin -i32_to_f64 > $OUTPUT/i32_f64_rd.tv

$BUILD/testfloat_gen -rnear_even -i64_to_f64 > $OUTPUT/i64_f64_rne.tv
$BUILD/testfloat_gen -rminMag -i64_to_f64 > $OUTPUT/i64_f64_rz.tv
$BUILD/testfloat_gen -rmax -i64_to_f64 > $OUTPUT/i64_f64_ru.tv
$BUILD/testfloat_gen -rmin -i64_to_f64 > $OUTPUT/i64_f64_rd.tv

$BUILD/testfloat_gen -rnear_even -i32_to_f32 > $OUTPUT/i32_f32_rne.tv
$BUILD/testfloat_gen -rminMag -i32_to_f32 > $OUTPUT/i32_f32_rz.tv
$BUILD/testfloat_gen -rmax -i32_to_f32 > $OUTPUT/i32_f32_ru.tv
$BUILD/testfloat_gen -rmin -i32_to_f32 > $OUTPUT/i32_f32_rd.tv

$BUILD/testfloat_gen -rnear_even -f32_to_i32 > $OUTPUT/f32_i32_rne.tv
$BUILD/testfloat_gen -rminMag -f32_to_i32 > $OUTPUT/f32_i32_rz.tv
$BUILD/testfloat_gen -rmax -f32_to_i32 > $OUTPUT/f32_i32_ru.tv
$BUILD/testfloat_gen -rmin -f32_to_i32 > $OUTPUT/f32_i32_rd.tv

$BUILD/testfloat_gen -rnear_even -f32_to_ui32 > $OUTPUT/f32_ui32_rne.tv
$BUILD/testfloat_gen -rminMag -f32_to_ui32 > $OUTPUT/f32_ui32_rz.tv
$BUILD/testfloat_gen -rmax -f32_to_ui32 > $OUTPUT/f32_ui32_ru.tv
$BUILD/testfloat_gen -rmin -f32_to_ui32 > $OUTPUT/f32_ui32_rd.tv

$BUILD/testfloat_gen -rnear_even -i64_to_f32 > $OUTPUT/i64_f32_rne.tv
$BUILD/testfloat_gen -rminMag -i64_to_f32 > $OUTPUT/i64_f32_rz.tv
$BUILD/testfloat_gen -rmax -i64_to_f32 > $OUTPUT/i64_f32_ru.tv
$BUILD/testfloat_gen -rmin -i64_to_f32 > $OUTPUT/i64_f32_rd.tv

$BUILD/testfloat_gen -rnear_even -ui32_to_f64 > $OUTPUT/ui32_f64_rne.tv
$BUILD/testfloat_gen -rminMag -ui32_to_f64 > $OUTPUT/ui32_f64_rz.tv
$BUILD/testfloat_gen -rmax -ui32_to_f64 > $OUTPUT/ui32_f64_ru.tv
$BUILD/testfloat_gen -rmin -ui32_to_f64 > $OUTPUT/ui32_f64_rd.tv

$BUILD/testfloat_gen -rnear_even -ui64_to_f64 > $OUTPUT/ui64_f64_rne.tv
$BUILD/testfloat_gen -rminMag -ui64_to_f64 > $OUTPUT/ui64_f64_rz.tv
$BUILD/testfloat_gen -rmax -ui64_to_f64 > $OUTPUT/ui64_f64_ru.tv
$BUILD/testfloat_gen -rmin -ui64_to_f64 > $OUTPUT/ui64_f64_rd.tv

$BUILD/testfloat_gen -rnear_even -ui32_to_f32 > $OUTPUT/ui32_f32_rne.tv
$BUILD/testfloat_gen -rminMag -ui32_to_f32 > $OUTPUT/ui32_f32_rz.tv
$BUILD/testfloat_gen -rmax -ui32_to_f32 > $OUTPUT/ui32_f32_ru.tv
$BUILD/testfloat_gen -rmin -ui32_to_f32 > $OUTPUT/ui32_f32_rd.tv

$BUILD/testfloat_gen -rnear_even -ui64_to_f32 > $OUTPUT/ui64_f32_rne.tv
$BUILD/testfloat_gen -rminMag -ui64_to_f32 > $OUTPUT/ui64_f32_rz.tv
$BUILD/testfloat_gen -rmax -ui64_to_f32 > $OUTPUT/ui64_f32_ru.tv
$BUILD/testfloat_gen -rmin -ui64_to_f32 > $OUTPUT/ui64_f32_rd.tv

$BUILD/testfloat_gen -rnear_even -f64_to_i64 > $OUTPUT/f64_i64_rne.tv
$BUILD/testfloat_gen -rminMag -f64_to_i64 > $OUTPUT/f64_i64_rz.tv
$BUILD/testfloat_gen -rmax -f64_to_i64 > $OUTPUT/f64_i64_ru.tv
$BUILD/testfloat_gen -rmin -f64_to_i64 > $OUTPUT/f64_i64_rd.tv

$BUILD/testfloat_gen -rnear_even -f64_to_ui64 > $OUTPUT/f64_ui64_rne.tv
$BUILD/testfloat_gen -rminMag -f64_to_ui64 > $OUTPUT/f64_ui64_rz.tv
$BUILD/testfloat_gen -rmax -f64_to_ui64 > $OUTPUT/f64_ui64_ru.tv
$BUILD/testfloat_gen -rmin -f64_to_ui64 > $OUTPUT/f64_ui64_rd.tv
