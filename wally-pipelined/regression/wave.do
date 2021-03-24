onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/reset
add wave -noupdate /testbench/test
add wave -noupdate -radix ascii /testbench/memfilename
add wave -noupdate -expand -group {Execution Stage} /testbench/FunctionName/FunctionName/FunctionName
add wave -noupdate -expand -group {Execution Stage} /testbench/dut/hart/ifu/PCE
add wave -noupdate -expand -group {Execution Stage} /testbench/InstrEName
add wave -noupdate -expand -group {Execution Stage} /testbench/dut/hart/ifu/InstrE
add wave -noupdate -expand -group HDU -group traps /testbench/dut/hart/priv/trap/InstrMisalignedFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/hart/priv/trap/InstrAccessFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/hart/priv/trap/IllegalInstrFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/hart/priv/trap/BreakpointFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/hart/priv/trap/LoadMisalignedFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/hart/priv/trap/StoreMisalignedFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/hart/priv/trap/LoadAccessFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/hart/priv/trap/StoreAccessFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/hart/priv/trap/EcallFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/hart/priv/trap/InstrPageFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/hart/priv/trap/LoadPageFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/hart/priv/trap/StorePageFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/hart/priv/trap/InterruptM
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
add wave -noupdate -expand -group HDU -expand -group Stall -color Orange /testbench/dut/hart/ifu/StallE
add wave -noupdate -expand -group HDU -expand -group Stall -color Orange /testbench/dut/hart/ifu/StallM
add wave -noupdate -expand -group HDU -expand -group Stall -color Orange /testbench/dut/hart/ifu/StallW
add wave -noupdate -group Bpred -expand -group direction -color Yellow /testbench/dut/hart/ifu/bpred/Predictor/DirPredictor/GHRF
add wave -noupdate -group Bpred -expand -group direction -divider Lookup
add wave -noupdate -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/Predictor/DirPredictor/LookUpPC
add wave -noupdate -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/Predictor/DirPredictor/LookUpPCIndex
add wave -noupdate -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/Predictor/DirPredictor/PredictionMemory
add wave -noupdate -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/Predictor/DirPredictor/Prediction
add wave -noupdate -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/BPPredF
add wave -noupdate -group Bpred -expand -group direction -expand -group output /testbench/dut/hart/ifu/bpred/BPPredPCF
add wave -noupdate -group Bpred -expand -group direction -expand -group output /testbench/dut/hart/ifu/bpred/SelBPPredF
add wave -noupdate -group Bpred -expand -group direction -divider Update
add wave -noupdate -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/Predictor/DirPredictor/UpdatePC
add wave -noupdate -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/Predictor/DirPredictor/UpdatePCIndex
add wave -noupdate -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/Predictor/DirPredictor/UpdateEN
add wave -noupdate -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/Predictor/DirPredictor/UpdatePrediction
add wave -noupdate -group Bpred -expand -group direction -group other /testbench/dut/hart/ifu/bpred/Predictor/DirPredictor/DoForwarding
add wave -noupdate -group Bpred -expand -group direction -group other /testbench/dut/hart/ifu/bpred/Predictor/DirPredictor/DoForwardingF
add wave -noupdate -group Bpred -expand -group direction -group other /testbench/dut/hart/ifu/bpred/Predictor/DirPredictor/GHRD
add wave -noupdate -group Bpred -expand -group direction -group other /testbench/dut/hart/ifu/bpred/Predictor/DirPredictor/GHRE
add wave -noupdate -group Bpred -group {bp wrong} /testbench/dut/hart/ifu/bpred/TargetWrongE
add wave -noupdate -group Bpred -group {bp wrong} /testbench/dut/hart/ifu/bpred/FallThroughWrongE
add wave -noupdate -group Bpred -group {bp wrong} /testbench/dut/hart/ifu/bpred/PredictionDirWrongE
add wave -noupdate -group Bpred -group {bp wrong} /testbench/dut/hart/ifu/bpred/PredictionPCWrongE
add wave -noupdate -group Bpred -group {bp wrong} /testbench/dut/hart/ifu/bpred/BPPredWrongE
add wave -noupdate -group Bpred -group {bp wrong} /testbench/dut/hart/ifu/bpred/InstrClassE
add wave -noupdate -group Bpred -group {bp wrong} -divider pcs
add wave -noupdate -group Bpred -group {bp wrong} /testbench/dut/hart/ifu/bpred/PCD
add wave -noupdate -group Bpred -group {bp wrong} /testbench/dut/hart/ifu/bpred/PCTargetE
add wave -noupdate -group Bpred -expand -group BTB -divider Update
add wave -noupdate -group Bpred -expand -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/UpdateEN
add wave -noupdate -group Bpred -expand -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/UpdatePC
add wave -noupdate -group Bpred -expand -group BTB /testbench/dut/hart/ifu/bpred/InstrClassE
add wave -noupdate -group Bpred -expand -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/UpdateTarget
add wave -noupdate -group Bpred -expand -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/UpdatePCIndexQ
add wave -noupdate -group Bpred -expand -group BTB -divider Lookup
add wave -noupdate -group Bpred -expand -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/TargetPC
add wave -noupdate -group Bpred -expand -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/InstrClass
add wave -noupdate -group Bpred -expand -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/Valid
add wave -noupdate -group Bpred /testbench/dut/hart/ifu/bpred/BPPredWrongE
add wave -noupdate -group Bpred -expand -group RAS /testbench/dut/hart/ifu/bpred/RASPredictor/pop
add wave -noupdate -group Bpred -expand -group RAS /testbench/dut/hart/ifu/bpred/RASPredictor/push
add wave -noupdate -group Bpred -expand -group RAS /testbench/dut/hart/ifu/bpred/RASPredictor/pushPC
add wave -noupdate -group Bpred -expand -group RAS /testbench/dut/hart/ifu/bpred/RASPredictor/PtrD
add wave -noupdate -group Bpred -expand -group RAS /testbench/dut/hart/ifu/bpred/RASPredictor/PtrQ
add wave -noupdate -group Bpred -expand -group RAS /testbench/dut/hart/ifu/bpred/RASPredictor/memory
add wave -noupdate -group Bpred -expand -group RAS /testbench/dut/hart/ifu/bpred/RASPredictor/popPC
add wave -noupdate -expand -group {instruction pipeline} /testbench/dut/hart/ifu/InstrF
add wave -noupdate -expand -group {instruction pipeline} /testbench/dut/hart/ifu/InstrD
add wave -noupdate -expand -group {instruction pipeline} /testbench/dut/hart/ifu/InstrE
add wave -noupdate -expand -group {instruction pipeline} /testbench/dut/hart/ifu/InstrM
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/PCNextF
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/PCF
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/PCPlus2or4F
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/BPPredPCF
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/PCNext0F
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/PCNext1F
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/SelBPPredF
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/BPPredWrongE
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/PrivilegedChangePCM
add wave -noupdate -expand -group {Decode Stage} /testbench/dut/hart/ifu/InstrD
add wave -noupdate -expand -group {Decode Stage} /testbench/InstrDName
add wave -noupdate -expand -group {Decode Stage} /testbench/dut/hart/ieu/c/RegWriteD
add wave -noupdate -expand -group {Decode Stage} /testbench/dut/hart/ieu/dp/RdD
add wave -noupdate -expand -group {Decode Stage} /testbench/dut/hart/ieu/dp/Rs1D
add wave -noupdate -expand -group {Decode Stage} /testbench/dut/hart/ieu/dp/Rs2D
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
add wave -noupdate -expand -group RegFile -group {write regfile mux} /testbench/dut/hart/ieu/dp/CSRReadValW
add wave -noupdate -expand -group RegFile -group {write regfile mux} /testbench/dut/hart/ieu/dp/ResultSrcW
add wave -noupdate -expand -group RegFile -group {write regfile mux} /testbench/dut/hart/ieu/dp/ResultW
add wave -noupdate -expand -group alu /testbench/dut/hart/ieu/dp/alu/a
add wave -noupdate -expand -group alu /testbench/dut/hart/ieu/dp/alu/b
add wave -noupdate -expand -group alu /testbench/dut/hart/ieu/dp/alu/alucontrol
add wave -noupdate -expand -group alu /testbench/dut/hart/ieu/dp/alu/result
add wave -noupdate -expand -group alu /testbench/dut/hart/ieu/dp/alu/flags
add wave -noupdate -expand -group alu -divider internals
add wave -noupdate -expand -group alu /testbench/dut/hart/ieu/dp/alu/overflow
add wave -noupdate -expand -group alu /testbench/dut/hart/ieu/dp/alu/carry
add wave -noupdate -expand -group alu /testbench/dut/hart/ieu/dp/alu/zero
add wave -noupdate -expand -group alu /testbench/dut/hart/ieu/dp/alu/neg
add wave -noupdate -expand -group alu /testbench/dut/hart/ieu/dp/alu/lt
add wave -noupdate -expand -group alu /testbench/dut/hart/ieu/dp/alu/ltu
add wave -noupdate /testbench/InstrFName
add wave -noupdate -group dcache /testbench/dut/hart/MemAdrM
add wave -noupdate -group dcache /testbench/dut/hart/MemPAdrM
add wave -noupdate -group dcache /testbench/dut/hart/WriteDataM
add wave -noupdate -group dcache /testbench/dut/hart/dmem/MemRWM
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
add wave -noupdate -group {alu execution stage} /testbench/dut/hart/ieu/dp/WriteDataE
add wave -noupdate -group {alu execution stage} /testbench/dut/hart/ieu/dp/ALUResultE
add wave -noupdate -group {alu execution stage} /testbench/dut/hart/ieu/dp/SrcAE
add wave -noupdate -group {alu execution stage} /testbench/dut/hart/ieu/dp/SrcBE
add wave -noupdate /testbench/dut/hart/ieu/dp/ALUResultM
add wave -noupdate -group PCS /testbench/dut/hart/ifu/PCNextF
add wave -noupdate -group PCS /testbench/dut/hart/PCF
add wave -noupdate -group PCS /testbench/dut/hart/ifu/PCD
add wave -noupdate -group PCS /testbench/dut/hart/PCE
add wave -noupdate -group PCS /testbench/dut/hart/PCM
add wave -noupdate -group PCS /testbench/dut/hart/ifu/PCW
add wave -noupdate -group PCS -group pcnextmux /testbench/dut/hart/ifu/PCNextF
add wave -noupdate -group PCS -group pcnextmux /testbench/dut/hart/ifu/PCNext0F
add wave -noupdate -group PCS -group pcnextmux /testbench/dut/hart/ifu/PCNext1F
add wave -noupdate -group {function radix debug} /testbench/FunctionName/FunctionName/FunctionAddr
add wave -noupdate -group {function radix debug} -radix unsigned /testbench/FunctionName/FunctionName/ProgramAddrIndex
add wave -noupdate -group {function radix debug} /testbench/FunctionName/FunctionName/reset
add wave -noupdate -group {function radix debug} /testbench/FunctionName/FunctionName/ProgramLabelMapLineCount
add wave -noupdate -group {function radix debug} /testbench/FunctionName/FunctionName/ProgramLabelMapLine
add wave -noupdate -group {function radix debug} /testbench/FunctionName/FunctionName/ProgramLabelMapFP
add wave -noupdate -group {function radix debug} /testbench/FunctionName/FunctionName/ProgramLabelMapFile
add wave -noupdate -group {function radix debug} /testbench/FunctionName/FunctionName/ProgramAddrMapLineCount
add wave -noupdate -group {function radix debug} /testbench/FunctionName/FunctionName/ProgramAddrMapLine
add wave -noupdate -group {function radix debug} /testbench/FunctionName/FunctionName/ProgramAddrMapFP
add wave -noupdate -group {function radix debug} /testbench/FunctionName/FunctionName/ProgramAddrMapFile
add wave -noupdate -group {function radix debug} /testbench/FunctionName/FunctionName/FunctionAddr
add wave -noupdate -group {function radix debug} /testbench/FunctionName/FunctionName/ProgramAddrIndex
add wave -noupdate -group {function radix debug} /testbench/FunctionName/FunctionName/FunctionName
add wave -noupdate -expand -group {performance counters} /testbench/dut/hart/priv/csr/genblk1/counters/MCOUNTEN
add wave -noupdate -expand -group {performance counters} /testbench/dut/hart/priv/csr/genblk1/counters/MCOUNTINHIBIT_REGW
add wave -noupdate -expand -group {performance counters} /testbench/dut/hart/priv/csr/genblk1/counters/genblk1/HPMCOUNTER_REGW
add wave -noupdate /testbench/dut/hart/ieu/dp/ALUResultW
add wave -noupdate /testbench/dut/hart/ieu/dp/ResultSrcW
add wave -noupdate /testbench/dut/hart/ieu/dp/CSRReadValW
add wave -noupdate /testbench/dut/hart/priv/csr/genblk1/counters/CSRCReadValM
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 7} {13518 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 250
configure wave -valuecolwidth 229
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
WaveRestoreZoom {13489 ns} {13607 ns}
