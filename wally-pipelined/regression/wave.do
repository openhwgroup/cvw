onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/reset
add wave -noupdate -radix ascii /testbench/memfilename
add wave -noupdate -divider <NULL>
add wave -noupdate /testbench/dut/hart/ebu/IReadF
add wave -noupdate -expand -group HDU /testbench/dut/hart/DataStall
add wave -noupdate -expand -group HDU /testbench/dut/hart/InstrStall
add wave -noupdate -expand -group HDU -color Yellow /testbench/dut/hart/hzu/FlushF
add wave -noupdate -expand -group HDU -color Yellow /testbench/dut/hart/FlushD
add wave -noupdate -expand -group HDU -color Yellow /testbench/dut/hart/FlushE
add wave -noupdate -expand -group HDU -color Yellow /testbench/dut/hart/FlushM
add wave -noupdate -expand -group HDU -color Yellow /testbench/dut/hart/FlushW
add wave -noupdate -expand -group HDU -color Orange /testbench/dut/hart/StallF
add wave -noupdate -expand -group HDU -color Orange /testbench/dut/hart/StallD
add wave -noupdate -expand -group Bpred -expand -group direction -divider Update
add wave -noupdate -expand -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/DirPredictor/UpdatePC
add wave -noupdate -expand -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/DirPredictor/UpdateEN
add wave -noupdate -expand -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/DirPredictor/UpdatePCIndex
add wave -noupdate -expand -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/DirPredictor/UpdatePrediction
add wave -noupdate -expand -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/DirPredictor/memory/memory
add wave -noupdate -expand -group InstrClass /testbench/dut/hart/ifu/bpred/InstrClassF
add wave -noupdate -expand -group InstrClass /testbench/dut/hart/ifu/bpred/InstrClassD
add wave -noupdate -expand -group InstrClass /testbench/dut/hart/ifu/bpred/InstrClassE
add wave -noupdate /testbench/dut/hart/ifu/bpred/InstrF
add wave -noupdate /testbench/dut/hart/ifu/bpred/BPPredWrongE
add wave -noupdate /testbench/dut/hart/ifu/PCNextF
add wave -noupdate /testbench/dut/hart/ifu/PCF
add wave -noupdate /testbench/dut/hart/ifu/PCPlus2or4F
add wave -noupdate /testbench/dut/hart/ifu/PCNext0F
add wave -noupdate /testbench/dut/hart/ifu/PCNext1F
add wave -noupdate /testbench/dut/hart/ifu/SelBPPredF
add wave -noupdate /testbench/dut/hart/ifu/bpred/BTBValidF
add wave -noupdate /testbench/dut/hart/ifu/bpred/BPPredF
add wave -noupdate /testbench/dut/hart/ifu/bpred/TargetPredictor/ValidBits
add wave -noupdate /testbench/dut/hart/ifu/bpred/TargetPredictor/LookUpPCIndexQ
add wave -noupdate /testbench/dut/hart/ifu/bpred/TargetPredictor/UpdatePCIndexQ
add wave -noupdate /testbench/dut/hart/ifu/bpred/TargetPredictor/LookUpPC
add wave -noupdate -expand -group {bp wrong} /testbench/dut/hart/ifu/bpred/TargetWrongE
add wave -noupdate -expand -group {bp wrong} /testbench/dut/hart/ifu/bpred/FallThroughWrongE
add wave -noupdate -expand -group {bp wrong} /testbench/dut/hart/ifu/bpred/PredictionDirWrongE
add wave -noupdate -expand -group {bp wrong} /testbench/dut/hart/ifu/bpred/PredictionPCWrongE
add wave -noupdate -expand -group {bp wrong} /testbench/dut/hart/ifu/bpred/BPPredWrongE
add wave -noupdate -expand -group BTB -divider Update
add wave -noupdate -expand -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/UpdateEN
add wave -noupdate -expand -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/UpdatePC
add wave -noupdate -expand -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/UpdateTarget
add wave -noupdate -expand -group {Execution Stage} /testbench/dut/hart/ifu/PCE
add wave -noupdate -expand -group {Execution Stage} /testbench/dut/hart/ifu/InstrE
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {137177 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 250
configure wave -valuecolwidth 185
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {136946 ns} {137442 ns}
