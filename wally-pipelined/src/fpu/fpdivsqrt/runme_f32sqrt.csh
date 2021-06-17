#!/bin/sh
vsim -do f32_sqrt_rne.do -c
vsim -do f32_sqrt_rz.do -c
vsim -do f32_sqrt_rd.do -c
vsim -do f32_sqrt_ru.do -c
