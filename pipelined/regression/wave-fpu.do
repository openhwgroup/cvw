
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
add wave -noupdate /testbenchfp/fdivsqrt/fdivsqrt/fdivsqrtfsm/state
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/specialcase/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/flags/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/normshift/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/shiftcorrection/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/resultsign/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/round/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/fmashiftcalc/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/divshiftcalc/*
add wave -group {PostProc} -noupdate /testbenchfp/postprocess/cvtshiftcalc/*
add wave -group {Divide} -noupdate /testbenchfp/fdivsqrt/fdivsqrt/fdivsqrtiter/WC
add wave -group {Divide} -noupdate /testbenchfp/fdivsqrt/fdivsqrt/fdivsqrtiter/WS
add wave -group {Divide} -noupdate /testbenchfp/fdivsqrt/fdivsqrt/fdivsqrtiter/WCA
add wave -group {Divide} -noupdate /testbenchfp/fdivsqrt/fdivsqrt/fdivsqrtiter/WSA
add wave -group {Divide} -noupdate /testbenchfp/fdivsqrt/fdivsqrt/fdivsqrtiter/U
add wave -group {Divide} -noupdate /testbenchfp/fdivsqrt/fdivsqrt/fdivsqrtiter/UM
add wave -group {Divide} -noupdate /testbenchfp/fdivsqrt/fdivsqrt/fdivsqrtiter/UNext
add wave -group {Divide} -noupdate /testbenchfp/fdivsqrt/fdivsqrt/fdivsqrtiter/UMNext
add wave -group {Divide} -noupdate /testbenchfp/fdivsqrt/fdivsqrt/fdivsqrtiter/*
# add wave -group {Divide} -group inter0 -noupdate /testbenchfp/fdivsqrt/fdivsqrt/fdivsqrtiter/interations[0]/stage/fdivsqrtstage/*
# add wave -group {Divide} -group inter0 -noupdate /testbenchfp/fdivsqrt/fdivsqrt/fdivsqrtiter/interations[0]/stage/fdivsqrtstage/otfc/otfc2/*
# add wave -group {Divide} -group inter0 -noupdate /testbenchfp/fdivsqrt/fdivsqrt/fdivsqrtiter/interations[0]/stage/fdivsqrtstage/qsel/qsel2/*
# add wave -group {Divide} -group inter0 -noupdate /testbenchfp/fdivsqrt/fdivsqrt/fdivsqrtiter/interations[0]/fdivsqrtstage/stage/genblk1/qsel4/*
add wave -group {Divide} -noupdate /testbenchfp/fdivsqrt/fdivsqrt/fdivsqrtpreproc/*
add wave -group {Divide} -noupdate /testbenchfp/fdivsqrt/fdivsqrt/fdivsqrtpreproc/expcalc/*
add wave -group {Divide} -noupdate /testbenchfp/fdivsqrt/fdivsqrt/fdivsqrtfsm/*
add wave -group {Sqrt} -noupdate -recursive /testbenchfp/fdivsqrt/fdivsqrt/*
add wave -group {Testbench} -noupdate /testbenchfp/*
add wave -group {Testbench} -noupdate /testbenchfp/readvectors/*
