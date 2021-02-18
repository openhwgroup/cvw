onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/reset
add wave -noupdate -divider <NULL>
add wave -noupdate /testbench/dut/hart/ebu/IReadF
add wave -noupdate -group HDU /testbench/dut/hart/DataStall
add wave -noupdate -group HDU /testbench/dut/hart/InstrStall
add wave -noupdate -group HDU /testbench/dut/hart/StallF
add wave -noupdate -group HDU /testbench/dut/hart/StallD
add wave -noupdate -group HDU /testbench/dut/hart/FlushD
add wave -noupdate -group HDU /testbench/dut/hart/FlushE
add wave -noupdate -group HDU /testbench/dut/hart/FlushM
add wave -noupdate -group HDU /testbench/dut/hart/FlushW
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
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {72 ns} 0}
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
WaveRestoreZoom {0 ns} {329 ns}
