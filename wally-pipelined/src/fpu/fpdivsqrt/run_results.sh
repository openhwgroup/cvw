#!/bin/sh
echo 'f64 DIV RNE' > run_results.txt
cat f64_div_rne.out | grep '_0$' >> run_results.txt
echo 'f64 DIV RD' >> run_results.txt
cat f64_div_rd.out | grep '_0$' >> run_results.txt
echo 'f64 DIV RU' >> run_results.txt
cat f64_div_ru.out | grep '_0$' >> run_results.txt
echo 'f64 DIV RZ' >> run_results.txt
cat f64_div_rz.out | grep '_0$' >> run_results.txt

echo 'f32 DIV RNE' >> run_results.txt
cat f32_div_rne.out | grep '_0$' >> run_results.txt
echo 'f32 DIV RD' >> run_results.txt
cat f32_div_rd.out | grep '_0$' >> run_results.txt
echo 'f32 DIV RU' >> run_results.txt
cat f32_div_ru.out | grep '_0$' >> run_results.txt
echo 'f32 DIV RZ' >> run_results.txt
cat f32_div_rz.out | grep '_0$' >> run_results.txt

echo 'f64 SQRT RNE' >> run_results.txt
cat f64_sqrt_rne.out | grep '_0$' >> run_results.txt
echo 'f64 SQRT RD' >> run_results.txt
cat f64_sqrt_rd.out | grep '_0$' >> run_results.txt
echo 'f64 SQRT RU' >> run_results.txt
cat f64_sqrt_ru.out | grep '_0$' >> run_results.txt
echo 'f64 SQRT RZ' >> run_results.txt
cat f64_sqrt_rz.out | grep '_0$' >> run_results.txt

echo 'f32 SQRT RNE' >> run_results.txt
cat f32_sqrt_rne.out | grep '_0$' >> run_results.txt
echo 'f32 SQRT RD' >> run_results.txt
cat f32_sqrt_rd.out | grep '_0$' >> run_results.txt
echo 'f32 SQRT RU' >> run_results.txt
cat f32_sqrt_ru.out | grep '_0$' >> run_results.txt
echo 'f32 SQRT RZ' >> run_results.txt
cat f32_sqrt_rz.out | grep '_0$' >> run_results.txt
