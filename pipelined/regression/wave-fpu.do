
add wave -noupdate /testbenchfp/clk
add wave -noupdate -radix decimal /testbenchfp/VectorNum
add wave -noupdate /testbenchfp/FrmNum
add wave -noupdate /testbenchfp/X
add wave -noupdate /testbenchfp/Y
add wave -noupdate /testbenchfp/Z
add wave -noupdate /testbenchfp/Res
add wave -noupdate /testbenchfp/Ans
add wave -noupdate /testbenchfp/DivStart
add wave -noupdate /testbenchfp/DivBusy
add wave -noupdate /testbenchfp/srtfsm/state
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/resultselect/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/flags/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/normshift/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/lzacorrection/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/resultsign/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/round/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/fmashiftcalc/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/divshiftcalc/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/cvtshiftcalc/*
add wave -group {Divide} -noupdate /testbenchfp/srtradix4/*
add wave -group {Divide} -noupdate /testbenchfp/srtradix4/qsel4/*
add wave -group {Divide} -noupdate /testbenchfp/srtradix4/otfc4/*
add wave -group {Divide} -noupdate /testbenchfp/srtpreproc/*
add wave -group {Divide} -noupdate /testbenchfp/srtradix4/expcalc/*
add wave -group {Divide} -noupdate /testbenchfp/srtfsm/*
add wave -group {Testbench} -noupdate /testbenchfp/*
add wave -group {Testbench} -noupdate /testbenchfp/readvectors/*
