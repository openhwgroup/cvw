#!/bin/sh
./testfloat_gen f32_eq > f32_cmp_eq.tv
./testfloat_gen f32_le > f32_cmp_le.tv
./testfloat_gen f32_lt > f32_cmp_lt.tv

./testfloat_gen f32_eq_signaling > f32_cmp_eq_signaling.tv
./testfloat_gen f32_le_quiet > f32_cmp_le_quiet.tv
./testfloat_gen f32_lt_quiet > f32_cmp_lt_quiet.tv

