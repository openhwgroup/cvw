onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/reset
add wave -noupdate -radix ascii /testbench/memfilename
add wave -noupdate -expand -group {Execution Stage} /testbench/dut/hart/ifu/PCE
add wave -noupdate -expand -group {Execution Stage} /testbench/InstrEName
add wave -noupdate -expand -group {Execution Stage} /testbench/dut/hart/ifu/InstrE
add wave -noupdate -divider <NULL>
add wave -noupdate /testbench/dut/hart/ebu/IReadF
add wave -noupdate -expand -group HDU -group hazards /testbench/dut/hart/hzu/BPPredWrongE
add wave -noupdate -expand -group HDU -group hazards /testbench/dut/hart/hzu/CSRWritePendingDEM
add wave -noupdate -expand -group HDU -group hazards /testbench/dut/hart/hzu/RetM
add wave -noupdate -expand -group HDU -group hazards /testbench/dut/hart/hzu/TrapM
add wave -noupdate -expand -group HDU -group hazards /testbench/dut/hart/hzu/LoadStallD
add wave -noupdate -expand -group HDU -group hazards /testbench/dut/hart/hzu/InstrStall
add wave -noupdate -expand -group HDU -group hazards /testbench/dut/hart/hzu/DataStall
add wave -noupdate -expand -group HDU -expand -group Flush -color Yellow /testbench/dut/hart/hzu/FlushF
add wave -noupdate -expand -group HDU -expand -group Flush -color Yellow /testbench/dut/hart/FlushD
add wave -noupdate -expand -group HDU -expand -group Flush -color Yellow /testbench/dut/hart/FlushE
add wave -noupdate -expand -group HDU -expand -group Flush -color Yellow /testbench/dut/hart/FlushM
add wave -noupdate -expand -group HDU -expand -group Flush -color Yellow /testbench/dut/hart/FlushW
add wave -noupdate -expand -group HDU -expand -group Stall -color Orange /testbench/dut/hart/StallF
add wave -noupdate -expand -group HDU -expand -group Stall -color Orange /testbench/dut/hart/StallD
add wave -noupdate -group Bpred -expand -group direction -divider Update
add wave -noupdate -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/DirPredictor/UpdatePC
add wave -noupdate -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/DirPredictor/UpdateEN
add wave -noupdate -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/DirPredictor/UpdatePCIndex
add wave -noupdate -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/DirPredictor/UpdatePrediction
add wave -noupdate -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/DirPredictor/memory/memory
add wave -noupdate -group InstrClass /testbench/dut/hart/ifu/bpred/InstrClassF
add wave -noupdate -group InstrClass /testbench/dut/hart/ifu/bpred/InstrClassD
add wave -noupdate -group InstrClass /testbench/dut/hart/ifu/bpred/InstrClassE
add wave -noupdate -group {instruction pipeline} /testbench/dut/hart/ifu/InstrF
add wave -noupdate -group {instruction pipeline} /testbench/dut/hart/ifu/InstrD
add wave -noupdate -group {instruction pipeline} /testbench/dut/hart/ifu/InstrE
add wave -noupdate -group {instruction pipeline} /testbench/dut/hart/ifu/InstrM
add wave -noupdate /testbench/dut/hart/ifu/bpred/BPPredWrongE
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/PCNextF
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/PCF
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/PCPlus2or4F
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/BPPredPCF
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/PCNext0F
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/PCNext1F
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/SelBPPredF
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/BPPredWrongE
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/PrivilegedChangePCM
add wave -noupdate /testbench/dut/hart/ifu/bpred/TargetPredictor/ValidBits
add wave -noupdate /testbench/dut/hart/ifu/bpred/BPPredF
add wave -noupdate /testbench/dut/hart/ifu/bpred/BTBValidF
add wave -noupdate /testbench/dut/hart/ifu/bpred/TargetPredictor/LookUpPCIndexQ
add wave -noupdate /testbench/dut/hart/ifu/bpred/TargetPredictor/UpdatePCIndexQ
add wave -noupdate /testbench/dut/hart/ifu/bpred/TargetPredictor/LookUpPC
add wave -noupdate -group {bp wrong} /testbench/dut/hart/ifu/bpred/TargetWrongE
add wave -noupdate -group {bp wrong} /testbench/dut/hart/ifu/bpred/FallThroughWrongE
add wave -noupdate -group {bp wrong} /testbench/dut/hart/ifu/bpred/PredictionDirWrongE
add wave -noupdate -group {bp wrong} /testbench/dut/hart/ifu/bpred/PredictionPCWrongE
add wave -noupdate -group {bp wrong} /testbench/dut/hart/ifu/bpred/BPPredWrongE
add wave -noupdate -group {bp wrong} /testbench/dut/hart/ifu/bpred/InstrClassE
add wave -noupdate -group BTB -divider Update
add wave -noupdate -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/UpdateEN
add wave -noupdate -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/UpdatePC
add wave -noupdate -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/UpdateTarget
add wave -noupdate -group BTB -divider Lookup
add wave -noupdate -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/TargetPC
add wave -noupdate -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/Valid
add wave -noupdate /testbench/dut/hart/ifu/bpred/BTBPredPCF
add wave -noupdate /testbench/dut/hart/ifu/bpred/TargetPredictor/TargetPC
add wave -noupdate /testbench/dut/hart/ifu/bpred/CorrectPCE
add wave -noupdate /testbench/dut/hart/ifu/bpred/FlushF
add wave -noupdate /testbench/dut/hart/FlushF
add wave -noupdate -expand -group RegFile /testbench/dut/hart/ieu/dp/regf/rf
add wave -noupdate -expand -group RegFile /testbench/dut/hart/ieu/dp/regf/a1
add wave -noupdate -expand -group RegFile /testbench/dut/hart/ieu/dp/regf/a2
add wave -noupdate -expand -group RegFile /testbench/dut/hart/ieu/dp/regf/a3
add wave -noupdate -expand -group RegFile /testbench/dut/hart/ieu/dp/regf/rd1
add wave -noupdate -expand -group RegFile /testbench/dut/hart/ieu/dp/regf/rd2
add wave -noupdate -expand -group RegFile /testbench/dut/hart/ieu/dp/regf/we3
add wave -noupdate -expand -group RegFile /testbench/dut/hart/ieu/dp/regf/wd3
add wave -noupdate -expand -group RegFile -group {write regfile mux} /testbench/dut/hart/ieu/dp/ALUResultW
add wave -noupdate -expand -group RegFile -group {write regfile mux} /testbench/dut/hart/ieu/dp/ReadDataW
add wave -noupdate -expand -group RegFile -group {write regfile mux} /testbench/dut/hart/ieu/dp/PCLinkW
add wave -noupdate -expand -group RegFile -group {write regfile mux} /testbench/dut/hart/ieu/dp/CSRReadValW
add wave -noupdate -expand -group RegFile -group {write regfile mux} /testbench/dut/hart/ieu/dp/ResultSrcW
add wave -noupdate -expand -group RegFile -group {write regfile mux} /testbench/dut/hart/ieu/dp/ResultW
add wave -noupdate /testbench/dut/hart/ieu/c/RegWriteE
add wave -noupdate -group {Decode Stage} /testbench/dut/hart/ifu/InstrD
add wave -noupdate -group {Decode Stage} /testbench/InstrDName
add wave -noupdate -group {Decode Stage} /testbench/dut/hart/ieu/c/RegWriteD
add wave -noupdate -group {Decode Stage} /testbench/dut/hart/ieu/dp/RdD
add wave -noupdate -group {Decode Stage} /testbench/dut/hart/ieu/dp/Rs1D
add wave -noupdate -group {Decode Stage} /testbench/dut/hart/ieu/dp/Rs2D
add wave -noupdate /testbench/InstrFName
add wave -noupdate -expand -group dcache /testbench/dut/hart/MemAdrM
add wave -noupdate -expand -group dcache /testbench/dut/hart/MemPAdrM
add wave -noupdate -expand -group dcache /testbench/dut/hart/WriteDataM
add wave -noupdate -expand -group dcache /testbench/dut/hart/ReadDataM
add wave -noupdate -expand -group dcache /testbench/dut/hart/dmem/MemRWM
add wave -noupdate -group Forward /testbench/dut/hart/ieu/fw/Rs1D
add wave -noupdate -group Forward /testbench/dut/hart/ieu/fw/Rs2D
add wave -noupdate -group Forward /testbench/dut/hart/ieu/fw/Rs1E
add wave -noupdate -group Forward /testbench/dut/hart/ieu/fw/Rs2E
add wave -noupdate -group Forward /testbench/dut/hart/ieu/fw/RdE
add wave -noupdate -group Forward /testbench/dut/hart/ieu/fw/RdM
add wave -noupdate -group Forward /testbench/dut/hart/ieu/fw/RdW
add wave -noupdate -group Forward /testbench/dut/hart/ieu/fw/MemReadE
add wave -noupdate -group Forward /testbench/dut/hart/ieu/fw/RegWriteM
add wave -noupdate -group Forward /testbench/dut/hart/ieu/fw/RegWriteW
add wave -noupdate -group Forward -color Thistle /testbench/dut/hart/ieu/fw/ForwardAE
add wave -noupdate -group Forward -color Thistle /testbench/dut/hart/ieu/fw/ForwardBE
add wave -noupdate -group Forward -color Thistle /testbench/dut/hart/ieu/fw/LoadStallD
add wave -noupdate -expand -group {alu execution stage} /testbench/dut/hart/ieu/dp/WriteDataE
add wave -noupdate -expand -group {alu execution stage} /testbench/dut/hart/ieu/dp/ALUResultE
add wave -noupdate -expand -group {alu execution stage} /testbench/dut/hart/ieu/dp/SrcAE
add wave -noupdate -expand -group {alu execution stage} /testbench/dut/hart/ieu/dp/SrcBE
add wave -noupdate /testbench/dut/hart/ieu/dp/ALUResultM
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {231033 ns} 0} {{Cursor 3} {1276133 ns} 0}
quietly wave cursor active 2
configure wave -namecolwidth 250
configure wave -valuecolwidth 518
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
WaveRestoreZoom {1276094 ns} {1276208 ns}
