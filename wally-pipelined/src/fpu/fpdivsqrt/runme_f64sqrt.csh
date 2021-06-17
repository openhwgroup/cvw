#!/bin/sh
vsim -do f64_sqrt_rne.do -c
vsim -do f64_sqrt_rz.do -c
vsim -do f64_sqrt_rd.do -c
vsim -do f64_sqrt_ru.do -c
