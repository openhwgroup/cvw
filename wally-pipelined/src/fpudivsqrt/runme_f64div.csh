#!/bin/sh
vsim -do f64_div_rne.do -c
vsim -do f64_div_rz.do -c
vsim -do f64_div_rd.do -c
vsim -do f64_div_ru.do -c
