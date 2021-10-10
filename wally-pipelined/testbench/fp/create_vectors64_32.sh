#!/bin/sh
./testfloat_gen -rnear_even f64_to_f32 > f64_f32_rne.tv
./testfloat_gen -rminMag f64_to_f32 > f64_f32_rz.tv
./testfloat_gen -rmax f64_to_f32 > f64_f32_ru.tv
./testfloat_gen -rmin f64_to_f32 > f64_f32_rd.tv

./testfloat_gen -rnear_even f64_to_i32 > f64_i32_rne.tv
./testfloat_gen -rminMag f64_to_i32 > f64_i32_rz.tv
./testfloat_gen -rmax f64_to_i32 > f64_i32_ru.tv
./testfloat_gen -rmin f64_to_i32 > f64_i32_rd.tv

./testfloat_gen -rnear_even f64_to_ui32 > f64_ui32_rne.tv
./testfloat_gen -rminMag f64_to_ui32 > f64_ui32_rz.tv
./testfloat_gen -rmax f64_to_ui32 > f64_ui32_ru.tv
./testfloat_gen -rmin f64_to_ui32 > f64_ui32_rd.tv



