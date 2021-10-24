#!/bin/sh
./testfloat_gen -rnear_even f32_add > f32_add_rne.tv
./testfloat_gen -rminMag f32_add > f32_add_rz.tv
./testfloat_gen -rmax f32_add > f32_add_ru.tv
./testfloat_gen -rmin f32_add > f32_add_rd.tv

./testfloat_gen -rnear_even f32_sub > f32_sub_rne.tv
./testfloat_gen -rminMag f32_sub > f32_sub_rz.tv
./testfloat_gen -rmax f32_sub > f32_sub_ru.tv
./testfloat_gen -rmin f32_sub > f32_sub_rd.tv

./testfloat_gen -rnear_even f32_div > f32_div_rne.tv
./testfloat_gen -rminMag f32_div > f32_div_rz.tv
./testfloat_gen -rmax f32_div > f32_div_ru.tv
./testfloat_gen -rmin f32_div > f32_div_rd.tv

./testfloat_gen -rnear_even f32_sqrt > f32_sqrt_rne.tv
./testfloat_gen -rminMag f32_sqrt > f32_sqrt_rz.tv
./testfloat_gen -rmax f32_sqrt > f32_sqrt_ru.tv
./testfloat_gen -rmin f32_sqrt > f32_sqrt_rd.tv
