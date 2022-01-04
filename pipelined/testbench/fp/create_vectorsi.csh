#!/bin/sh
./testfloat_gen -rnear_even -i32_to_f64 > i32_f64_rne.tv
./testfloat_gen -rminMag -i32_to_f64 > i32_f64_rz.tv
./testfloat_gen -rmax -i32_to_f64 > i32_f64_ru.tv
./testfloat_gen -rmin -i32_to_f64 > i32_f64_rd.tv

./testfloat_gen -rnear_even -i64_to_f64 > i64_f64_rne.tv
./testfloat_gen -rminMag -i64_to_f64 > i64_f64_rz.tv
./testfloat_gen -rmax -i64_to_f64 > i64_f64_ru.tv
./testfloat_gen -rmin -i64_to_f64 > i64_f64_rd.tv

./testfloat_gen -rnear_even -i32_to_f32 > i32_f32_rne.tv
./testfloat_gen -rminMag -i32_to_f32 > i32_f32_rz.tv
./testfloat_gen -rmax -i32_to_f32 > i32_f32_ru.tv
./testfloat_gen -rmin -i32_to_f32 > i32_f32_rd.tv

./testfloat_gen -rnear_even -i64_to_f32 > i64_f32_rne.tv
./testfloat_gen -rminMag -i64_to_f32 > i64_f32_rz.tv
./testfloat_gen -rmax -i64_to_f32 > i64_f32_ru.tv
./testfloat_gen -rmin -i64_to_f32 > i64_f32_rd.tv

./testfloat_gen -rnear_even -ui32_to_f64 > ui32_f64_rne.tv
./testfloat_gen -rminMag -ui32_to_f64 > ui32_f64_rz.tv
./testfloat_gen -rmax -ui32_to_f64 > ui32_f64_ru.tv
./testfloat_gen -rmin -ui32_to_f64 > ui32_f64_rd.tv

./testfloat_gen -rnear_even -ui64_to_f64 > ui64_f64_rne.tv
./testfloat_gen -rminMag -ui64_to_f64 > ui64_f64_rz.tv
./testfloat_gen -rmax -ui64_to_f64 > ui64_f64_ru.tv
./testfloat_gen -rmin -ui64_to_f64 > ui64_f64_rd.tv

./testfloat_gen -rnear_even -ui32_to_f32 > ui32_f32_rne.tv
./testfloat_gen -rminMag -ui32_to_f32 > ui32_f32_rz.tv
./testfloat_gen -rmax -ui32_to_f32 > ui32_f32_ru.tv
./testfloat_gen -rmin -ui32_to_f32 > ui32_f32_rd.tv

./testfloat_gen -rnear_even -ui64_to_f32 > ui64_f32_rne.tv
./testfloat_gen -rminMag -ui64_to_f32 > ui64_f32_rz.tv
./testfloat_gen -rmax -ui64_to_f32 > ui64_f32_ru.tv
./testfloat_gen -rmin -ui64_to_f32 > ui64_f32_rd.tv

