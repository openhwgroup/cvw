#!/bin/sh
BUILD="../../addins/TestFloat-3e/build/Linux-x86_64-GCC"
OUTPUT="./vectors"
echo "Editing ui32_to_f16 test vectors"
sed -ie 's/$/_0_2_2/' $OUTPUT/ui32_to_f16_rne.tv
sed -ie 's/$/_1_2_2/' $OUTPUT/ui32_to_f16_rz.tv
sed -ie 's/$/_3_2_2/' $OUTPUT/ui32_to_f16_ru.tv
sed -ie 's/$/_2_2_2/' $OUTPUT/ui32_to_f16_rd.tv
sed -ie 's/$/_4_2_2/' $OUTPUT/ui32_to_f16_rnm.tv
echo "Editing ui32_to_f32 test vectors"
sed -ie 's/$/_0_0_2/' $OUTPUT/ui32_to_f32_rne.tv
sed -ie 's/$/_1_0_2/' $OUTPUT/ui32_to_f32_rz.tv
sed -ie 's/$/_3_0_2/' $OUTPUT/ui32_to_f32_ru.tv
sed -ie 's/$/_2_0_2/' $OUTPUT/ui32_to_f32_rd.tv
sed -ie 's/$/_4_0_2/' $OUTPUT/ui32_to_f32_rnm.tv
echo "Editing ui32_to_f64 test vectors"
sed -ie 's/$/_0_1_2/' $OUTPUT/ui32_to_f64_rne.tv
sed -ie 's/$/_1_1_2/' $OUTPUT/ui32_to_f64_rz.tv
sed -ie 's/$/_3_1_2/' $OUTPUT/ui32_to_f64_ru.tv
sed -ie 's/$/_2_1_2/' $OUTPUT/ui32_to_f64_rd.tv
sed -ie 's/$/_4_1_2/' $OUTPUT/ui32_to_f64_rnm.tv
echo "Editing ui32_to_f128 test vectors"
sed -ie 's/$/_0_3_2/' $OUTPUT/ui32_to_f128_rne.tv
sed -ie 's/$/_1_3_2/' $OUTPUT/ui32_to_f128_rz.tv
sed -ie 's/$/_3_3_2/' $OUTPUT/ui32_to_f128_ru.tv
sed -ie 's/$/_2_3_2/' $OUTPUT/ui32_to_f128_rd.tv
sed -ie 's/$/_4_3_2/' $OUTPUT/ui32_to_f128_rnm.tv
echo "Editing ui64_to_f16 test vectors"
sed -ie 's/$/_0_2_6/' $OUTPUT/ui64_to_f16_rne.tv
sed -ie 's/$/_1_2_6/' $OUTPUT/ui64_to_f16_rz.tv
sed -ie 's/$/_3_2_6/' $OUTPUT/ui64_to_f16_ru.tv
sed -ie 's/$/_2_2_6/' $OUTPUT/ui64_to_f16_rd.tv
sed -ie 's/$/_4_2_6/' $OUTPUT/ui64_to_f16_rnm.tv
echo "Editing ui64_to_f32 test vectors"
sed -ie 's/$/_0_0_6/' $OUTPUT/ui64_to_f32_rne.tv
sed -ie 's/$/_1_0_6/' $OUTPUT/ui64_to_f32_rz.tv
sed -ie 's/$/_3_0_6/' $OUTPUT/ui64_to_f32_ru.tv
sed -ie 's/$/_2_0_6/' $OUTPUT/ui64_to_f32_rd.tv
sed -ie 's/$/_4_0_6/' $OUTPUT/ui64_to_f32_rnm.tv
echo "Editing ui64_to_f64 test vectors"
sed -ie 's/$/_0_1_6/' $OUTPUT/ui64_to_f64_rne.tv
sed -ie 's/$/_1_1_6/' $OUTPUT/ui64_to_f64_rz.tv
sed -ie 's/$/_3_1_6/' $OUTPUT/ui64_to_f64_ru.tv
sed -ie 's/$/_2_1_6/' $OUTPUT/ui64_to_f64_rd.tv
sed -ie 's/$/_4_1_6/' $OUTPUT/ui64_to_f64_rnm.tv
echo "Editing ui64_to_f128 test vectors"
sed -ie 's/$/_0_3_6/' $OUTPUT/ui64_to_f128_rne.tv
sed -ie 's/$/_1_3_6/' $OUTPUT/ui64_to_f128_rz.tv
sed -ie 's/$/_3_3_6/' $OUTPUT/ui64_to_f128_ru.tv
sed -ie 's/$/_2_3_6/' $OUTPUT/ui64_to_f128_rd.tv
sed -ie 's/$/_4_3_6/' $OUTPUT/ui64_to_f128_rnm.tv
echo "Editing i32_to_f16 test vectors"
sed -ie 's/$/_0_2_0/' $OUTPUT/i32_to_f16_rne.tv
sed -ie 's/$/_1_2_0/' $OUTPUT/i32_to_f16_rz.tv
sed -ie 's/$/_3_2_0/' $OUTPUT/i32_to_f16_ru.tv
sed -ie 's/$/_2_2_0/' $OUTPUT/i32_to_f16_rd.tv
sed -ie 's/$/_4_2_0/' $OUTPUT/i32_to_f16_rnm.tv
echo "Editing i32_to_f32 test vectors"
sed -ie 's/$/_0_0_0/' $OUTPUT/i32_to_f32_rne.tv
sed -ie 's/$/_1_0_0/' $OUTPUT/i32_to_f32_rz.tv
sed -ie 's/$/_3_0_0/' $OUTPUT/i32_to_f32_ru.tv
sed -ie 's/$/_2_0_0/' $OUTPUT/i32_to_f32_rd.tv
sed -ie 's/$/_4_0_0/' $OUTPUT/i32_to_f32_rnm.tv
echo "Editing i32_to_f64 test vectors"
sed -ie 's/$/_0_1_0/' $OUTPUT/i32_to_f64_rne.tv
sed -ie 's/$/_1_1_0/' $OUTPUT/i32_to_f64_rz.tv
sed -ie 's/$/_3_1_0/' $OUTPUT/i32_to_f64_ru.tv
sed -ie 's/$/_2_1_0/' $OUTPUT/i32_to_f64_rd.tv
sed -ie 's/$/_4_1_0/' $OUTPUT/i32_to_f64_rnm.tv
echo "Editing i32_to_f128 test vectors"
sed -ie 's/$/_0_3_0/' $OUTPUT/i32_to_f128_rne.tv
sed -ie 's/$/_1_3_0/' $OUTPUT/i32_to_f128_rz.tv
sed -ie 's/$/_3_3_0/' $OUTPUT/i32_to_f128_ru.tv
sed -ie 's/$/_2_3_0/' $OUTPUT/i32_to_f128_rd.tv
sed -ie 's/$/_4_3_0/' $OUTPUT/i32_to_f128_rnm.tv
echo "Editing i64_to_f16 test vectors"
sed -ie 's/$/_0_2_4/' $OUTPUT/i64_to_f16_rne.tv
sed -ie 's/$/_1_2_4/' $OUTPUT/i64_to_f16_rz.tv
sed -ie 's/$/_3_2_4/' $OUTPUT/i64_to_f16_ru.tv
sed -ie 's/$/_2_2_4/' $OUTPUT/i64_to_f16_rd.tv
sed -ie 's/$/_4_2_4/' $OUTPUT/i64_to_f16_rnm.tv
echo "Editing i64_to_f32 test vectors"
sed -ie 's/$/_0_0_4/' $OUTPUT/i64_to_f32_rne.tv
sed -ie 's/$/_1_0_4/' $OUTPUT/i64_to_f32_rz.tv
sed -ie 's/$/_3_0_4/' $OUTPUT/i64_to_f32_ru.tv
sed -ie 's/$/_2_0_4/' $OUTPUT/i64_to_f32_rd.tv
sed -ie 's/$/_4_0_4/' $OUTPUT/i64_to_f32_rnm.tv
echo "Editing i64_to_f64 test vectors"
sed -ie 's/$/_0_1_4/' $OUTPUT/i64_to_f64_rne.tv
sed -ie 's/$/_1_1_4/' $OUTPUT/i64_to_f64_rz.tv
sed -ie 's/$/_3_1_4/' $OUTPUT/i64_to_f64_ru.tv
sed -ie 's/$/_2_1_4/' $OUTPUT/i64_to_f64_rd.tv
sed -ie 's/$/_4_1_4/' $OUTPUT/i64_to_f64_rnm.tv
echo "Editing i64_to_f128 test vectors"
sed -ie 's/$/_0_3_4/' $OUTPUT/i64_to_f128_rne.tv
sed -ie 's/$/_1_3_4/' $OUTPUT/i64_to_f128_rz.tv
sed -ie 's/$/_3_3_4/' $OUTPUT/i64_to_f128_ru.tv
sed -ie 's/$/_2_3_4/' $OUTPUT/i64_to_f128_rd.tv
sed -ie 's/$/_4_3_4/' $OUTPUT/i64_to_f128_rnm.tv
echo "Editing f16_to_ui32 test vectors"
sed -ie 's/$/_0_2_3/' $OUTPUT/f16_to_ui32_rne.tv
sed -ie 's/$/_1_2_3/' $OUTPUT/f16_to_ui32_rz.tv
sed -ie 's/$/_3_2_3/' $OUTPUT/f16_to_ui32_ru.tv
sed -ie 's/$/_2_2_3/' $OUTPUT/f16_to_ui32_rd.tv
sed -ie 's/$/_4_2_3/' $OUTPUT/f16_to_ui32_rnm.tv
echo "Editing f32_to_ui32 test vectors"
sed -ie 's/$/_0_0_3/' $OUTPUT/f32_to_ui32_rne.tv
sed -ie 's/$/_1_0_3/' $OUTPUT/f32_to_ui32_rz.tv
sed -ie 's/$/_3_0_3/' $OUTPUT/f32_to_ui32_ru.tv
sed -ie 's/$/_2_0_3/' $OUTPUT/f32_to_ui32_rd.tv
sed -ie 's/$/_4_0_3/' $OUTPUT/f32_to_ui32_rnm.tv
echo "Editing f64_to_ui32 test vectors"
sed -ie 's/$/_0_1_3/' $OUTPUT/f64_to_ui32_rne.tv
sed -ie 's/$/_1_1_3/' $OUTPUT/f64_to_ui32_rz.tv
sed -ie 's/$/_3_1_3/' $OUTPUT/f64_to_ui32_ru.tv
sed -ie 's/$/_2_1_3/' $OUTPUT/f64_to_ui32_rd.tv
sed -ie 's/$/_4_1_3/' $OUTPUT/f64_to_ui32_rnm.tv
echo "Editing f128_to_ui32 test vectors"
sed -ie 's/$/_0_3_3/' $OUTPUT/f128_to_ui32_rne.tv
sed -ie 's/$/_1_3_3/' $OUTPUT/f128_to_ui32_rz.tv
sed -ie 's/$/_3_3_3/' $OUTPUT/f128_to_ui32_ru.tv
sed -ie 's/$/_2_3_3/' $OUTPUT/f128_to_ui32_rd.tv
sed -ie 's/$/_4_3_3/' $OUTPUT/f128_to_ui32_rnm.tv
echo "Editing f16_to_ui64 test vectors"
sed -ie 's/$/_0_2_7/' $OUTPUT/f16_to_ui64_rne.tv
sed -ie 's/$/_1_2_7/' $OUTPUT/f16_to_ui64_rz.tv
sed -ie 's/$/_3_2_7/' $OUTPUT/f16_to_ui64_ru.tv
sed -ie 's/$/_2_2_7/' $OUTPUT/f16_to_ui64_rd.tv
sed -ie 's/$/_4_2_7/' $OUTPUT/f16_to_ui64_rnm.tv
echo "Editing f32_to_ui64 test vectors"
sed -ie 's/$/_0_0_7/' $OUTPUT/f32_to_ui64_rne.tv
sed -ie 's/$/_1_0_7/' $OUTPUT/f32_to_ui64_rz.tv
sed -ie 's/$/_3_0_7/' $OUTPUT/f32_to_ui64_ru.tv
sed -ie 's/$/_2_0_7/' $OUTPUT/f32_to_ui64_rd.tv
sed -ie 's/$/_4_0_7/' $OUTPUT/f32_to_ui64_rnm.tv
echo "Editing f64_to_ui64 test vectors"
sed -ie 's/$/_0_1_7/' $OUTPUT/f64_to_ui64_rne.tv
sed -ie 's/$/_1_1_7/' $OUTPUT/f64_to_ui64_rz.tv
sed -ie 's/$/_3_1_7/' $OUTPUT/f64_to_ui64_ru.tv
sed -ie 's/$/_2_1_7/' $OUTPUT/f64_to_ui64_rd.tv
sed -ie 's/$/_4_1_7/' $OUTPUT/f64_to_ui64_rnm.tv
echo "Editing f128_to_ui64 test vectors"
sed -ie 's/$/_0_3_7/' $OUTPUT/f128_to_ui64_rne.tv
sed -ie 's/$/_1_3_7/' $OUTPUT/f128_to_ui64_rz.tv
sed -ie 's/$/_3_3_7/' $OUTPUT/f128_to_ui64_ru.tv
sed -ie 's/$/_2_3_7/' $OUTPUT/f128_to_ui64_rd.tv
sed -ie 's/$/_4_3_7/' $OUTPUT/f128_to_ui64_rnm.tv
echo "Editing f16_to_i32 test vectors"
sed -ie 's/$/_0_2_1/' $OUTPUT/f16_to_i32_rne.tv
sed -ie 's/$/_1_2_1/' $OUTPUT/f16_to_i32_rz.tv
sed -ie 's/$/_3_2_1/' $OUTPUT/f16_to_i32_ru.tv
sed -ie 's/$/_2_2_1/' $OUTPUT/f16_to_i32_rd.tv
sed -ie 's/$/_4_2_1/' $OUTPUT/f16_to_i32_rnm.tv
echo "Editing f32_to_i32 test vectors"
sed -ie 's/$/_0_0_1/' $OUTPUT/f32_to_i32_rne.tv
sed -ie 's/$/_1_0_1/' $OUTPUT/f32_to_i32_rz.tv
sed -ie 's/$/_3_0_1/' $OUTPUT/f32_to_i32_ru.tv
sed -ie 's/$/_2_0_1/' $OUTPUT/f32_to_i32_rd.tv
sed -ie 's/$/_4_0_1/' $OUTPUT/f32_to_i32_rnm.tv
echo "Editing f64_to_i32 test vectors"
sed -ie 's/$/_0_1_1/' $OUTPUT/f64_to_i32_rne.tv
sed -ie 's/$/_1_1_1/' $OUTPUT/f64_to_i32_rz.tv
sed -ie 's/$/_3_1_1/' $OUTPUT/f64_to_i32_ru.tv
sed -ie 's/$/_2_1_1/' $OUTPUT/f64_to_i32_rd.tv
sed -ie 's/$/_4_1_1/' $OUTPUT/f64_to_i32_rnm.tv
echo "Editing f128_to_i32 test vectors"
sed -ie 's/$/_0_3_1/' $OUTPUT/f128_to_i32_rne.tv
sed -ie 's/$/_1_3_1/' $OUTPUT/f128_to_i32_rz.tv
sed -ie 's/$/_3_3_1/' $OUTPUT/f128_to_i32_ru.tv
sed -ie 's/$/_2_3_1/' $OUTPUT/f128_to_i32_rd.tv
sed -ie 's/$/_4_3_1/' $OUTPUT/f128_to_i32_rnm.tv
echo "Editing f16_to_i64 test vectors"
sed -ie 's/$/_0_2_5/' $OUTPUT/f16_to_i64_rne.tv
sed -ie 's/$/_1_2_5/' $OUTPUT/f16_to_i64_rz.tv
sed -ie 's/$/_3_2_5/' $OUTPUT/f16_to_i64_ru.tv
sed -ie 's/$/_2_2_5/' $OUTPUT/f16_to_i64_rd.tv
sed -ie 's/$/_4_2_5/' $OUTPUT/f16_to_i64_rnm.tv
echo "Editing f32_to_i64 test vectors"
sed -ie 's/$/_0_0_5/' $OUTPUT/f32_to_i64_rne.tv
sed -ie 's/$/_1_0_5/' $OUTPUT/f32_to_i64_rz.tv
sed -ie 's/$/_3_0_5/' $OUTPUT/f32_to_i64_ru.tv
sed -ie 's/$/_2_0_5/' $OUTPUT/f32_to_i64_rd.tv
sed -ie 's/$/_4_0_5/' $OUTPUT/f32_to_i64_rnm.tv
echo "Editing f64_to_i64 test vectors"
sed -ie 's/$/_0_1_5/' $OUTPUT/f64_to_i64_rne.tv
sed -ie 's/$/_1_1_5/' $OUTPUT/f64_to_i64_rz.tv
sed -ie 's/$/_3_1_5/' $OUTPUT/f64_to_i64_ru.tv
sed -ie 's/$/_2_1_5/' $OUTPUT/f64_to_i64_rd.tv
sed -ie 's/$/_4_1_5/' $OUTPUT/f64_to_i64_rnm.tv
echo "Editing f128_to_i64 test vectors"
sed -ie 's/$/_0_3_5/' $OUTPUT/f128_to_i64_rne.tv
sed -ie 's/$/_1_3_5/' $OUTPUT/f128_to_i64_rz.tv
sed -ie 's/$/_3_3_5/' $OUTPUT/f128_to_i64_ru.tv
sed -ie 's/$/_2_3_5/' $OUTPUT/f128_to_i64_rd.tv
sed -ie 's/$/_4_3_5/' $OUTPUT/f128_to_i64_rnm.tv
echo "Editing f16_to_f32 test vectors"
sed -ie 's/$/_0_2_2/' $OUTPUT/f16_to_f32_rne.tv
sed -ie 's/$/_1_2_2/' $OUTPUT/f16_to_f32_rz.tv
sed -ie 's/$/_3_2_2/' $OUTPUT/f16_to_f32_ru.tv
sed -ie 's/$/_2_2_2/' $OUTPUT/f16_to_f32_rd.tv
sed -ie 's/$/_4_2_2/' $OUTPUT/f16_to_f32_rnm.tv
echo "Editing f16_to_f64 test vectors"
sed -ie 's/$/_0_2_2/' $OUTPUT/f16_to_f64_rne.tv
sed -ie 's/$/_1_2_2/' $OUTPUT/f16_to_f64_rz.tv
sed -ie 's/$/_3_2_2/' $OUTPUT/f16_to_f64_ru.tv
sed -ie 's/$/_2_2_2/' $OUTPUT/f16_to_f64_rd.tv
sed -ie 's/$/_4_2_2/' $OUTPUT/f16_to_f64_rnm.tv
echo "Editing f16_to_f128 test vectors"
sed -ie 's/$/_0_2_2/' $OUTPUT/f16_to_f128_rne.tv
sed -ie 's/$/_1_2_2/' $OUTPUT/f16_to_f128_rz.tv
sed -ie 's/$/_3_2_2/' $OUTPUT/f16_to_f128_ru.tv
sed -ie 's/$/_2_2_2/' $OUTPUT/f16_to_f128_rd.tv
sed -ie 's/$/_4_2_2/' $OUTPUT/f16_to_f128_rnm.tv
echo "Editing f32_to_f16 test vectors"
sed -ie 's/$/_0_0_0/' $OUTPUT/f32_to_f16_rne.tv
sed -ie 's/$/_1_0_0/' $OUTPUT/f32_to_f16_rz.tv
sed -ie 's/$/_3_0_0/' $OUTPUT/f32_to_f16_ru.tv
sed -ie 's/$/_2_0_0/' $OUTPUT/f32_to_f16_rd.tv
sed -ie 's/$/_4_0_0/' $OUTPUT/f32_to_f16_rnm.tv
echo "Editing f32_to_f64 test vectors"
sed -ie 's/$/_0_0_0/' $OUTPUT/f32_to_f64_rne.tv
sed -ie 's/$/_1_0_0/' $OUTPUT/f32_to_f64_rz.tv
sed -ie 's/$/_3_0_0/' $OUTPUT/f32_to_f64_ru.tv
sed -ie 's/$/_2_0_0/' $OUTPUT/f32_to_f64_rd.tv
sed -ie 's/$/_4_0_0/' $OUTPUT/f32_to_f64_rnm.tv
echo "Editing f32_to_f128 test vectors"
sed -ie 's/$/_0_0_0/' $OUTPUT/f32_to_f128_rne.tv
sed -ie 's/$/_1_0_0/' $OUTPUT/f32_to_f128_rz.tv
sed -ie 's/$/_3_0_0/' $OUTPUT/f32_to_f128_ru.tv
sed -ie 's/$/_2_0_0/' $OUTPUT/f32_to_f128_rd.tv
sed -ie 's/$/_4_0_0/' $OUTPUT/f32_to_f128_rnm.tv
echo "Editing f64_to_f16 test vectors"
sed -ie 's/$/_0_1_1/' $OUTPUT/f64_to_f16_rne.tv
sed -ie 's/$/_1_1_1/' $OUTPUT/f64_to_f16_rz.tv
sed -ie 's/$/_3_1_1/' $OUTPUT/f64_to_f16_ru.tv
sed -ie 's/$/_2_1_1/' $OUTPUT/f64_to_f16_rd.tv
sed -ie 's/$/_4_1_1/' $OUTPUT/f64_to_f16_rnm.tv
echo "Editing f64_to_f32 test vectors"
sed -ie 's/$/_0_1_1/' $OUTPUT/f64_to_f32_rne.tv
sed -ie 's/$/_1_1_1/' $OUTPUT/f64_to_f32_rz.tv
sed -ie 's/$/_3_1_1/' $OUTPUT/f64_to_f32_ru.tv
sed -ie 's/$/_2_1_1/' $OUTPUT/f64_to_f32_rd.tv
sed -ie 's/$/_4_1_1/' $OUTPUT/f64_to_f32_rnm.tv
echo "Editing f64_to_f128 test vectors"
sed -ie 's/$/_0_1_1/' $OUTPUT/f64_to_f128_rne.tv
sed -ie 's/$/_1_1_1/' $OUTPUT/f64_to_f128_rz.tv
sed -ie 's/$/_3_1_1/' $OUTPUT/f64_to_f128_ru.tv
sed -ie 's/$/_2_1_1/' $OUTPUT/f64_to_f128_rd.tv
sed -ie 's/$/_4_1_1/' $OUTPUT/f64_to_f128_rnm.tv
echo "Editing f128_to_f16 test vectors"
sed -ie 's/$/_0_3_3/' $OUTPUT/f128_to_f16_rne.tv
sed -ie 's/$/_1_3_3/' $OUTPUT/f128_to_f16_rz.tv
sed -ie 's/$/_3_3_3/' $OUTPUT/f128_to_f16_ru.tv
sed -ie 's/$/_2_3_3/' $OUTPUT/f128_to_f16_rd.tv
sed -ie 's/$/_4_3_3/' $OUTPUT/f128_to_f16_rnm.tv
echo "Editing f128_to_f32 test vectors"
sed -ie 's/$/_0_3_3/' $OUTPUT/f128_to_f32_rne.tv
sed -ie 's/$/_1_3_3/' $OUTPUT/f128_to_f32_rz.tv
sed -ie 's/$/_3_3_3/' $OUTPUT/f128_to_f32_ru.tv
sed -ie 's/$/_2_3_3/' $OUTPUT/f128_to_f32_rd.tv
sed -ie 's/$/_4_3_3/' $OUTPUT/f128_to_f32_rnm.tv
echo "Editing f128_to_f64 test vectors"
sed -ie 's/$/_0_3_3/' $OUTPUT/f128_to_f64_rne.tv
sed -ie 's/$/_1_3_3/' $OUTPUT/f128_to_f64_rz.tv
sed -ie 's/$/_3_3_3/' $OUTPUT/f128_to_f64_ru.tv
sed -ie 's/$/_2_3_3/' $OUTPUT/f128_to_f64_rd.tv
sed -ie 's/$/_4_3_3/' $OUTPUT/f128_to_f64_rnm.tv
echo "Editing f16_add test vectors"
sed -ie 's/$/_0_2_6/' $OUTPUT/f16_add_rne.tv
sed -ie 's/$/_1_2_6/' $OUTPUT/f16_add_rz.tv
sed -ie 's/$/_3_2_6/' $OUTPUT/f16_add_ru.tv
sed -ie 's/$/_2_2_6/' $OUTPUT/f16_add_rd.tv
sed -ie 's/$/_4_2_6/' $OUTPUT/f16_add_rnm.tv
echo "Editing f32_add test vectors"
sed -ie 's/$/_0_0_6/' $OUTPUT/f32_add_rne.tv
sed -ie 's/$/_1_0_6/' $OUTPUT/f32_add_rz.tv
sed -ie 's/$/_3_0_6/' $OUTPUT/f32_add_ru.tv
sed -ie 's/$/_2_0_6/' $OUTPUT/f32_add_rd.tv
sed -ie 's/$/_4_0_6/' $OUTPUT/f32_add_rnm.tv
echo "Editing f64_add test vectors"
sed -ie 's/$/_0_1_6/' $OUTPUT/f64_add_rne.tv
sed -ie 's/$/_1_1_6/' $OUTPUT/f64_add_rz.tv
sed -ie 's/$/_3_1_6/' $OUTPUT/f64_add_ru.tv
sed -ie 's/$/_2_1_6/' $OUTPUT/f64_add_rd.tv
sed -ie 's/$/_4_1_6/' $OUTPUT/f64_add_rnm.tv
echo "Editing f128_add test vectors"
sed -ie 's/$/_0_3_6/' $OUTPUT/f128_add_rne.tv
sed -ie 's/$/_1_3_6/' $OUTPUT/f128_add_rz.tv
sed -ie 's/$/_3_3_6/' $OUTPUT/f128_add_ru.tv
sed -ie 's/$/_2_3_6/' $OUTPUT/f128_add_rd.tv
sed -ie 's/$/_4_3_6/' $OUTPUT/f128_add_rnm.tv
echo "Editing f16_sub test vectors"
sed -ie 's/$/_0_2_7/' $OUTPUT/f16_sub_rne.tv
sed -ie 's/$/_1_2_7/' $OUTPUT/f16_sub_rz.tv
sed -ie 's/$/_3_2_7/' $OUTPUT/f16_sub_ru.tv
sed -ie 's/$/_2_2_7/' $OUTPUT/f16_sub_rd.tv
sed -ie 's/$/_4_2_7/' $OUTPUT/f16_sub_rnm.tv
echo "Editing f32_sub test vectors"
sed -ie 's/$/_0_0_7/' $OUTPUT/f32_sub_rne.tv
sed -ie 's/$/_1_0_7/' $OUTPUT/f32_sub_rz.tv
sed -ie 's/$/_3_0_7/' $OUTPUT/f32_sub_ru.tv
sed -ie 's/$/_2_0_7/' $OUTPUT/f32_sub_rd.tv
sed -ie 's/$/_4_0_7/' $OUTPUT/f32_sub_rnm.tv
echo "Editing f64_sub test vectors"
sed -ie 's/$/_0_1_7/' $OUTPUT/f64_sub_rne.tv
sed -ie 's/$/_1_1_7/' $OUTPUT/f64_sub_rz.tv
sed -ie 's/$/_3_1_7/' $OUTPUT/f64_sub_ru.tv
sed -ie 's/$/_2_1_7/' $OUTPUT/f64_sub_rd.tv
sed -ie 's/$/_4_1_7/' $OUTPUT/f64_sub_rnm.tv
echo "Editing f128_sub test vectors"
sed -ie 's/$/_0_3_7/' $OUTPUT/f128_sub_rne.tv
sed -ie 's/$/_1_3_7/' $OUTPUT/f128_sub_rz.tv
sed -ie 's/$/_3_3_7/' $OUTPUT/f128_sub_ru.tv
sed -ie 's/$/_2_3_7/' $OUTPUT/f128_sub_rd.tv
sed -ie 's/$/_4_3_7/' $OUTPUT/f128_sub_rnm.tv
echo "Editing f16_mul test vectors"
sed -ie 's/$/_0_2_4/' $OUTPUT/f16_mul_rne.tv
sed -ie 's/$/_1_2_4/' $OUTPUT/f16_mul_rz.tv
sed -ie 's/$/_3_2_4/' $OUTPUT/f16_mul_ru.tv
sed -ie 's/$/_2_2_4/' $OUTPUT/f16_mul_rd.tv
sed -ie 's/$/_4_2_4/' $OUTPUT/f16_mul_rnm.tv
echo "Editing f32_mul test vectors"
sed -ie 's/$/_0_0_4/' $OUTPUT/f32_mul_rne.tv
sed -ie 's/$/_1_0_4/' $OUTPUT/f32_mul_rz.tv
sed -ie 's/$/_3_0_4/' $OUTPUT/f32_mul_ru.tv
sed -ie 's/$/_2_0_4/' $OUTPUT/f32_mul_rd.tv
sed -ie 's/$/_4_0_4/' $OUTPUT/f32_mul_rnm.tv
echo "Editing f64_mul test vectors"
sed -ie 's/$/_0_1_4/' $OUTPUT/f64_mul_rne.tv
sed -ie 's/$/_1_1_4/' $OUTPUT/f64_mul_rz.tv
sed -ie 's/$/_3_1_4/' $OUTPUT/f64_mul_ru.tv
sed -ie 's/$/_2_1_4/' $OUTPUT/f64_mul_rd.tv
sed -ie 's/$/_4_1_4/' $OUTPUT/f64_mul_rnm.tv
echo "Editing f128_mul test vectors"
sed -ie 's/$/_0_3_4/' $OUTPUT/f128_mul_rne.tv
sed -ie 's/$/_1_3_4/' $OUTPUT/f128_mul_rz.tv
sed -ie 's/$/_3_3_4/' $OUTPUT/f128_mul_ru.tv
sed -ie 's/$/_2_3_4/' $OUTPUT/f128_mul_rd.tv
sed -ie 's/$/_4_3_4/' $OUTPUT/f128_mul_rnm.tv
echo "Editing f16_div test vectors"
sed -ie 's/$/_0_2_0/' $OUTPUT/f16_div_rne.tv
sed -ie 's/$/_1_2_0/' $OUTPUT/f16_div_rz.tv
sed -ie 's/$/_3_2_0/' $OUTPUT/f16_div_ru.tv
sed -ie 's/$/_2_2_0/' $OUTPUT/f16_div_rd.tv
sed -ie 's/$/_4_2_0/' $OUTPUT/f16_div_rnm.tv
echo "Editing f32_div test vectors"
sed -ie 's/$/_0_0_0/' $OUTPUT/f32_div_rne.tv
sed -ie 's/$/_1_0_0/' $OUTPUT/f32_div_rz.tv
sed -ie 's/$/_3_0_0/' $OUTPUT/f32_div_ru.tv
sed -ie 's/$/_2_0_0/' $OUTPUT/f32_div_rd.tv
sed -ie 's/$/_4_0_0/' $OUTPUT/f32_div_rnm.tv
echo "Editing f64_div test vectors"
sed -ie 's/$/_0_1_0/' $OUTPUT/f64_div_rne.tv
sed -ie 's/$/_1_1_0/' $OUTPUT/f64_div_rz.tv
sed -ie 's/$/_3_1_0/' $OUTPUT/f64_div_ru.tv
sed -ie 's/$/_2_1_0/' $OUTPUT/f64_div_rd.tv
sed -ie 's/$/_4_1_0/' $OUTPUT/f64_div_rnm.tv
echo "Editing f128_div test vectors"
sed -ie 's/$/_0_3_0/' $OUTPUT/f128_div_rne.tv
sed -ie 's/$/_1_3_0/' $OUTPUT/f128_div_rz.tv
sed -ie 's/$/_3_3_0/' $OUTPUT/f128_div_ru.tv
sed -ie 's/$/_2_3_0/' $OUTPUT/f128_div_rd.tv
sed -ie 's/$/_4_3_0/' $OUTPUT/f128_div_rnm.tv
echo "Editing f16_sqrt test vectors"
sed -ie 's/$/_0_2_1/' $OUTPUT/f16_sqrt_rne.tv
sed -ie 's/$/_1_2_1/' $OUTPUT/f16_sqrt_rz.tv
sed -ie 's/$/_3_2_1/' $OUTPUT/f16_sqrt_ru.tv
sed -ie 's/$/_2_2_1/' $OUTPUT/f16_sqrt_rd.tv
sed -ie 's/$/_4_2_1/' $OUTPUT/f16_sqrt_rnm.tv
echo "Editing f32_sqrt test vectors"
sed -ie 's/$/_0_0_1/' $OUTPUT/f32_sqrt_rne.tv
sed -ie 's/$/_1_0_1/' $OUTPUT/f32_sqrt_rz.tv
sed -ie 's/$/_3_0_1/' $OUTPUT/f32_sqrt_ru.tv
sed -ie 's/$/_2_0_1/' $OUTPUT/f32_sqrt_rd.tv
sed -ie 's/$/_4_0_1/' $OUTPUT/f32_sqrt_rnm.tv
echo "Editing f64_sqrt test vectors"
sed -ie 's/$/_0_1_1/' $OUTPUT/f64_sqrt_rne.tv
sed -ie 's/$/_1_1_1/' $OUTPUT/f64_sqrt_rz.tv
sed -ie 's/$/_3_1_1/' $OUTPUT/f64_sqrt_ru.tv
sed -ie 's/$/_2_1_1/' $OUTPUT/f64_sqrt_rd.tv
sed -ie 's/$/_4_1_1/' $OUTPUT/f64_sqrt_rnm.tv
echo "Editing f128_sqrt test vectors"
sed -ie 's/$/_0_3_1/' $OUTPUT/f128_sqrt_rne.tv
sed -ie 's/$/_1_3_1/' $OUTPUT/f128_sqrt_rz.tv
sed -ie 's/$/_3_3_1/' $OUTPUT/f128_sqrt_ru.tv
sed -ie 's/$/_2_3_1/' $OUTPUT/f128_sqrt_rd.tv
sed -ie 's/$/_4_3_1/' $OUTPUT/f128_sqrt_rnm.tv
echo "Editing f16_eq test vectors"
sed -ie 's/$/_0_2_2/' $OUTPUT/f16_eq_rne.tv
sed -ie 's/$/_1_2_2/' $OUTPUT/f16_eq_rz.tv
sed -ie 's/$/_3_2_2/' $OUTPUT/f16_eq_ru.tv
sed -ie 's/$/_2_2_2/' $OUTPUT/f16_eq_rd.tv
sed -ie 's/$/_4_2_2/' $OUTPUT/f16_eq_rnm.tv
echo "Editing f32_eq test vectors"
sed -ie 's/$/_0_0_2/' $OUTPUT/f32_eq_rne.tv
sed -ie 's/$/_1_0_2/' $OUTPUT/f32_eq_rz.tv
sed -ie 's/$/_3_0_2/' $OUTPUT/f32_eq_ru.tv
sed -ie 's/$/_2_0_2/' $OUTPUT/f32_eq_rd.tv
sed -ie 's/$/_4_0_2/' $OUTPUT/f32_eq_rnm.tv
echo "Editing f64_eq test vectors"
sed -ie 's/$/_0_1_2/' $OUTPUT/f64_eq_rne.tv
sed -ie 's/$/_1_1_2/' $OUTPUT/f64_eq_rz.tv
sed -ie 's/$/_3_1_2/' $OUTPUT/f64_eq_ru.tv
sed -ie 's/$/_2_1_2/' $OUTPUT/f64_eq_rd.tv
sed -ie 's/$/_4_1_2/' $OUTPUT/f64_eq_rnm.tv
echo "Editing f128_eq test vectors"
sed -ie 's/$/_0_3_2/' $OUTPUT/f128_eq_rne.tv
sed -ie 's/$/_1_3_2/' $OUTPUT/f128_eq_rz.tv
sed -ie 's/$/_3_3_2/' $OUTPUT/f128_eq_ru.tv
sed -ie 's/$/_2_3_2/' $OUTPUT/f128_eq_rd.tv
sed -ie 's/$/_4_3_2/' $OUTPUT/f128_eq_rnm.tv
echo "Editing f16_le test vectors"
sed -ie 's/$/_0_2_3/' $OUTPUT/f16_le_rne.tv
sed -ie 's/$/_1_2_3/' $OUTPUT/f16_le_rz.tv
sed -ie 's/$/_3_2_3/' $OUTPUT/f16_le_ru.tv
sed -ie 's/$/_2_2_3/' $OUTPUT/f16_le_rd.tv
sed -ie 's/$/_4_2_3/' $OUTPUT/f16_le_rnm.tv
echo "Editing f32_le test vectors"
sed -ie 's/$/_0_0_3/' $OUTPUT/f32_le_rne.tv
sed -ie 's/$/_1_0_3/' $OUTPUT/f32_le_rz.tv
sed -ie 's/$/_3_0_3/' $OUTPUT/f32_le_ru.tv
sed -ie 's/$/_2_0_3/' $OUTPUT/f32_le_rd.tv
sed -ie 's/$/_4_0_3/' $OUTPUT/f32_le_rnm.tv
echo "Editing f64_le test vectors"
sed -ie 's/$/_0_1_3/' $OUTPUT/f64_le_rne.tv
sed -ie 's/$/_1_1_3/' $OUTPUT/f64_le_rz.tv
sed -ie 's/$/_3_1_3/' $OUTPUT/f64_le_ru.tv
sed -ie 's/$/_2_1_3/' $OUTPUT/f64_le_rd.tv
sed -ie 's/$/_4_1_3/' $OUTPUT/f64_le_rnm.tv
echo "Editing f128_le test vectors"
sed -ie 's/$/_0_3_3/' $OUTPUT/f128_le_rne.tv
sed -ie 's/$/_1_3_3/' $OUTPUT/f128_le_rz.tv
sed -ie 's/$/_3_3_3/' $OUTPUT/f128_le_ru.tv
sed -ie 's/$/_2_3_3/' $OUTPUT/f128_le_rd.tv
sed -ie 's/$/_4_3_3/' $OUTPUT/f128_le_rnm.tv
echo "Editing f16_lt test vectors"
sed -ie 's/$/_0_2_1/' $OUTPUT/f16_lt_rne.tv
sed -ie 's/$/_1_2_1/' $OUTPUT/f16_lt_rz.tv
sed -ie 's/$/_3_2_1/' $OUTPUT/f16_lt_ru.tv
sed -ie 's/$/_2_2_1/' $OUTPUT/f16_lt_rd.tv
sed -ie 's/$/_4_2_1/' $OUTPUT/f16_lt_rnm.tv
echo "Editing f32_lt test vectors"
sed -ie 's/$/_0_0_1/' $OUTPUT/f32_lt_rne.tv
sed -ie 's/$/_1_0_1/' $OUTPUT/f32_lt_rz.tv
sed -ie 's/$/_3_0_1/' $OUTPUT/f32_lt_ru.tv
sed -ie 's/$/_2_0_1/' $OUTPUT/f32_lt_rd.tv
sed -ie 's/$/_4_0_1/' $OUTPUT/f32_lt_rnm.tv
echo "Editing f64_lt test vectors"
sed -ie 's/$/_0_1_1/' $OUTPUT/f64_lt_rne.tv
sed -ie 's/$/_1_1_1/' $OUTPUT/f64_lt_rz.tv
sed -ie 's/$/_3_1_1/' $OUTPUT/f64_lt_ru.tv
sed -ie 's/$/_2_1_1/' $OUTPUT/f64_lt_rd.tv
sed -ie 's/$/_4_1_1/' $OUTPUT/f64_lt_rnm.tv
echo "Editing f128_lt test vectors"
sed -ie 's/$/_0_3_1/' $OUTPUT/f128_lt_rne.tv
sed -ie 's/$/_1_3_1/' $OUTPUT/f128_lt_rz.tv
sed -ie 's/$/_3_3_1/' $OUTPUT/f128_lt_ru.tv
sed -ie 's/$/_2_3_1/' $OUTPUT/f128_lt_rd.tv
sed -ie 's/$/_4_3_1/' $OUTPUT/f128_lt_rnm.tv
echo "Editing f16_mulAdd test vectors"
sed -ie 's/$/_0_2_0/' $OUTPUT/f16_mulAdd_rne.tv
sed -ie 's/$/_1_2_0/' $OUTPUT/f16_mulAdd_rz.tv
sed -ie 's/$/_3_2_0/' $OUTPUT/f16_mulAdd_ru.tv
sed -ie 's/$/_2_2_0/' $OUTPUT/f16_mulAdd_rd.tv
sed -ie 's/$/_4_2_0/' $OUTPUT/f16_mulAdd_rnm.tv
echo "Editing f32_mulAdd test vectors"
sed -ie 's/$/_0_0_0/' $OUTPUT/f32_mulAdd_rne.tv
sed -ie 's/$/_1_0_0/' $OUTPUT/f32_mulAdd_rz.tv
sed -ie 's/$/_3_0_0/' $OUTPUT/f32_mulAdd_ru.tv
sed -ie 's/$/_2_0_0/' $OUTPUT/f32_mulAdd_rd.tv
sed -ie 's/$/_4_0_0/' $OUTPUT/f32_mulAdd_rnm.tv
echo "Editing f64_mulAdd test vectors"
sed -ie 's/$/_0_1_0/' $OUTPUT/f64_mulAdd_rne.tv
sed -ie 's/$/_1_1_0/' $OUTPUT/f64_mulAdd_rz.tv
sed -ie 's/$/_3_1_0/' $OUTPUT/f64_mulAdd_ru.tv
sed -ie 's/$/_2_1_0/' $OUTPUT/f64_mulAdd_rd.tv
sed -ie 's/$/_4_1_0/' $OUTPUT/f64_mulAdd_rnm.tv
echo "Editing f128_mulAdd test vectors"
sed -ie 's/$/_0_3_0/' $OUTPUT/f128_mulAdd_rne.tv
sed -ie 's/$/_1_3_0/' $OUTPUT/f128_mulAdd_rz.tv
sed -ie 's/$/_3_3_0/' $OUTPUT/f128_mulAdd_ru.tv
sed -ie 's/$/_2_3_0/' $OUTPUT/f128_mulAdd_rd.tv
sed -ie 's/$/_4_3_0/' $OUTPUT/f128_mulAdd_rnm.tv
rm vectors/*.tve