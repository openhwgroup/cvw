
add wave -noupdate /testbenchfp/clk
add wave -noupdate -radix decimal /testbenchfp/VectorNum
add wave -noupdate /testbenchfp/FrmNum
add wave -noupdate /testbenchfp/X
add wave -noupdate /testbenchfp/Y
add wave -noupdate /testbenchfp/Z
add wave -noupdate /testbenchfp/Res
add wave -noupdate /testbenchfp/Ans
add wave -noupdate /testbenchfp/DivStart
add wave -noupdate /testbenchfp/FDivBusyE
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/postprocess/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/postprocess/specialcase/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/postprocess/flags/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/postprocess/normshift/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/postprocess/shiftcorrection/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/postprocess/resultsign/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/postprocess/round/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/postprocess/fmashiftcalc/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/postprocess/divshiftcalc/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/postprocess/cvtshiftcalc/*
add wave -group {Testbench} -noupdate /testbenchfp/*
add wave -group {Testbench} -noupdate /testbenchfp/readvectors/*
