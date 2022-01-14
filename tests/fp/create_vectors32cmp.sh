#!/bin/sh

BUILD="./TestFloat-3e/build/Linux-x86_64-GCC"
OUTPUT="./vectors"

$BUILD/testfloat_gen f32_eq > $OUTPUT/f32_cmp_eq.tv
$BUILD/testfloat_gen f32_le > $OUTPUT/f32_cmp_le.tv
$BUILD/testfloat_gen f32_lt > $OUTPUT/f32_cmp_lt.tv

$BUILD/testfloat_gen f32_eq_signaling > $OUTPUT/f32_cmp_eq_signaling.tv
$BUILD/testfloat_gen f32_le_quiet > $OUTPUT/f32_cmp_le_quiet.tv
$BUILD/testfloat_gen f32_lt_quiet > $OUTPUT/f32_cmp_lt_quiet.tv

