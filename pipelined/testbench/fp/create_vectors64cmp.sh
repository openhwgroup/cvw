#!/bin/sh

BUILD="./TestFloat-3e/build/Linux-x86_64-GCC"
OUTPUT="./vectors"

$BUILD/testfloat_gen f64_eq > $OUTPUT/f64_cmp_eq.tv
$BUILD/testfloat_gen f64_le > $OUTPUT/f64_cmp_le.tv
$BUILD/testfloat_gen f64_lt > $OUTPUT/f64_cmp_lt.tv

$BUILD/testfloat_gen f64_eq_signaling > $OUTPUT/f64_cmp_eq_signaling.tv
$BUILD/testfloat_gen f64_le_quiet > $OUTPUT/f64_cmp_le_quiet.tv
$BUILD/testfloat_gen f64_lt_quiet > $OUTPUT/f64_cmp_lt_quiet.tv

