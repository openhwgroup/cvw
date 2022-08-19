#!/bin/sh
vsim -do iter32S.do -c
vsim -do iter32.do -c
vsim -do iter64.do -c
vsim -do iter64S.do -c
vsim -do iter128.do -c
vsim -do iter128S.do -c

