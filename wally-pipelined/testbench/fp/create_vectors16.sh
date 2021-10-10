#!/bin/sh
./testfloat_gen -rnear_even f16_add > f16_add_rne.tv
./testfloat_gen -rminMag f16_add > f16_add_rz.tv
./testfloat_gen -rmin f16_add > f16_add_ru.tv
./testfloat_gen -rmax f16_add > f16_add_rd.tv

./testfloat_gen -rnear_even f16_sub > f16_sub_rne.tv
./testfloat_gen -rminMag f16_sub > f16_sub_rz.tv
./testfloat_gen -rmin f16_sub > f16_sub_ru.tv
./testfloat_gen -rmax f16_sub > f16_sub_rd.tv

./testfloat_gen -rnear_even f16_div > f16_div_rne.tv
./testfloat_gen -rminMag f16_div > f16_div_rz.tv
./testfloat_gen -rmin f16_div > f16_div_ru.tv
./testfloat_gen -rmax f16_div > f16_div_rd.tv

./testfloat_gen -rnear_even f16_sqrt > f16_sqrt_rne.tv
./testfloat_gen -rminMag f16_sqrt > f16_sqrt_rz.tv
./testfloat_gen -rmin f16_sqrt > f16_sqrt_ru.tv
./testfloat_gen -rmax f16_sqrt > f16_sqrt_rd.tv


