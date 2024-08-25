james.stine@okstate.edu 14 Jan 2022

These are the testvectors (TV) to test the floating-point unit using
Berkeley TestFloat written originally by John Hauser.  TestFloat
requires both TestFloat and SoftFloat.

The locations of these tools at time of this README is found here:
TestFloat-3e:  http://www.jhauser.us/arithmetic/TestFloat.html
SoftFloat-3e:  http://www.jhauser.us/arithmetic/SoftFloat.html

These tools have been compiled on a x86_64 environment by going into
their respective build/Linux-x86_64-GCC directories and running make.

The makefile in the vectors subdirectory of this directory will generate TV
for each rounding mode and operation. It also puts an underscore between each
vector instead of a space to allow SystemVerilog readmemh to read correctly.

The makefile at the top level of this directory will compile SoftFloat and
TestFloat and then generate all of the TVs. It also generates TVs for the
combined integer floating-point divider.

Although not needed, a case.sh script is included to change the case
of the hex output.  This is for those that do not like to see
hexadecimal capitalized :P.

      46464   185856   836352 f16_add_rd.tv
      46464   185856   836352 f16_add_rne.tv
      46464   185856   836352 f16_add_ru.tv
      46464   185856   836352 f16_add_rz.tv
      46464   185856   836352 f16_div_rd.tv
      46464   185856   836352 f16_div_rne.tv
      46464   185856   836352 f16_div_ru.tv
      46464   185856   836352 f16_div_rz.tv
      46464   185856   836352 f16_mul_rd.tv
      46464   185856   836352 f16_mul_rne.tv
      46464   185856   836352 f16_mul_ru.tv
      46464   185856   836352 f16_mul_rz.tv
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
      46464   185856  1393920 f32_mul_rd.tv
      46464   185856  1393920 f32_mul_rne.tv
      46464   185856  1393920 f32_mul_ru.tv
      46464   185856  1393920 f32_mul_rz.tv
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
    2840352 11308896 94651296 total

