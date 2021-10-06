#!/bin/sh
./testfloat_gen -rnear_even f32_to_f64 > f32_f64_rne.tv
./testfloat_gen -rminMag f32_to_f64 > f32_f64_rz.tv
./testfloat_gen -rmax f32_to_f64 > f32_f64_ru.tv
./testfloat_gen -rmin f32_to_f64 > f32_f64_rd.tv
