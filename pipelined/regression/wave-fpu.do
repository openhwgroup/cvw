
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
add wave -noupdate /testbenchfp/divsqrt/srtfsm/state
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
add wave -group {Divide} -noupdate /testbenchfp/divsqrt/srt/WC
add wave -group {Divide} -noupdate /testbenchfp/divsqrt/srt/WS
add wave -group {Divide} -noupdate /testbenchfp/divsqrt/srt/WCA
add wave -group {Divide} -noupdate /testbenchfp/divsqrt/srt/WSA
add wave -group {Divide} -noupdate /testbenchfp/divsqrt/srt/Q
add wave -group {Divide} -noupdate /testbenchfp/divsqrt/srt/QM
add wave -group {Divide} -noupdate /testbenchfp/divsqrt/srt/QNext
add wave -group {Divide} -noupdate /testbenchfp/divsqrt/srt/QMNext
add wave -group {Divide} -noupdate /testbenchfp/divsqrt/srt/*
add wave -group {Divide} -group inter0 -noupdate /testbenchfp/divsqrt/srt/interations[0]/divinteration/*
# add wave -group {Divide} -group inter0 -noupdate /testbenchfp/divsqrt/srt/interations[0]/divinteration/otfc/otfc2/*
# add wave -group {Divide} -group inter0 -noupdate /testbenchfp/divsqrt/srt/interations[0]/divinteration/qsel/qsel2/*
add wave -group {Divide} -group inter0 -noupdate /testbenchfp/divsqrt/srt/interations[0]/divinteration/genblk1/qsel4/*
add wave -group {Divide} -noupdate /testbenchfp/divsqrt/srtpreproc/*
add wave -group {Divide} -noupdate /testbenchfp/divsqrt/srtpreproc/expcalc/*
add wave -group {Divide} -noupdate /testbenchfp/divsqrt/srtfsm/*
add wave -group {Testbench} -noupdate /testbenchfp/*
add wave -group {Testbench} -noupdate /testbenchfp/readvectors/*
