onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/reset
add wave -noupdate /testbench/memfilename
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
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/hart/hzu/BPPredWrongE
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/hart/hzu/CSRWritePendingDEM
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/hart/hzu/RetM
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/hart/hzu/TrapM
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/hart/hzu/LoadStallD
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/hart/hzu/ICacheStallF
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/hart/DataStall
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/hart/MulDivStallD
add wave -noupdate -expand -group HDU -group Flush -color Yellow /testbench/dut/hart/hzu/FlushF
add wave -noupdate -expand -group HDU -group Flush -color Yellow /testbench/dut/hart/FlushD
add wave -noupdate -expand -group HDU -group Flush -color Yellow /testbench/dut/hart/FlushE
add wave -noupdate -expand -group HDU -group Flush -color Yellow /testbench/dut/hart/FlushM
add wave -noupdate -expand -group HDU -group Flush -color Yellow /testbench/dut/hart/FlushW
add wave -noupdate -expand -group HDU -group Stall -color Orange /testbench/dut/hart/StallF
add wave -noupdate -expand -group HDU -group Stall -color Orange /testbench/dut/hart/StallD
add wave -noupdate -expand -group HDU -group Stall -color Orange /testbench/dut/hart/StallE
add wave -noupdate -expand -group HDU -group Stall -color Orange /testbench/dut/hart/StallM
add wave -noupdate -expand -group HDU -group Stall -color Orange /testbench/dut/hart/StallW
add wave -noupdate -group Bpred -color Orange /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHR
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/BPPredF
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} {/testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/InstrClassE[0]}
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} {/testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/BPInstrClassE[0]}
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/BPPredDirWrongE
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} -divider {class check}
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/BPClassRightNonCFI
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/BPClassWrongCFI
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/BPClassWrongNonCFI
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/BPClassRightBPRight
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/BPClassRightBPWrong
add wave -noupdate -group Bpred -radix hexadecimal -childformat {{{/testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[6]} -radix binary} {{/testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[5]} -radix binary} {{/testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[4]} -radix binary} {{/testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[3]} -radix binary} {{/testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[2]} -radix binary} {{/testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[1]} -radix binary} {{/testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[0]} -radix binary}} -subitemconfig {{/testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[6]} {-height 16 -radix binary} {/testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[5]} {-height 16 -radix binary} {/testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[4]} {-height 16 -radix binary} {/testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[3]} {-height 16 -radix binary} {/testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[2]} {-height 16 -radix binary} {/testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[1]} {-height 16 -radix binary} {/testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[0]} {-height 16 -radix binary}} /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel
add wave -noupdate -group Bpred /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHRNext
add wave -noupdate -group Bpred /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHRUpdateEN
add wave -noupdate -group Bpred /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/PHTUpdateAdr
add wave -noupdate -group Bpred /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/PHTUpdateAdr0
add wave -noupdate -group Bpred /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/PHTUpdateAdr1
add wave -noupdate -group Bpred /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/PHTUpdateEN
add wave -noupdate -group Bpred -expand -group prediction /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHRLookup
add wave -noupdate -group Bpred -expand -group prediction /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/PCNextF
add wave -noupdate -group Bpred -expand -group prediction /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/PHT/RA1
add wave -noupdate -group Bpred -expand -group prediction -radix binary /testbench/dut/hart/ifu/bpred/bpred/BPPredF
add wave -noupdate -group Bpred -expand -group prediction /testbench/dut/hart/ifu/bpred/bpred/BTBValidF
add wave -noupdate -group Bpred -expand -group prediction /testbench/dut/hart/ifu/bpred/bpred/BPInstrClassF
add wave -noupdate -group Bpred -expand -group prediction /testbench/dut/hart/ifu/bpred/bpred/BTBPredPCF
add wave -noupdate -group Bpred -expand -group prediction /testbench/dut/hart/ifu/bpred/bpred/RASPCF
add wave -noupdate -group Bpred -expand -group prediction /testbench/dut/hart/ifu/bpred/bpred/TargetPredictor/LookUpPCIndex
add wave -noupdate -group Bpred -expand -group prediction /testbench/dut/hart/ifu/bpred/bpred/TargetPredictor/TargetPC
add wave -noupdate -group Bpred -expand -group prediction -expand -group ex -radix binary /testbench/dut/hart/ifu/bpred/bpred/BPPredE
add wave -noupdate -group Bpred -expand -group prediction -expand -group ex /testbench/dut/hart/ifu/bpred/bpred/PCSrcE
add wave -noupdate -group Bpred -expand -group prediction -expand -group ex /testbench/dut/hart/ifu/bpred/bpred/BPPredDirWrongE
add wave -noupdate -group Bpred -expand -group update -expand -group BTB /testbench/dut/hart/ifu/bpred/bpred/TargetPredictor/UpdatePCIndex
add wave -noupdate -group Bpred -expand -group update -expand -group BTB /testbench/dut/hart/ifu/bpred/bpred/TargetPredictor/UpdateTarget
add wave -noupdate -group Bpred -expand -group update -expand -group BTB /testbench/dut/hart/ifu/bpred/bpred/TargetPredictor/UpdateEN
add wave -noupdate -group Bpred -expand -group update -expand -group BTB /testbench/dut/hart/ifu/bpred/bpred/TargetPredictor/UpdatePC
add wave -noupdate -group Bpred -expand -group update -expand -group BTB /testbench/dut/hart/ifu/bpred/bpred/TargetPredictor/UpdateTarget
add wave -noupdate -group Bpred -expand -group update -expand -group direction /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/PHTUpdateAdr
add wave -noupdate -group Bpred -expand -group update -expand -group direction /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/PCE
add wave -noupdate -group Bpred -expand -group update -expand -group direction /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/PHT/WA1
add wave -noupdate -group Bpred -expand -group {bp wrong} /testbench/dut/hart/ifu/bpred/bpred/TargetWrongE
add wave -noupdate -group Bpred -expand -group {bp wrong} /testbench/dut/hart/ifu/bpred/bpred/FallThroughWrongE
add wave -noupdate -group Bpred -expand -group {bp wrong} /testbench/dut/hart/ifu/bpred/bpred/PredictionPCWrongE
add wave -noupdate -group Bpred -expand -group {bp wrong} /testbench/dut/hart/ifu/bpred/bpred/InstrClassE
add wave -noupdate -group Bpred -expand -group {bp wrong} /testbench/dut/hart/ifu/bpred/bpred/PredictionInstrClassWrongE
add wave -noupdate -group Bpred -expand -group {bp wrong} /testbench/dut/hart/ifu/bpred/bpred/BPPredClassNonCFIWrongE
add wave -noupdate -group Bpred -expand -group {bp wrong} /testbench/dut/hart/ifu/bpred/bpred/BPPredWrongE
add wave -noupdate -group Bpred /testbench/dut/hart/ifu/bpred/bpred/BPPredWrongE
add wave -noupdate -expand -group {instruction pipeline} /testbench/InstrFName
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
add wave -noupdate -group {Decode Stage} /testbench/dut/hart/ifu/InstrD
add wave -noupdate -group {Decode Stage} /testbench/InstrDName
add wave -noupdate -group {Decode Stage} /testbench/dut/hart/ieu/c/RegWriteD
add wave -noupdate -group {Decode Stage} /testbench/dut/hart/ieu/dp/RdD
add wave -noupdate -group {Decode Stage} /testbench/dut/hart/ieu/dp/Rs1D
add wave -noupdate -group {Decode Stage} /testbench/dut/hart/ieu/dp/Rs2D
add wave -noupdate -group RegFile /testbench/dut/hart/ieu/dp/regf/rf
add wave -noupdate -group RegFile /testbench/dut/hart/ieu/dp/regf/a1
add wave -noupdate -group RegFile /testbench/dut/hart/ieu/dp/regf/a2
add wave -noupdate -group RegFile /testbench/dut/hart/ieu/dp/regf/a3
add wave -noupdate -group RegFile /testbench/dut/hart/ieu/dp/regf/rd1
add wave -noupdate -group RegFile /testbench/dut/hart/ieu/dp/regf/rd2
add wave -noupdate -group RegFile /testbench/dut/hart/ieu/dp/regf/we3
add wave -noupdate -group RegFile /testbench/dut/hart/ieu/dp/regf/wd3
add wave -noupdate -group RegFile -group {write regfile mux} /testbench/dut/hart/ieu/dp/ALUResultW
add wave -noupdate -group RegFile -group {write regfile mux} /testbench/dut/hart/ieu/dp/ReadDataW
add wave -noupdate -group RegFile -group {write regfile mux} /testbench/dut/hart/ieu/dp/CSRReadValW
add wave -noupdate -group RegFile -group {write regfile mux} /testbench/dut/hart/ieu/dp/ResultSrcW
add wave -noupdate -group RegFile -group {write regfile mux} /testbench/dut/hart/ieu/dp/ResultW
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
add wave -noupdate -group dcache -expand -group {cpu request} /testbench/dut/hart/MemAdrM
add wave -noupdate -group dcache -expand -group {cpu request} /testbench/dut/hart/WriteDataM
add wave -noupdate -group dcache /testbench/dut/hart/MemPAdrM
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
add wave -noupdate -group PCS /testbench/dut/hart/ifu/PCNextF
add wave -noupdate -group PCS /testbench/dut/hart/PCF
add wave -noupdate -group PCS /testbench/dut/hart/ifu/PCD
add wave -noupdate -group PCS /testbench/dut/hart/PCE
add wave -noupdate -group PCS /testbench/dut/hart/PCM
add wave -noupdate -group PCS /testbench/PCW
add wave -noupdate -group muldiv /testbench/dut/hart/mdu/InstrD
add wave -noupdate -group muldiv /testbench/dut/hart/mdu/SrcAE
add wave -noupdate -group muldiv /testbench/dut/hart/mdu/SrcBE
add wave -noupdate -group muldiv /testbench/dut/hart/mdu/Funct3E
add wave -noupdate -group muldiv /testbench/dut/hart/mdu/MulDivE
add wave -noupdate -group muldiv /testbench/dut/hart/mdu/W64E
add wave -noupdate -group muldiv /testbench/dut/hart/mdu/StallM
add wave -noupdate -group muldiv /testbench/dut/hart/mdu/StallW
add wave -noupdate -group muldiv /testbench/dut/hart/mdu/FlushM
add wave -noupdate -group muldiv /testbench/dut/hart/mdu/FlushW
add wave -noupdate -group muldiv /testbench/dut/hart/mdu/MulDivResultW
add wave -noupdate -group muldiv /testbench/dut/hart/mdu/genblk1/div/start
add wave -noupdate -group muldiv /testbench/dut/hart/mdu/DivDoneE
add wave -noupdate -group muldiv /testbench/dut/hart/mdu/DivBusyE
add wave -noupdate -group divider /testbench/dut/hart/mdu/genblk1/div/fsm1/CURRENT_STATE
add wave -noupdate -group divider /testbench/dut/hart/mdu/genblk1/div/N
add wave -noupdate -group divider /testbench/dut/hart/mdu/genblk1/div/D
add wave -noupdate -group divider /testbench/dut/hart/mdu/genblk1/div/Q
add wave -noupdate -group divider /testbench/dut/hart/mdu/genblk1/div/rem0
add wave -noupdate -group icache -color Orange /testbench/dut/hart/ifu/icache/controller/CurrState
add wave -noupdate -group icache /testbench/dut/hart/ifu/icache/controller/NextState
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/hit
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/spill
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/ICacheStallF
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/SavePC
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/spillSave
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/UnalignedSelect
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/PCMux
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/spillSave
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/CntReset
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/PreCntEn
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/CntEn
add wave -noupdate -group icache -expand -group {icache parameters} -radix unsigned /testbench/dut/hart/ifu/icache/cachemem/NUMLINES
add wave -noupdate -group icache -expand -group {icache parameters} -radix unsigned /testbench/dut/hart/ifu/icache/cachemem/BLOCKLEN
add wave -noupdate -group icache -expand -group {icache parameters} -radix unsigned /testbench/dut/hart/ifu/icache/cachemem/BLOCKBYTELEN
add wave -noupdate -group icache -expand -group {icache parameters} -radix unsigned /testbench/dut/hart/ifu/icache/cachemem/OFFSETLEN
add wave -noupdate -group icache -expand -group {icache parameters} -radix unsigned /testbench/dut/hart/ifu/icache/cachemem/INDEXLEN
add wave -noupdate -group icache -expand -group {icache parameters} -radix unsigned /testbench/dut/hart/ifu/icache/cachemem/TAGLEN
add wave -noupdate -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/FetchCountFlag
add wave -noupdate -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/FetchCount
add wave -noupdate -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/InstrPAdrF
add wave -noupdate -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/InstrReadF
add wave -noupdate -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/InstrAckF
add wave -noupdate -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/InstrInF
add wave -noupdate -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/ICacheMemWriteEnable
add wave -noupdate -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/ICacheMemWriteData
add wave -noupdate -group icache -expand -group memory -group {tag read} /testbench/dut/hart/ifu/icache/cachemem/DataValidBit
add wave -noupdate -group icache -expand -group memory -group {tag read} /testbench/dut/hart/ifu/icache/cachemem/cachetags/ReadData
add wave -noupdate -group icache -expand -group memory -group {tag write} /testbench/dut/hart/ifu/icache/cachemem/WriteEnable
add wave -noupdate -group icache -expand -group memory -group {tag write} /testbench/dut/hart/ifu/icache/cachemem/WriteLine
add wave -noupdate -group icache -expand -group memory -group {tag write} /testbench/dut/hart/ifu/icache/cachemem/cachetags/StoredData
add wave -noupdate -group icache -expand -group {instr to cpu} /testbench/dut/hart/ifu/icache/controller/FinalInstrRawF
add wave -noupdate -group icache -expand -group pc /testbench/dut/hart/ifu/icache/controller/PCPF
add wave -noupdate -group icache -expand -group pc /testbench/dut/hart/ifu/icache/controller/PCPreFinalF
add wave -noupdate -group AHB /testbench/dut/hart/ebu/BusState
add wave -noupdate -group AHB /testbench/dut/hart/ebu/ProposedNextBusState
add wave -noupdate -group AHB /testbench/dut/hart/ebu/NextBusState
add wave -noupdate -group AHB /testbench/dut/hart/ebu/DSquashBusAccessM
add wave -noupdate -group AHB /testbench/dut/hart/ebu/ISquashBusAccessF
add wave -noupdate -group AHB -expand -group {input requests} /testbench/dut/hart/ebu/AtomicMaskedM
add wave -noupdate -group AHB -expand -group {input requests} /testbench/dut/hart/ebu/MemReadM
add wave -noupdate -group AHB -expand -group {input requests} /testbench/dut/hart/ebu/MemWriteM
add wave -noupdate -group AHB -expand -group {input requests} /testbench/dut/hart/ebu/InstrReadF
add wave -noupdate -group AHB /testbench/dut/hart/ebu/HCLK
add wave -noupdate -group AHB /testbench/dut/hart/ebu/HRESETn
add wave -noupdate -group AHB /testbench/dut/hart/ebu/HRDATA
add wave -noupdate -group AHB /testbench/dut/hart/ebu/HREADY
add wave -noupdate -group AHB /testbench/dut/hart/ebu/HRESP
add wave -noupdate -group AHB /testbench/dut/hart/ebu/HADDR
add wave -noupdate -group AHB /testbench/dut/hart/ebu/HWDATA
add wave -noupdate -group AHB /testbench/dut/hart/ebu/HWRITE
add wave -noupdate -group AHB /testbench/dut/hart/ebu/HSIZE
add wave -noupdate -group AHB /testbench/dut/hart/ebu/HBURST
add wave -noupdate -group AHB /testbench/dut/hart/ebu/HPROT
add wave -noupdate -group AHB /testbench/dut/hart/ebu/HTRANS
add wave -noupdate -group AHB /testbench/dut/hart/ebu/HMASTLOCK
add wave -noupdate -group AHB /testbench/dut/hart/ebu/HADDRD
add wave -noupdate -group AHB /testbench/dut/hart/ebu/HSIZED
add wave -noupdate -group AHB /testbench/dut/hart/ebu/HWRITED
add wave -noupdate -expand -group lsu /testbench/dut/hart/lsu/CurrState
add wave -noupdate -expand -group lsu /testbench/dut/hart/arbiter/MemAdrM
add wave -noupdate -expand -group lsu /testbench/dut/hart/lsu/MemPAdrM
add wave -noupdate -expand -group lsu /testbench/dut/hart/lsu/WriteDataM
add wave -noupdate -expand -group lsu /testbench/dut/hart/lsu/AtomicMaskedM
add wave -noupdate -expand -group lsu /testbench/dut/hart/lsu/DSquashBusAccessM
add wave -noupdate -expand -group lsu /testbench/dut/hart/lsu/MemAckW
add wave -noupdate -group plic /testbench/dut/uncore/genblk2/plic/HCLK
add wave -noupdate -group plic /testbench/dut/uncore/genblk2/plic/HSELPLIC
add wave -noupdate -group plic /testbench/dut/uncore/genblk2/plic/HADDR
add wave -noupdate -group plic /testbench/dut/uncore/genblk2/plic/HWRITE
add wave -noupdate -group plic /testbench/dut/uncore/genblk2/plic/HREADY
add wave -noupdate -group plic /testbench/dut/uncore/genblk2/plic/HTRANS
add wave -noupdate -group plic /testbench/dut/uncore/genblk2/plic/HWDATA
add wave -noupdate -group plic /testbench/dut/uncore/genblk2/plic/UARTIntr
add wave -noupdate -group plic /testbench/dut/uncore/genblk2/plic/GPIOIntr
add wave -noupdate -group plic /testbench/dut/uncore/genblk2/plic/HREADPLIC
add wave -noupdate -group plic /testbench/dut/uncore/genblk2/plic/HRESPPLIC
add wave -noupdate -group plic /testbench/dut/uncore/genblk2/plic/HREADYPLIC
add wave -noupdate -group plic /testbench/dut/uncore/genblk2/plic/ExtIntM
add wave -noupdate -group GPIO /testbench/dut/uncore/genblk3/gpio/HCLK
add wave -noupdate -group GPIO /testbench/dut/uncore/genblk3/gpio/HSELGPIO
add wave -noupdate -group GPIO /testbench/dut/uncore/genblk3/gpio/HADDR
add wave -noupdate -group GPIO /testbench/dut/uncore/genblk3/gpio/HWDATA
add wave -noupdate -group GPIO /testbench/dut/uncore/genblk3/gpio/HWRITE
add wave -noupdate -group GPIO /testbench/dut/uncore/genblk3/gpio/HREADY
add wave -noupdate -group GPIO /testbench/dut/uncore/genblk3/gpio/HTRANS
add wave -noupdate -group GPIO /testbench/dut/uncore/genblk3/gpio/HREADGPIO
add wave -noupdate -group GPIO /testbench/dut/uncore/genblk3/gpio/HRESPGPIO
add wave -noupdate -group GPIO /testbench/dut/uncore/genblk3/gpio/HREADYGPIO
add wave -noupdate -group GPIO /testbench/dut/uncore/genblk3/gpio/GPIOPinsIn
add wave -noupdate -group GPIO /testbench/dut/uncore/genblk3/gpio/GPIOPinsOut
add wave -noupdate -group GPIO /testbench/dut/uncore/genblk3/gpio/GPIOPinsEn
add wave -noupdate -group GPIO /testbench/dut/uncore/genblk3/gpio/GPIOIntr
add wave -noupdate -group CLINT /testbench/dut/uncore/genblk1/clint/HCLK
add wave -noupdate -group CLINT /testbench/dut/uncore/genblk1/clint/HSELCLINT
add wave -noupdate -group CLINT /testbench/dut/uncore/genblk1/clint/HADDR
add wave -noupdate -group CLINT /testbench/dut/uncore/genblk1/clint/HWRITE
add wave -noupdate -group CLINT /testbench/dut/uncore/genblk1/clint/HWDATA
add wave -noupdate -group CLINT /testbench/dut/uncore/genblk1/clint/HREADY
add wave -noupdate -group CLINT /testbench/dut/uncore/genblk1/clint/HTRANS
add wave -noupdate -group CLINT /testbench/dut/uncore/genblk1/clint/HREADCLINT
add wave -noupdate -group CLINT /testbench/dut/uncore/genblk1/clint/HRESPCLINT
add wave -noupdate -group CLINT /testbench/dut/uncore/genblk1/clint/HREADYCLINT
add wave -noupdate -group CLINT /testbench/dut/uncore/genblk1/clint/MTIME
add wave -noupdate -group CLINT /testbench/dut/uncore/genblk1/clint/MTIMECMP
add wave -noupdate -group CLINT /testbench/dut/uncore/genblk1/clint/TimerIntM
add wave -noupdate -group CLINT /testbench/dut/uncore/genblk1/clint/SwIntM
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 4} {32648010 ns} 0} {{Cursor 5} {10763646 ns} 0}
quietly wave cursor active 2
configure wave -namecolwidth 250
configure wave -valuecolwidth 189
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
WaveRestoreZoom {10763302 ns} {10763880 ns}
