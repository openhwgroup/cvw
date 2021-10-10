These are the testvectors (TV) to test the floating-point units using
Berkeley TestFloat written originally by John Hauser.  TestFloat
requires both TestFloat and SoftFloat.

The locations at time of this README is found here:
TestFloat-3e:  http://www.jhauser.us/arithmetic/TestFloat.html
SoftFloat-3e:  http://www.jhauser.us/arithmetic/SoftFloat.html

These files have been compiled on a x86_64 environment by going into
the build/Linux-x86_64-GCC directory and typing make.  A script
createX.sh (e.g., create_vectors32.sh) has been included that create
the TV for each rounding mode  and operation.  These scripts must be
run in the build directory of TestFloat.

After each TV has been created a script (included) is run called
undy.sh that puts an underscore between vector to allow SystemVerilog
readmemh to read correctly.

./undy.sh file.tv

To remove all the underscores from all the TV files, one can run the
command that will add underscores appropriately to all the files.

sed -i 's/ /_/g' *.tv

Note: due to size, the fxx_fma_xx.tv vectors are not included.
However, they can easily be created with the create scripts.

James Stine
10/7/2021

List of TestVectors (TV) and sizes

   46464   185856   836352 f16_add_rd.tv
   46464   185856   836352 f16_add_rne.tv
   46464   185856   836352 f16_add_ru.tv
   46464   185856   836352 f16_add_rz.tv
   46464   185856   836352 f16_div_rd.tv
   46464   185856   836352 f16_div_rne.tv
   46464   185856   836352 f16_div_ru.tv
   46464   185856   836352 f16_div_rz.tv
     408     1224     5304 f16_sqrt_rd.tv
     408     1224     5304 f16_sqrt_rne.tv
     408     1224     5304 f16_sqrt_ru.tv
     408     1224     5304 f16_sqrt_rz.tv
   46464   185856   836352 f16_sub_rd.tv
   46464   185856   836352 f16_sub_rne.tv
   46464   185856   836352 f16_sub_ru.tv
   46464   185856   836352 f16_sub_rz.tv
   46464   185856  1393920 f32_add_rd.tv
   46464   185856  1393920 f32_add_rne.tv
   46464   185856  1393920 f32_add_ru.tv
   46464   185856  1393920 f32_add_rz.tv
   46464   185856  1068672 f32_cmp_eq_signaling.tv
   46464   185856  1068672 f32_cmp_eq.tv
   46464   185856  1068672 f32_cmp_le_quiet.tv
   46464   185856  1068672 f32_cmp_le.tv
   46464   185856  1068672 f32_cmp_lt_quiet.tv
   46464   185856  1068672 f32_cmp_lt.tv
   46464   185856  1393920 f32_div_rd.tv
   46464   185856  1393920 f32_div_rne.tv
   46464   185856  1393920 f32_div_ru.tv
   46464   185856  1393920 f32_div_rz.tv
     600     1800    17400 f32_f64_rd.tv
     600     1800    17400 f32_f64_rne.tv
     600     1800    17400 f32_f64_ru.tv
     600     1800    17400 f32_f64_rz.tv
     600     1800    12600 f32_i32_rd.tv
     600     1800    12600 f32_i32_rne.tv
     600     1800    12600 f32_i32_ru.tv
     600     1800    12600 f32_i32_rz.tv
     600     1800    17400 f32_i64_rd.tv
     600     1800    17400 f32_i64_rne.tv
     600     1800    17400 f32_i64_ru.tv
     600     1800    17400 f32_i64_rz.tv
   46464    46464  1393920 f32_mul_rd.tv
   46464    46464  1393920 f32_mul_rne.tv
   46464    46464  1393920 f32_mul_ru.tv
   46464    46464  1393920 f32_mul_rz.tv
     600     1800    12600 f32_sqrt_rd.tv
     600     1800    12600 f32_sqrt_rne.tv
     600     1800    12600 f32_sqrt_ru.tv
     600     1800    12600 f32_sqrt_rz.tv
   46464   185856  1393920 f32_sub_rd.tv
   46464   185856  1393920 f32_sub_rne.tv
   46464   185856  1393920 f32_sub_ru.tv
   46464   185856  1393920 f32_sub_rz.tv
     600     1800    12600 f32_ui32_rd.tv
     600     1800    12600 f32_ui32_rne.tv
     600     1800    12600 f32_ui32_ru.tv
     600     1800    12600 f32_ui32_rz.tv
     600     1800    17400 f32_ui64_rd.tv
     600     1800    17400 f32_ui64_rne.tv
     600     1800    17400 f32_ui64_ru.tv
     600     1800    17400 f32_ui64_rz.tv
   46464   185856  2509056 f64_add_rd.tv
   46464   185856  2509056 f64_add_rne.tv
   46464   185856  2509056 f64_add_ru.tv
   46464   185856  2509056 f64_add_rz.tv
   46464   185856  1812096 f64_cmp_eq_signaling.tv
   46464   185856  1812096 f64_cmp_eq.tv
   46464   185856  1812096 f64_cmp_le_quiet.tv
   46464   185856  1812096 f64_cmp_le.tv
   46464   185856  1812096 f64_cmp_lt_quiet.tv
   46464   185856  1812096 f64_cmp_lt.tv
   46464   185856  2509056 f64_div_rd.tv
   46464   185856  2509056 f64_div_rne.tv
   46464   185856  2509056 f64_div_ru.tv
   46464   185856  2509056 f64_div_rz.tv
     768     2304    22272 f64_f32_rd.tv
     768     2304    22272 f64_f32_rne.tv
     768     2304    22272 f64_f32_ru.tv
     768     2304    22272 f64_f32_rz.tv
     768     2304    22272 f64_i32_rd.tv
     768     2304    22272 f64_i32_rne.tv
     768     2304    22272 f64_i32_ru.tv
     768     2304    22272 f64_i32_rz.tv
     768     2304    28416 f64_i64_rd.tv
     768     2304    28416 f64_i64_rne.tv
     768     2304    28416 f64_i64_ru.tv
     768     2304    28416 f64_i64_rz.tv
   46464   185856  2509056 f64_mul_rd.tv
   46464   185856  2509056 f64_mul_rne.tv
   46464   185856  2509056 f64_mul_ru.tv
   46464   185856  2509056 f64_mul_rz.tv
     768     2304    28416 f64_sqrt_rd.tv
     768     2304    28416 f64_sqrt_rne.tv
     768     2304    28416 f64_sqrt_ru.tv
     768     2304    28416 f64_sqrt_rz.tv
   46464   185856  2509056 f64_sub_rd.tv
   46464   185856  2509056 f64_sub_rne.tv
   46464   185856  2509056 f64_sub_ru.tv
   46464   185856  2509056 f64_sub_rz.tv
     768     2304    22272 f64_ui32_rd.tv
     768     2304    22272 f64_ui32_rne.tv
     768     2304    22272 f64_ui32_ru.tv
     768     2304    22272 f64_ui32_rz.tv
     768     2304    28416 f64_ui64_rd.tv
     768     2304    28416 f64_ui64_rne.tv
     768     2304    28416 f64_ui64_ru.tv
     768     2304    28416 f64_ui64_rz.tv
     372     1116     7812 i32_f32_rd.tv
     372     1116     7812 i32_f32_rne.tv
     372     1116     7812 i32_f32_ru.tv
     372     1116     7812 i32_f32_rz.tv
     372     1116    10788 i32_f64_rd.tv
     372     1116    10788 i32_f64_rne.tv
     372     1116    10788 i32_f64_ru.tv
     372     1116    10788 i32_f64_rz.tv
     756     2268    21924 i64_f32_rd.tv
     756     2268    21924 i64_f32_rne.tv
     756     2268    21924 i64_f32_ru.tv
     756     2268    21924 i64_f32_rz.tv
     756     2268    27972 i64_f64_rd.tv
     756     2268    27972 i64_f64_rne.tv
     756     2268    27972 i64_f64_ru.tv
     756     2268    27972 i64_f64_rz.tv
     372     1116     7812 ui32_f32_rd.tv
     372     1116     7812 ui32_f32_rne.tv
     372     1116     7812 ui32_f32_ru.tv
     372     1116     7812 ui32_f32_rz.tv
     372     1116    10788 ui32_f64_rd.tv
     372     1116    10788 ui32_f64_rne.tv
     372     1116    10788 ui32_f64_ru.tv
     372     1116    10788 ui32_f64_rz.tv
     756     2268    21924 ui64_f32_rd.tv
     756     2268    21924 ui64_f32_rne.tv
     756     2268    21924 ui64_f32_ru.tv
     756     2268    21924 ui64_f32_rz.tv
     756     2268    27972 ui64_f64_rd.tv
     756     2268    27972 ui64_f64_rne.tv
     756     2268    27972 ui64_f64_ru.tv
     756     2268    27972 ui64_f64_rz.tv
 2654496 10007904 91305888 total
