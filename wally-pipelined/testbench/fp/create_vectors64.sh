#!/bin/sh
./testfloat_gen -rnear_even f64_add > f64_add_rne.tv
./testfloat_gen -rminMag f64_add > f64_add_rz.tv
./testfloat_gen -rmax f64_add > f64_add_ru.tv
./testfloat_gen -rmin f64_add > f64_add_rd.tv

./testfloat_gen -rnear_even f64_sub > f64_sub_rne.tv
./testfloat_gen -rminMag f64_sub > f64_sub_rz.tv
./testfloat_gen -rmax f64_sub > f64_sub_ru.tv
./testfloat_gen -rmin f64_sub > f64_sub_rd.tv

./testfloat_gen -rnear_even f64_div > f64_div_rne.tv
./testfloat_gen -rminMag f64_div > f64_div_rz.tv
./testfloat_gen -rmax f64_div > f64_div_ru.tv
./testfloat_gen -rmin f64_div > f64_div_rd.tv

./testfloat_gen -rnear_even f64_sqrt > f64_sqrt_rne.tv
./testfloat_gen -rminMag f64_sqrt > f64_sqrt_rz.tv
./testfloat_gen -rmax f64_sqrt > f64_sqrt_ru.tv
./testfloat_gen -rmin f64_sqrt > f64_sqrt_rd.tv
