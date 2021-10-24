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

./testfloat_gen -rnear_even -f32_to_i32 > f32_i32_rne.tv
./testfloat_gen -rminMag -f32_to_i32 > f32_i32_rz.tv
./testfloat_gen -rmax -f32_to_i32 > f32_i32_ru.tv
./testfloat_gen -rmin -f32_to_i32 > f32_i32_rd.tv

./testfloat_gen -rnear_even -f32_to_ui32 > f32_ui32_rne.tv
./testfloat_gen -rminMag -f32_to_ui32 > f32_ui32_rz.tv
./testfloat_gen -rmax -f32_to_ui32 > f32_ui32_ru.tv
./testfloat_gen -rmin -f32_to_ui32 > f32_ui32_rd.tv

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

./testfloat_gen -rnear_even -f64_to_i64 > f64_i64_rne.tv
./testfloat_gen -rminMag -f64_to_i64 > f64_i64_rz.tv
./testfloat_gen -rmax -f64_to_i64 > f64_i64_ru.tv
./testfloat_gen -rmin -f64_to_i64 > f64_i64_rd.tv

./testfloat_gen -rnear_even -f64_to_ui64 > f64_ui64_rne.tv
./testfloat_gen -rminMag -f64_to_ui64 > f64_ui64_rz.tv
./testfloat_gen -rmax -f64_to_ui64 > f64_ui64_ru.tv
./testfloat_gen -rmin -f64_to_ui64 > f64_ui64_rd.tv
