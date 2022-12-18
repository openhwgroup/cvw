onerror {resume}
quietly virtual function -install /testbench/dut/core/lsu -env /testbench/dut/core/lsu/bus { &{/testbench/dut/core/lsu/LSUHTRANS[1], /testbench/dut/core/lsu/LSUHADDR }} test
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/reset
add wave -noupdate -expand -group Testbench /testbench/reset_ext
add wave -noupdate -expand -group Testbench -radix unsigned /testbench/InstrCountW
add wave -noupdate -expand -group Testbench -radix unsigned /testbench/AttemptedInstructionCount
add wave -noupdate -expand -group Testbench -radix decimal /testbench/interruptInstrCount
add wave -noupdate -expand -group Testbench /testbench/interruptCauseVal
add wave -noupdate -expand -group Testbench /testbench/interruptEpcVal
add wave -noupdate -expand -group Testbench /testbench/interruptTVal
add wave -noupdate -expand -group Testbench /testbench/interruptDesc
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/core/hzu/BPPredWrongE
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/core/hzu/RetM
add wave -noupdate -expand -group HDU -expand -group hazards -color Pink /testbench/dut/core/hzu/TrapM
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/core/hzu/LoadStallD
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/core/hzu/LSUStallM
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/core/hzu/DivBusyE
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/priv/trap/ExceptionM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/priv/trap/InstrMisalignedFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/priv/trap/InstrAccessFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/priv/trap/IllegalInstrFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/priv/trap/LoadAccessFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/priv/trap/StoreAmoMisalignedFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/priv/trap/InstrPageFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/priv/trap/LoadPageFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/priv/trap/StoreAmoPageFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/priv/trap/BreakpointFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/priv/trap/EcallFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/priv/trap/LoadMisalignedFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/priv/trap/StoreAmoAccessFaultM
add wave -noupdate -expand -group HDU -group Flush -color Yellow /testbench/dut/core/FlushD
add wave -noupdate -expand -group HDU -group Flush -color Yellow /testbench/dut/core/FlushE
add wave -noupdate -expand -group HDU -group Flush -color Yellow /testbench/dut/core/FlushM
add wave -noupdate -expand -group HDU -group Flush -color Yellow /testbench/dut/core/FlushW
add wave -noupdate -expand -group HDU -group Stall -color Orange /testbench/dut/core/StallF
add wave -noupdate -expand -group HDU -group Stall -color Orange /testbench/dut/core/StallD
add wave -noupdate -expand -group HDU -group Stall -color Orange /testbench/dut/core/StallE
add wave -noupdate -expand -group HDU -group Stall -color Orange /testbench/dut/core/StallM
add wave -noupdate -expand -group HDU -group Stall -color Orange /testbench/dut/core/StallW
add wave -noupdate -group {instruction pipeline} /testbench/InstrFName
add wave -noupdate -group {instruction pipeline} /testbench/dut/core/ifu/FinalInstrRawF
add wave -noupdate -group {instruction pipeline} /testbench/dut/core/ifu/InstrD
add wave -noupdate -group {instruction pipeline} /testbench/dut/core/ifu/InstrE
add wave -noupdate -group {instruction pipeline} /testbench/dut/core/ifu/InstrM
add wave -noupdate -group {Decode Stage} /testbench/dut/core/ifu/PCD
add wave -noupdate -group {Decode Stage} /testbench/dut/core/ifu/InstrD
add wave -noupdate -group {Decode Stage} /testbench/InstrDName
add wave -noupdate -group {Decode Stage} /testbench/dut/core/ieu/c/InstrValidD
add wave -noupdate -group {Decode Stage} /testbench/dut/core/ieu/c/RegWriteD
add wave -noupdate -group {Decode Stage} /testbench/dut/core/ieu/dp/RdD
add wave -noupdate -group {Decode Stage} /testbench/dut/core/ieu/dp/Rs1D
add wave -noupdate -group {Decode Stage} /testbench/dut/core/ieu/dp/Rs2D
add wave -noupdate -group {Execution Stage} /testbench/dut/core/ifu/PCE
add wave -noupdate -group {Execution Stage} /testbench/ExpectedPCE
add wave -noupdate -group {Execution Stage} /testbench/dut/core/ifu/InstrE
add wave -noupdate -group {Execution Stage} /testbench/InstrEName
add wave -noupdate -group {Execution Stage} /testbench/dut/core/ieu/c/InstrValidE
add wave -noupdate -group {Execution Stage} /testbench/textE
add wave -noupdate -group {Execution Stage} -color {Cornflower Blue} /testbench/FunctionName/FunctionName
add wave -noupdate -expand -group {Memory Stage} /testbench/checkInstrM
add wave -noupdate -expand -group {Memory Stage} /testbench/dut/core/PCM
add wave -noupdate -expand -group {Memory Stage} /testbench/ExpectedPCM
add wave -noupdate -expand -group {Memory Stage} /testbench/dut/core/InstrM
add wave -noupdate -expand -group {Memory Stage} /testbench/InstrMName
add wave -noupdate -expand -group {Memory Stage} /testbench/textM
add wave -noupdate -expand -group {Memory Stage} /testbench/dut/core/lsu/IEUAdrM
add wave -noupdate -group {WriteBack stage} /testbench/checkInstrW
add wave -noupdate -group {WriteBack stage} /testbench/InstrValidW
add wave -noupdate -group {WriteBack stage} /testbench/PCW
add wave -noupdate -group {WriteBack stage} /testbench/ExpectedPCW
add wave -noupdate -group {WriteBack stage} /testbench/InstrW
add wave -noupdate -group {WriteBack stage} /testbench/InstrWName
add wave -noupdate -group {WriteBack stage} /testbench/textW
add wave -noupdate -group Bpred -color Orange /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHR
add wave -noupdate -group Bpred -group {branch update selection inputs} /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/BPPredF
add wave -noupdate -group Bpred -group {branch update selection inputs} {/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/InstrClassE[0]}
add wave -noupdate -group Bpred -group {branch update selection inputs} {/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/BPInstrClassE[0]}
add wave -noupdate -group Bpred -group {branch update selection inputs} /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/BPPredDirWrongE
add wave -noupdate -group Bpred -group {branch update selection inputs} -divider {class check}
add wave -noupdate -group Bpred -group {branch update selection inputs} /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/BPClassRightNonCFI
add wave -noupdate -group Bpred -group {branch update selection inputs} /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/BPClassWrongCFI
add wave -noupdate -group Bpred -group {branch update selection inputs} /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/BPClassWrongNonCFI
add wave -noupdate -group Bpred -group {branch update selection inputs} /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/BPClassRightBPRight
add wave -noupdate -group Bpred -group {branch update selection inputs} /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/BPClassRightBPWrong
add wave -noupdate -group Bpred -radix hexadecimal -childformat {{{/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[6]} -radix binary} {{/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[5]} -radix binary} {{/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[4]} -radix binary} {{/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[3]} -radix binary} {{/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[2]} -radix binary} {{/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[1]} -radix binary} {{/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[0]} -radix binary}} -subitemconfig {{/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[6]} {-height 17 -radix binary} {/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[5]} {-height 17 -radix binary} {/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[4]} {-height 17 -radix binary} {/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[3]} {-height 17 -radix binary} {/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[2]} {-height 17 -radix binary} {/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[1]} {-height 17 -radix binary} {/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[0]} {-height 17 -radix binary}} /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel
add wave -noupdate -group Bpred /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRNext
add wave -noupdate -group Bpred /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRUpdateEN
add wave -noupdate -group Bpred /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/PHTUpdateAdr
add wave -noupdate -group Bpred /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/PHTUpdateAdr0
add wave -noupdate -group Bpred /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/PHTUpdateAdr1
add wave -noupdate -group Bpred /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/PHTUpdateEN
add wave -noupdate -group Bpred -expand -group prediction /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRLookup
add wave -noupdate -group Bpred -expand -group prediction /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/PCNextF
add wave -noupdate -group Bpred -expand -group prediction /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/PHT/RA1
add wave -noupdate -group Bpred -expand -group prediction -radix binary /testbench/dut/core/ifu/bpred/bpred/BPPredF
add wave -noupdate -group Bpred -expand -group prediction /testbench/dut/core/ifu/bpred/bpred/BTBValidF
add wave -noupdate -group Bpred -expand -group prediction /testbench/dut/core/ifu/bpred/bpred/BPInstrClassF
add wave -noupdate -group Bpred -expand -group prediction /testbench/dut/core/ifu/bpred/bpred/BTBPredPCF
add wave -noupdate -group Bpred -expand -group prediction /testbench/dut/core/ifu/bpred/bpred/RASPCF
add wave -noupdate -group Bpred -expand -group prediction /testbench/dut/core/ifu/bpred/bpred/TargetPredictor/LookUpPCIndex
add wave -noupdate -group Bpred -expand -group prediction /testbench/dut/core/ifu/bpred/bpred/TargetPredictor/TargetPC
add wave -noupdate -group Bpred -expand -group prediction -expand -group ex -radix binary /testbench/dut/core/ifu/bpred/bpred/BPPredE
add wave -noupdate -group Bpred -expand -group prediction -expand -group ex /testbench/dut/core/ifu/bpred/bpred/PCSrcE
add wave -noupdate -group Bpred -expand -group prediction -expand -group ex /testbench/dut/core/ifu/bpred/bpred/BPPredDirWrongE
add wave -noupdate -group Bpred -expand -group update -expand -group BTB /testbench/dut/core/ifu/bpred/bpred/TargetPredictor/UpdatePCIndex
add wave -noupdate -group Bpred -expand -group update -expand -group BTB /testbench/dut/core/ifu/bpred/bpred/TargetPredictor/UpdateTarget
add wave -noupdate -group Bpred -expand -group update -expand -group BTB /testbench/dut/core/ifu/bpred/bpred/TargetPredictor/UpdateEN
add wave -noupdate -group Bpred -expand -group update -expand -group BTB /testbench/dut/core/ifu/bpred/bpred/TargetPredictor/UpdatePC
add wave -noupdate -group Bpred -expand -group update -expand -group BTB /testbench/dut/core/ifu/bpred/bpred/TargetPredictor/UpdateTarget
add wave -noupdate -group Bpred -expand -group update -expand -group direction /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/PHTUpdateAdr
add wave -noupdate -group Bpred -expand -group update -expand -group direction /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/PCE
add wave -noupdate -group Bpred -expand -group update -expand -group direction /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/PHT/WA1
add wave -noupdate -group Bpred -expand -group {bp wrong} /testbench/dut/core/ifu/bpred/bpred/TargetWrongE
add wave -noupdate -group Bpred -expand -group {bp wrong} /testbench/dut/core/ifu/bpred/bpred/FallThroughWrongE
add wave -noupdate -group Bpred -expand -group {bp wrong} /testbench/dut/core/ifu/bpred/bpred/PredictionPCWrongE
add wave -noupdate -group Bpred -expand -group {bp wrong} /testbench/dut/core/ifu/bpred/bpred/InstrClassE
add wave -noupdate -group Bpred -expand -group {bp wrong} /testbench/dut/core/ifu/bpred/bpred/PredictionInstrClassWrongE
add wave -noupdate -group Bpred -expand -group {bp wrong} /testbench/dut/core/ifu/bpred/bpred/BPPredClassNonCFIWrongE
add wave -noupdate -group Bpred -expand -group {bp wrong} /testbench/dut/core/ifu/bpred/bpred/BPPredWrongE
add wave -noupdate -group Bpred /testbench/dut/core/ifu/bpred/bpred/BPPredWrongE
add wave -noupdate -group PCS /testbench/dut/core/ifu/PCNextF
add wave -noupdate -group PCS /testbench/dut/core/PCF
add wave -noupdate -group PCS /testbench/dut/core/ifu/PCD
add wave -noupdate -group PCS /testbench/dut/core/PCE
add wave -noupdate -group PCS /testbench/dut/core/PCM
add wave -noupdate -group PCS /testbench/PCW
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/PCNextF
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/PCF
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/PCPlus2or4F
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/PCNext0F
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/PCNext1F
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/BPPredWrongE
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/PrivilegedChangePCM
add wave -noupdate -group RegFile -expand /testbench/dut/core/ieu/dp/regf/rf
add wave -noupdate -group RegFile /testbench/dut/core/ieu/dp/regf/a1
add wave -noupdate -group RegFile /testbench/dut/core/ieu/dp/regf/a2
add wave -noupdate -group RegFile /testbench/dut/core/ieu/dp/regf/a3
add wave -noupdate -group RegFile /testbench/dut/core/ieu/dp/regf/rd1
add wave -noupdate -group RegFile /testbench/dut/core/ieu/dp/regf/rd2
add wave -noupdate -group RegFile /testbench/dut/core/ieu/dp/regf/we3
add wave -noupdate -group RegFile /testbench/dut/core/ieu/dp/regf/wd3
add wave -noupdate -group RegFile -group {write regfile mux} /testbench/dut/core/ieu/dp/ReadDataW
add wave -noupdate -group RegFile -group {write regfile mux} /testbench/dut/core/ieu/dp/CSRReadValW
add wave -noupdate -group RegFile -group {write regfile mux} /testbench/dut/core/ieu/dp/ResultSrcW
add wave -noupdate -group RegFile -group {write regfile mux} /testbench/dut/core/ieu/dp/ResultW
add wave -noupdate -group alu /testbench/dut/core/ieu/dp/alu/A
add wave -noupdate -group alu /testbench/dut/core/ieu/dp/alu/B
add wave -noupdate -group alu /testbench/dut/core/ieu/dp/alu/ALUControl
add wave -noupdate -group alu -divider internals
add wave -noupdate -group Forward /testbench/dut/core/ieu/fw/Rs1D
add wave -noupdate -group Forward /testbench/dut/core/ieu/fw/Rs2D
add wave -noupdate -group Forward /testbench/dut/core/ieu/fw/Rs1E
add wave -noupdate -group Forward /testbench/dut/core/ieu/fw/Rs2E
add wave -noupdate -group Forward /testbench/dut/core/ieu/fw/RdE
add wave -noupdate -group Forward /testbench/dut/core/ieu/fw/RdM
add wave -noupdate -group Forward /testbench/dut/core/ieu/fw/RdW
add wave -noupdate -group Forward /testbench/dut/core/ieu/fw/MemReadE
add wave -noupdate -group Forward /testbench/dut/core/ieu/fw/RegWriteM
add wave -noupdate -group Forward /testbench/dut/core/ieu/fw/RegWriteW
add wave -noupdate -group Forward -color Thistle /testbench/dut/core/ieu/fw/ForwardAE
add wave -noupdate -group Forward -color Thistle /testbench/dut/core/ieu/fw/ForwardBE
add wave -noupdate -group Forward -color Thistle /testbench/dut/core/ieu/fw/LoadStallD
add wave -noupdate -group {alu execution stage} /testbench/dut/core/ieu/dp/ALUResultE
add wave -noupdate -group {alu execution stage} /testbench/dut/core/ieu/dp/SrcAE
add wave -noupdate -group {alu execution stage} /testbench/dut/core/ieu/dp/SrcBE
add wave -noupdate -group ifu -expand -group spill /testbench/dut/core/ifu/SpillSupport/spillsupport/SpillF
add wave -noupdate -group ifu -expand -group spill /testbench/dut/core/ifu/SpillSupport/spillsupport/CurrState
add wave -noupdate -group ifu -expand -group spill /testbench/dut/core/ifu/SpillSupport/spillsupport/SpillDataLine0
add wave -noupdate -group ifu -expand -group spill /testbench/dut/core/ifu/SpillSupport/spillsupport/SelSpillF
add wave -noupdate -group ifu -expand -group icache -color Gold /testbench/dut/core/ifu/bus/icache/icache/cachefsm/CurrState
add wave -noupdate -group ifu -expand -group icache /testbench/dut/core/ifu/ITLBMissF
add wave -noupdate -group ifu -expand -group icache /testbench/dut/core/ifu/bus/icache/icache/SelAdr
add wave -noupdate -group ifu -expand -group icache /testbench/dut/core/ifu/PCNextF
add wave -noupdate -group ifu -expand -group icache /testbench/dut/core/ifu/PCPF
add wave -noupdate -group ifu -expand -group icache -expand -group {fsm out and control} /testbench/dut/core/ifu/bus/icache/icache/HitWay
add wave -noupdate -group ifu -expand -group icache -expand -group {fsm out and control} /testbench/dut/core/ifu/ICacheStallF
add wave -noupdate -group ifu -expand -group icache -expand -group {fsm out and control} /testbench/dut/core/ifu/FinalInstrRawF
add wave -noupdate -group ifu -expand -group icache -expand -group memory /testbench/dut/core/ifu/bus/icache/icache/CacheBusAdr
add wave -noupdate -group ifu -expand -group icache -expand -group memory /testbench/dut/core/ifu/bus/icache/icache/cachefsm/CacheBusAck
add wave -noupdate -group ifu -expand -group itlb /testbench/dut/core/ifu/immu/immu/TLBWrite
add wave -noupdate -group ifu -expand -group itlb /testbench/dut/core/ifu/ITLBMissF
add wave -noupdate -group ifu -expand -group itlb /testbench/dut/core/ifu/immu/immu/PhysicalAddress
add wave -noupdate -expand -group lsu /testbench/dut/core/lsu/IEUAdrM
add wave -noupdate -expand -group lsu /testbench/dut/core/lsu/PAdrM
add wave -noupdate -expand -group lsu /testbench/dut/core/lsu/SelHPTW
add wave -noupdate -expand -group lsu /testbench/dut/core/lsu/LSUStallM
add wave -noupdate -expand -group lsu /testbench/dut/core/lsu/ReadDataWordMuxM
add wave -noupdate -expand -group lsu /testbench/dut/core/lsu/ReadDataM
add wave -noupdate -expand -group lsu /testbench/dut/core/lsu/WriteDataM
add wave -noupdate -expand -group lsu -group bus /testbench/dut/core/lsu/BusStall
add wave -noupdate -expand -group lsu -expand -group dcache -color Gold /testbench/dut/core/lsu/bus/dcache/dcache/cachefsm/CurrState
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu/bus/dcache/dcache/HitWay
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu/bus/dcache/dcache/SetValid
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu/bus/dcache/dcache/SetDirty
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu/bus/dcache/dcache/SelAdr
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu/IEUAdrE
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu/IEUAdrM
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu/bus/dcache/dcache/CAdr
add wave -noupdate -expand -group lsu -expand -group dcache {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[0]/ClearDirtyWay}
add wave -noupdate -expand -group lsu -expand -group dcache {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[0]/Dirty}
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group flush /testbench/dut/core/lsu/bus/dcache/dcache/NextFlushAdr
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group flush -radix hexadecimal /testbench/dut/core/lsu/bus/dcache/dcache/FlushAdr
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group flush /testbench/dut/core/lsu/bus/dcache/dcache/CAdr
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group flush /testbench/dut/core/lsu/bus/dcache/dcache/LineDirty
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group flush /testbench/dut/core/lsu/bus/dcache/dcache/FlushWay
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group flush /testbench/dut/core/lsu/bus/dcache/dcache/FlushWay
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group flush /testbench/dut/core/lsu/bus/dcache/dcache/SetDirty
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group flush /testbench/dut/core/lsu/bus/dcache/dcache/ClearDirty
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group flush /testbench/dut/core/lsu/bus/dcache/dcache/CacheBusAdr
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group flush /testbench/dut/core/lsu/CacheableM
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} /testbench/dut/core/lsu/bus/dcache/dcache/ClearDirty
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[0]/SelectedWriteWordEn}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[0]/SetValidWay}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[0]/SetDirtyWay}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 -label TAG {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[0]/CacheTagMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[0]/DirtyBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[0]/ValidBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 -expand -group Way0Word0 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[0]/word[0]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 -expand -group Way0Word1 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[0]/word[1]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 -expand -group Way0Word2 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[0]/word[2]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 -expand -group Way0Word3 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[0]/word[3]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[1]/SelectedWriteWordEn}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[1]/SetValidWay}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[1]/SetDirtyWay}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -label TAG {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[1]/CacheTagMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[1]/DirtyBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[1]/ValidBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word0 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[1]/word[0]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word1 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[1]/word[1]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word2 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[1]/word[2]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word3 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[1]/word[3]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[2]/SelectedWriteWordEn}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[2]/SetValidWay}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[2]/SetDirtyWay}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -label TAG {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[2]/CacheTagMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[2]/DirtyBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[2]/ValidBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word0 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[2]/word[0]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word1 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[2]/word[1]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word2 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[2]/word[2]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word3 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[2]/word[3]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/SelectedWriteWordEn}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/SetValidWay}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/CacheTagMem/RAM[2]}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/ValidBits[2]}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/DirtyBits[2]}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/SetDirtyWay}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -label TAG {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/CacheTagMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/DirtyBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/ValidBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word0 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/word[0]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word0 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/word[0]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word1 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/word[1]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word1 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/word[1]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word2 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/word[2]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word2 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/word[2]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word3 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/word[3]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word3 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/word[3]/CacheDataMem/RAM}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group valid/dirty /testbench/dut/core/lsu/bus/dcache/dcache/SetValid
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group valid/dirty /testbench/dut/core/lsu/bus/dcache/dcache/ClearValid
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group valid/dirty /testbench/dut/core/lsu/bus/dcache/dcache/SetDirty
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group valid/dirty /testbench/dut/core/lsu/bus/dcache/dcache/ClearDirty
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} /testbench/dut/core/lsu/bus/dcache/dcache/CAdr
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -group way0 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[0]/HitWay}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -group way0 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[0]/Dirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -group way0 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[0]/ReadTag}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -group way1 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[1]/HitWay}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -group way1 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[1]/Dirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -group way1 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[1]/ReadTag}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -group way2 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[2]/HitWay}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -group way2 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[2]/Dirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -group way2 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[2]/ReadTag}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way3 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/HitWay}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way3 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/Dirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way3 {/testbench/dut/core/lsu/bus/dcache/dcache/CacheWays[3]/ReadTag}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} /testbench/dut/core/lsu/bus/dcache/dcache/HitWay
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group Victim /testbench/dut/core/lsu/bus/dcache/dcache/VictimWay
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/core/lsu/bus/dcache/dcache/NextAdr
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/core/lsu/bus/dcache/dcache/PAdr
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/core/lsu/bus/dcache/dcache/FlushCache
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/core/lsu/bus/dcache/dcache/CacheStall
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/core/lsu/ReadDataWordM
add wave -noupdate -expand -group lsu -expand -group dcache -group status /testbench/dut/core/lsu/bus/dcache/dcache/HitWay
add wave -noupdate -expand -group lsu -expand -group dcache -group status -color {Medium Orchid} /testbench/dut/core/lsu/bus/dcache/dcache/CacheHit
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {Memory Side} /testbench/dut/core/lsu/bus/dcache/dcache/CacheBusAck
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu/bus/dcache/dcache/FlushWay
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/VAdr
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/tlbcontrol/EffectivePrivilegeMode
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/PTE
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/HitPageType
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/tlbcontrol/Translate
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/tlbcontrol/DisableTranslation
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/dmmu/TLBMiss
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/dmmu/TLBHit
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/dmmu/PhysicalAddress
add wave -noupdate -expand -group lsu -group dtlb -expand -group Status /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/tlbcontrol/PTE_D
add wave -noupdate -expand -group lsu -group dtlb -expand -group Status /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/tlbcontrol/PTE_A
add wave -noupdate -expand -group lsu -group dtlb -expand -group Status /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/tlbcontrol/PTE_U
add wave -noupdate -expand -group lsu -group dtlb -expand -group Status /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/tlbcontrol/PTE_X
add wave -noupdate -expand -group lsu -group dtlb -expand -group Status /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/tlbcontrol/PTE_W
add wave -noupdate -expand -group lsu -group dtlb -expand -group Status /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/tlbcontrol/PTE_R
add wave -noupdate -expand -group lsu -group dtlb -expand -group Status /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/tlbcontrol/PTE_V
add wave -noupdate -expand -group lsu -group dtlb -expand -group Status -color Maroon /testbench/dut/core/lsu/dmmu/dmmu/DAPageFault
add wave -noupdate -expand -group lsu -group dtlb -expand -group Status /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/tlbcontrol/ImproperPrivilege
add wave -noupdate -expand -group lsu -group dtlb -expand -group Status /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/tlbcontrol/UpperBitsUnequalPageFault
add wave -noupdate -expand -group lsu -group dtlb -expand -group Status /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/tlbcontrol/Misaligned
add wave -noupdate -expand -group lsu -group dtlb -expand -group Status /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/tlbcontrol/dtlb/InvalidRead
add wave -noupdate -expand -group lsu -group dtlb -expand -group Status /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/tlbcontrol/dtlb/InvalidWrite
add wave -noupdate -expand -group lsu -group dtlb -group faults /testbench/dut/core/lsu/dmmu/dmmu/TLBPageFault
add wave -noupdate -expand -group lsu -group dtlb -group faults /testbench/dut/core/lsu/dmmu/dmmu/LoadAccessFaultM
add wave -noupdate -expand -group lsu -group dtlb -group faults /testbench/dut/core/lsu/dmmu/dmmu/StoreAmoAccessFaultM
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/TLBPAdr
add wave -noupdate -expand -group lsu -group dtlb -group write /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/PTE
add wave -noupdate -expand -group lsu -group dtlb -group write /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/PageTypeWriteVal
add wave -noupdate -expand -group lsu -group dtlb -group write /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/TLBWrite
add wave -noupdate -expand -group lsu -group pma /testbench/dut/core/lsu/dmmu/dmmu/pmachecker/PhysicalAddress
add wave -noupdate -expand -group lsu -group pma /testbench/dut/core/lsu/dmmu/dmmu/pmachecker/SelRegions
add wave -noupdate -expand -group lsu -group pma /testbench/dut/core/lsu/dmmu/dmmu/Cacheable
add wave -noupdate -expand -group lsu -group pma /testbench/dut/core/lsu/dmmu/dmmu/Idempotent
add wave -noupdate -expand -group lsu -group pma /testbench/dut/core/lsu/dmmu/dmmu/AtomicAllowed
add wave -noupdate -expand -group lsu -group pma /testbench/dut/core/lsu/dmmu/dmmu/pmachecker/PMAAccessFault
add wave -noupdate -expand -group lsu -group pma /testbench/dut/core/lsu/dmmu/dmmu/PMAInstrAccessFaultF
add wave -noupdate -expand -group lsu -group pma /testbench/dut/core/lsu/dmmu/dmmu/PMALoadAccessFaultM
add wave -noupdate -expand -group lsu -group pma /testbench/dut/core/lsu/dmmu/dmmu/PMAStoreAmoAccessFaultM
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/core/lsu/dmmu/dmmu/pmpchecker/PhysicalAddress
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/core/lsu/dmmu/dmmu/pmpchecker/ReadAccessM
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/core/lsu/dmmu/dmmu/pmpchecker/WriteAccessM
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/core/lsu/dmmu/dmmu/pmpchecker/PMPADDR_ARRAY_REGW
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/core/lsu/dmmu/dmmu/pmpchecker/PMPCFG_ARRAY_REGW
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/core/lsu/dmmu/dmmu/PMPInstrAccessFaultF
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/core/lsu/dmmu/dmmu/PMPLoadAccessFaultM
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/core/lsu/dmmu/dmmu/PMPStoreAmoAccessFaultM
add wave -noupdate -group AHB /testbench/dut/core/ebu/ebu/HCLK
add wave -noupdate -group AHB /testbench/dut/core/ebu/ebu/HRESETn
add wave -noupdate -group AHB /testbench/dut/core/ebu/ebu/HREADY
add wave -noupdate -group AHB /testbench/dut/core/ebu/ebu/HRESP
add wave -noupdate -group AHB /testbench/dut/core/ebu/ebu/HADDR
add wave -noupdate -group AHB /testbench/dut/core/ebu/ebu/HWDATA
add wave -noupdate -group AHB /testbench/dut/core/ebu/ebu/HWRITE
add wave -noupdate -group AHB /testbench/dut/core/ebu/ebu/HSIZE
add wave -noupdate -group AHB /testbench/dut/core/ebu/ebu/HBURST
add wave -noupdate -group AHB /testbench/dut/core/ebu/ebu/HPROT
add wave -noupdate -group AHB /testbench/dut/core/ebu/ebu/HTRANS
add wave -noupdate -group AHB /testbench/dut/core/ebu/ebu/HMASTLOCK
add wave -noupdate -group AHB -group {pc selection} /testbench/dut/core/ifu/PCNext2F
add wave -noupdate -group AHB -group {pc selection} /testbench/dut/core/ifu/PrivilegedNextPCM
add wave -noupdate -group AHB -group {pc selection} /testbench/dut/core/ifu/PrivilegedChangePCM
add wave -noupdate -group AMO_ALU /testbench/dut/core/lsu/atomic/atomic/amoalu/funct
add wave -noupdate -group AMO_ALU /testbench/dut/core/lsu/atomic/atomic/amoalu/result
add wave -noupdate -group AMO_ALU /testbench/dut/core/lsu/atomic/atomic/amoalu/srca
add wave -noupdate -group AMO_ALU /testbench/dut/core/lsu/atomic/atomic/amoalu/srcb
add wave -noupdate -group AMO_ALU /testbench/dut/core/lsu/atomic/atomic/amoalu/width
add wave -noupdate -group itlb /testbench/dut/core/ifu/immu/immu/TLBWrite
add wave -noupdate -group itlb /testbench/dut/core/ifu/ITLBMissF
add wave -noupdate -group itlb /testbench/dut/core/ifu/immu/immu/PhysicalAddress
add wave -noupdate -group itlb /testbench/dut/core/ifu/immu/immu/PMAInstrAccessFaultF
add wave -noupdate -group plic /testbench/dut/uncore/uncore/plic/plic/UARTIntr
add wave -noupdate -group plic /testbench/dut/uncore/uncore/plic/plic/GPIOIntr
add wave -noupdate -group GPIO /testbench/dut/uncore/uncore/gpio/gpio/GPIOPinsIn
add wave -noupdate -group GPIO /testbench/dut/uncore/uncore/gpio/gpio/GPIOPinsOut
add wave -noupdate -group GPIO /testbench/dut/uncore/uncore/gpio/gpio/GPIOPinsEn
add wave -noupdate -group GPIO /testbench/dut/uncore/uncore/gpio/gpio/GPIOIntr
add wave -noupdate -group CLINT /testbench/dut/uncore/uncore/clint/clint/MTIME
add wave -noupdate -group CLINT /testbench/dut/uncore/uncore/clint/clint/MTIMECMP
add wave -noupdate -group uart /testbench/dut/uncore/uncore/uart/uart/SIN
add wave -noupdate -group uart /testbench/dut/uncore/uncore/uart/uart/DSRb
add wave -noupdate -group uart /testbench/dut/uncore/uncore/uart/uart/DCDb
add wave -noupdate -group uart /testbench/dut/uncore/uncore/uart/uart/CTSb
add wave -noupdate -group uart /testbench/dut/uncore/uncore/uart/uart/RIb
add wave -noupdate -group uart -expand -group outputs /testbench/dut/uncore/uncore/uart/uart/SOUT
add wave -noupdate -group uart -expand -group outputs /testbench/dut/uncore/uncore/uart/uart/RTSb
add wave -noupdate -group uart -expand -group outputs /testbench/dut/uncore/uncore/uart/uart/DTRb
add wave -noupdate -group uart -expand -group outputs /testbench/dut/uncore/uncore/uart/uart/OUT1b
add wave -noupdate -group uart -expand -group outputs /testbench/dut/uncore/uncore/uart/uart/OUT2b
add wave -noupdate -group uart -expand -group outputs /testbench/dut/uncore/uncore/uart/uart/INTR
add wave -noupdate -group uart -expand -group outputs /testbench/dut/uncore/uncore/uart/uart/TXRDYb
add wave -noupdate -group uart -expand -group outputs /testbench/dut/uncore/uncore/uart/uart/RXRDYb
add wave -noupdate -group {debug trace} -expand -group mem -color Yellow /testbench/dut/core/FlushW
add wave -noupdate -group {debug trace} -expand -group mem /testbench/checkInstrM
add wave -noupdate -group {debug trace} -expand -group mem /testbench/dut/core/PCM
add wave -noupdate -group {debug trace} -expand -group mem /testbench/ExpectedPCM
add wave -noupdate -group {debug trace} -expand -group mem /testbench/textM
add wave -noupdate -group {debug trace} -expand -group mem -color Brown /testbench/dut/core/hzu/TrapM
add wave -noupdate -group {debug trace} -expand -group wb /testbench/checkInstrW
add wave -noupdate -group {debug trace} -expand -group wb /testbench/PCW
add wave -noupdate -group {debug trace} -expand -group wb /testbench/ExpectedPCW
add wave -noupdate -group {debug trace} -expand -group wb /testbench/TrapW
add wave -noupdate -group {debug trace} -expand -group wb /testbench/textW
add wave -noupdate -group {Performance Counters} -label MCYCLE -radix unsigned {/testbench/dut/core/priv/priv/csr/counters/counters/HPMCOUNTER_REGW[0]}
add wave -noupdate -group {Performance Counters} -label MINSTRET -radix unsigned {/testbench/dut/core/priv/priv/csr/counters/counters/HPMCOUNTER_REGW[2]}
add wave -noupdate -group {Performance Counters} -label {LOAD STORE HAZARD} -radix unsigned {/testbench/dut/core/priv/priv/csr/counters/counters/HPMCOUNTER_REGW[3]}
add wave -noupdate -group {Performance Counters} -expand -group BRP -label {BP DIRECTION WRONG} -radix unsigned {/testbench/dut/core/priv/priv/csr/counters/counters/HPMCOUNTER_REGW[4]}
add wave -noupdate -group {Performance Counters} -expand -group BRP -label {BP INSTRUCTION} -radix unsigned {/testbench/dut/core/priv/priv/csr/counters/counters/HPMCOUNTER_REGW[5]}
add wave -noupdate -group {Performance Counters} -expand -group BRP -label {BTA/JTA WRONG} -radix unsigned {/testbench/dut/core/priv/priv/csr/counters/counters/HPMCOUNTER_REGW[6]}
add wave -noupdate -group {Performance Counters} -expand -group BRP -label {JAL(R) INSTRUCTION} -radix unsigned {/testbench/dut/core/priv/priv/csr/counters/counters/HPMCOUNTER_REGW[7]}
add wave -noupdate -group {Performance Counters} -expand -group BRP -label {RAS WRONG} -radix unsigned {/testbench/dut/core/priv/priv/csr/counters/counters/HPMCOUNTER_REGW[8]}
add wave -noupdate -group {Performance Counters} -expand -group BRP -label {RETURN INSTRUCTION} -radix unsigned {/testbench/dut/core/priv/priv/csr/counters/counters/HPMCOUNTER_REGW[9]}
add wave -noupdate -group {Performance Counters} -expand -group BRP -label {BP CLASS WRONG} -radix unsigned {/testbench/dut/core/priv/priv/csr/counters/counters/HPMCOUNTER_REGW[10]}
add wave -noupdate -group {Performance Counters} -expand -group ICACHE -label {ICACHE ACCESS} -radix unsigned {/testbench/dut/core/priv/priv/csr/counters/counters/HPMCOUNTER_REGW[13]}
add wave -noupdate -group {Performance Counters} -expand -group ICACHE -label {ICACHE MISS} -radix unsigned {/testbench/dut/core/priv/priv/csr/counters/counters/HPMCOUNTER_REGW[14]}
add wave -noupdate -group {Performance Counters} -expand -group DCACHE -label {DCACHE ACCESS} -radix unsigned {/testbench/dut/core/priv/priv/csr/counters/counters/HPMCOUNTER_REGW[11]}
add wave -noupdate -group {Performance Counters} -expand -group DCACHE -label {DCACHE MISS} -radix unsigned {/testbench/dut/core/priv/priv/csr/counters/counters/HPMCOUNTER_REGW[12]}
add wave -noupdate /testbench/dut/core/lsu/test
add wave -noupdate {/testbench/dut/core/lsu/LSUHTRANS[1]}
add wave -noupdate /testbench/dut/core/lsu/LSUHADDR
add wave -noupdate /testbench/dut/core/lsu/LSUHTRANS
add wave -noupdate /testbench/dut/core/lsu/HRDATA
add wave -noupdate /testbench/dut/core/lsu/LSUHWDATA
add wave -noupdate /testbench/dut/core/lsu/LSUHWRITE
add wave -noupdate /testbench/dut/core/lsu/bus/dcache/dcache/CacheBusAck
add wave -noupdate /testbench/dut/core/lsu/bus/dcache/dcache/ClearDirty
add wave -noupdate /testbench/dut/core/lsu/bus/dcache/dcache/ClearDirty
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{invalid oad data} {15916799 ns} 1} {{original store} {4919493 ns} 1} {{correct load data} {15300495 ns} 1} {{Cursor 4} {4919381 ns} 1} {{Cursor 5} {4934568 ns} 0}
quietly wave cursor active 5
configure wave -namecolwidth 250
configure wave -valuecolwidth 314
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
WaveRestoreZoom {4934554 ns} {4934778 ns}
