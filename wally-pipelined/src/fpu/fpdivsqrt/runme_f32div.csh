#!/bin/sh
vsim -do f32_div_rne.do -c
vsim -do f32_div_rz.do -c
vsim -do f32_div_rd.do -c
vsim -do f32_div_ru.do -c
