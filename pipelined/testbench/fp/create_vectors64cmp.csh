#!/bin/sh
./testfloat_gen f64_eq > f64_cmp_eq.tv
./testfloat_gen f64_le > f64_cmp_le.tv
./testfloat_gen f64_lt > f64_cmp_lt.tv

./testfloat_gen f64_eq_signaling > f64_cmp_eq_signaling.tv
./testfloat_gen f64_le_quiet > f64_cmp_le_quiet.tv
./testfloat_gen f64_lt_quiet > f64_cmp_lt_quiet.tv

