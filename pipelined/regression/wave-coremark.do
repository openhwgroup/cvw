onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/reset
add wave -noupdate /testbench/test
add wave -noupdate /testbench/memfilename
add wave -noupdate /testbench/dut/core/SATP_REGW
add wave -noupdate -group {Execution Stage} /testbench/dut/core/ifu/PCE
add wave -noupdate -group {Execution Stage} /testbench/InstrEName
add wave -noupdate -group {Execution Stage} /testbench/dut/core/ifu/InstrE
add wave -noupdate -expand -group {Memory Stage} /testbench/dut/core/priv/trap/InstrValidM
add wave -noupdate -expand -group {Memory Stage} /testbench/dut/core/PCM
add wave -noupdate -expand -group {Memory Stage} /testbench/InstrMName
add wave -noupdate -expand -group {Memory Stage} /testbench/dut/core/InstrM
add wave -noupdate -expand -group {Memory Stage} /testbench/dut/core/lsu/MemAdrM
add wave -noupdate /testbench/dut/core/ieu/dp/ResultM
add wave -noupdate /testbench/dut/core/ieu/dp/ResultW
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/trap/InstrMisalignedFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/trap/InstrAccessFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/trap/IllegalInstrFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/trap/BreakpointFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/trap/LoadMisalignedFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/trap/StoreAmoMisalignedFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/trap/LoadAccessFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/trap/StoreAmoAccessFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/trap/EcallFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/trap/InstrPageFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/trap/LoadPageFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/trap/StorePageFaultM
add wave -noupdate -expand -group HDU -group traps /testbench/dut/core/priv/trap/InterruptM
add wave -noupdate -expand -group HDU -group interrupts /testbench/dut/core/priv/trap/PendingIntsM
add wave -noupdate -expand -group HDU -group interrupts /testbench/dut/core/priv/trap/CommittedM
add wave -noupdate -expand -group HDU -group interrupts /testbench/dut/core/priv/trap/InstrValidM
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/core/hzu/BPPredWrongE
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/core/hzu/CSRWritePendingDEM
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/core/hzu/RetM
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/core/hzu/TrapM
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/core/hzu/LoadStallD
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/core/hzu/StoreStallD
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/core/hzu/ICacheStallF
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/core/hzu/LSUStallM
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/core/MulDivStallD
add wave -noupdate -expand -group HDU -group Flush -color Yellow /testbench/dut/core/hzu/FlushF
add wave -noupdate -expand -group HDU -group Flush -color Yellow /testbench/dut/core/FlushD
add wave -noupdate -expand -group HDU -group Flush -color Yellow /testbench/dut/core/FlushE
add wave -noupdate -expand -group HDU -group Flush -color Yellow /testbench/dut/core/FlushM
add wave -noupdate -expand -group HDU -group Flush -color Yellow /testbench/dut/core/FlushW
add wave -noupdate -expand -group HDU -group Stall -color Orange /testbench/dut/core/StallF
add wave -noupdate -expand -group HDU -group Stall -color Orange /testbench/dut/core/StallD
add wave -noupdate -expand -group HDU -group Stall -color Orange /testbench/dut/core/StallE
add wave -noupdate -expand -group HDU -group Stall -color Orange /testbench/dut/core/StallM
add wave -noupdate -expand -group HDU -group Stall -color Orange /testbench/dut/core/StallW
add wave -noupdate -group Bpred -color Orange /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHR
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/BPPredF
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} {/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/InstrClassE[0]}
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} {/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/BPInstrClassE[0]}
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/BPPredDirWrongE
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} -divider {class check}
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/BPClassRightNonCFI
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/BPClassWrongCFI
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/BPClassWrongNonCFI
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/BPClassRightBPRight
add wave -noupdate -group Bpred -expand -group {branch update selection inputs} /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/BPClassRightBPWrong
add wave -noupdate -group Bpred -radix hexadecimal -childformat {{{/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[6]} -radix binary} {{/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[5]} -radix binary} {{/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[4]} -radix binary} {{/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[3]} -radix binary} {{/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[2]} -radix binary} {{/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[1]} -radix binary} {{/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[0]} -radix binary}} -subitemconfig {{/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[6]} {-height 16 -radix binary} {/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[5]} {-height 16 -radix binary} {/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[4]} {-height 16 -radix binary} {/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[3]} {-height 16 -radix binary} {/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[2]} {-height 16 -radix binary} {/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[1]} {-height 16 -radix binary} {/testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel[0]} {-height 16 -radix binary}} /testbench/dut/core/ifu/bpred/bpred/Predictor/DirPredictor/GHRMuxSel
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
add wave -noupdate -group {instruction pipeline} /testbench/InstrFName
add wave -noupdate -group {instruction pipeline} /testbench/dut/core/ifu/bus/icache/FinalInstrRawF
add wave -noupdate -group {instruction pipeline} /testbench/dut/core/ifu/InstrD
add wave -noupdate -group {instruction pipeline} /testbench/dut/core/ifu/InstrE
add wave -noupdate -group {instruction pipeline} /testbench/dut/core/ifu/InstrM
add wave -noupdate -group {instruction pipeline} /testbench/InstrW
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/PCNextF
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/PCF
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/PCPlus2or4F
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/BPPredPCF
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/PCNext0F
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/PCNext1F
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/SelBPPredF
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/BPPredWrongE
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/PrivilegedChangePCM
add wave -noupdate -group {Decode Stage} /testbench/dut/core/ifu/InstrD
add wave -noupdate -group {Decode Stage} /testbench/InstrDName
add wave -noupdate -group {Decode Stage} /testbench/dut/core/ieu/c/RegWriteD
add wave -noupdate -group {Decode Stage} /testbench/dut/core/ieu/dp/RdD
add wave -noupdate -group {Decode Stage} /testbench/dut/core/ieu/dp/Rs1D
add wave -noupdate -group {Decode Stage} /testbench/dut/core/ieu/dp/Rs2D
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
add wave -noupdate -group alu /testbench/dut/core/ieu/dp/alu/result
add wave -noupdate -group alu /testbench/dut/core/ieu/dp/alu/FlagsE
add wave -noupdate -group alu -divider internals
add wave -noupdate -group alu /testbench/dut/core/ieu/dp/alu/overflow
add wave -noupdate -group alu /testbench/dut/core/ieu/dp/alu/carry
add wave -noupdate -group alu /testbench/dut/core/ieu/dp/alu/zero
add wave -noupdate -group alu /testbench/dut/core/ieu/dp/alu/neg
add wave -noupdate -group alu /testbench/dut/core/ieu/dp/alu/lt
add wave -noupdate -group alu /testbench/dut/core/ieu/dp/alu/ltu
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
add wave -noupdate -group {alu execution stage} /testbench/dut/core/ieu/dp/WriteDataE
add wave -noupdate -group {alu execution stage} /testbench/dut/core/ieu/dp/ALUResultE
add wave -noupdate -group {alu execution stage} /testbench/dut/core/ieu/dp/SrcAE
add wave -noupdate -group {alu execution stage} /testbench/dut/core/ieu/dp/SrcBE
add wave -noupdate -group PCS /testbench/dut/core/ifu/PCNextF
add wave -noupdate -group PCS /testbench/dut/core/PCF
add wave -noupdate -group PCS /testbench/dut/core/ifu/PCD
add wave -noupdate -group PCS /testbench/dut/core/PCE
add wave -noupdate -group PCS /testbench/dut/core/PCM
add wave -noupdate -group PCS /testbench/PCW
add wave -noupdate -group muldiv /testbench/dut/core/mdu/Funct3E
add wave -noupdate -group muldiv /testbench/dut/core/mdu/MulDivE
add wave -noupdate -group muldiv /testbench/dut/core/mdu/W64E
add wave -noupdate -group muldiv /testbench/dut/core/mdu/StallM
add wave -noupdate -group muldiv /testbench/dut/core/mdu/StallW
add wave -noupdate -group muldiv /testbench/dut/core/mdu/FlushM
add wave -noupdate -group muldiv /testbench/dut/core/mdu/FlushW
add wave -noupdate -group muldiv /testbench/dut/core/mdu/MulDivResultW
add wave -noupdate -group muldiv /testbench/dut/core/mdu/DivBusyE
add wave -noupdate -group icache -color Gold /testbench/dut/core/ifu/bus/icache/controller/CurrState
add wave -noupdate -group icache /testbench/dut/core/ifu/bus/icache/BasePAdrF
add wave -noupdate -group icache /testbench/dut/core/ifu/bus/icache/HitWay
add wave -noupdate -group icache /testbench/dut/core/ifu/bus/icache/VictimWay
add wave -noupdate -group icache -expand -group {Cache SRAM writes} -group way0 {/testbench/dut/core/ifu/bus/icache/CacheWays[0]/WriteEnable}
add wave -noupdate -group icache -expand -group {Cache SRAM writes} -group way0 {/testbench/dut/core/ifu/bus/icache/CacheWays[0]/SetValid}
add wave -noupdate -group icache -expand -group {Cache SRAM writes} -group way0 -label TAG {/testbench/dut/core/ifu/bus/icache/CacheWays[0]/CacheTagMem/StoredData}
add wave -noupdate -group icache -expand -group {Cache SRAM writes} -group way0 {/testbench/dut/core/ifu/bus/icache/CacheWays[0]/ValidBits}
add wave -noupdate -group icache -expand -group {Cache SRAM writes} -group way0 -expand -group Way0Word0 {/testbench/dut/core/ifu/bus/icache/CacheWays[0]/word[0]/CacheDataMem/StoredData}
add wave -noupdate -group icache -expand -group {Cache SRAM writes} -group way0 -expand -group Way0Word0 {/testbench/dut/core/ifu/bus/icache/CacheWays[0]/word[0]/CacheDataMem/WriteEnable}
add wave -noupdate -group icache -expand -group {Cache SRAM writes} -group way0 -group Way0Word1 {/testbench/dut/core/ifu/bus/icache/CacheWays[0]/word[1]/CacheDataMem/StoredData}
add wave -noupdate -group icache -expand -group {Cache SRAM writes} -group way0 -group Way0Word1 {/testbench/dut/core/ifu/bus/icache/CacheWays[0]/word[1]/CacheDataMem/WriteEnable}
add wave -noupdate -group icache -expand -group {Cache SRAM writes} -group way0 -group Way0Word2 {/testbench/dut/core/ifu/bus/icache/CacheWays[0]/word[2]/CacheDataMem/WriteEnable}
add wave -noupdate -group icache -expand -group {Cache SRAM writes} -group way0 -group Way0Word2 {/testbench/dut/core/ifu/bus/icache/CacheWays[0]/word[2]/CacheDataMem/StoredData}
add wave -noupdate -group icache -expand -group {Cache SRAM writes} -group way0 -group Way0Word3 {/testbench/dut/core/ifu/bus/icache/CacheWays[0]/word[3]/CacheDataMem/WriteEnable}
add wave -noupdate -group icache -expand -group {Cache SRAM writes} -group way0 -group Way0Word3 {/testbench/dut/core/ifu/bus/icache/CacheWays[0]/word[3]/CacheDataMem/StoredData}
add wave -noupdate -group icache /testbench/dut/core/ifu/bus/icache/controller/NextState
add wave -noupdate -group icache /testbench/dut/core/ifu/ITLBMissF
add wave -noupdate -group icache /testbench/dut/core/ifu/bus/icache/ITLBWriteF
add wave -noupdate -group icache /testbench/dut/core/ifu/bus/icache/ReadLineF
add wave -noupdate -group icache /testbench/dut/core/ifu/bus/icache/ReadLineF
add wave -noupdate -group icache /testbench/dut/core/ifu/bus/icache/BasePAdrF
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/core/ifu/bus/icache/controller/hit
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/core/ifu/bus/icache/controller/spill
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/core/ifu/bus/icache/controller/ICacheStallF
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/core/ifu/bus/icache/controller/spillSave
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/core/ifu/bus/icache/controller/spillSave
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/core/ifu/bus/icache/controller/CntReset
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/core/ifu/bus/icache/controller/PreCntEn
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/core/ifu/bus/icache/controller/CntEn
add wave -noupdate -group icache -expand -group memory /testbench/dut/core/ifu/bus/icache/InstrPAdrF
add wave -noupdate -group icache -expand -group memory /testbench/dut/core/ifu/bus/icache/InstrInF
add wave -noupdate -group icache -expand -group memory /testbench/dut/core/ifu/bus/icache/controller/FetchCountFlag
add wave -noupdate -group icache -expand -group memory /testbench/dut/core/ifu/bus/icache/FetchCount
add wave -noupdate -group icache -expand -group memory /testbench/dut/core/ifu/bus/icache/controller/InstrReadF
add wave -noupdate -group icache -expand -group memory /testbench/dut/core/ifu/bus/icache/controller/InstrAckF
add wave -noupdate -group icache -expand -group memory /testbench/dut/core/ifu/bus/icache/controller/ICacheMemWriteEnable
add wave -noupdate -group icache -expand -group memory /testbench/dut/core/ifu/bus/icache/ICacheBusWriteData
add wave -noupdate -group AHB -color Gold /testbench/dut/core/ebu/BusState
add wave -noupdate -group AHB /testbench/dut/core/ebu/NextBusState
add wave -noupdate -group AHB -expand -group {input requests} /testbench/dut/core/ebu/AtomicMaskedM
add wave -noupdate -group AHB -expand -group {input requests} /testbench/dut/core/ebu/InstrReadF
add wave -noupdate -group AHB -expand -group {input requests} /testbench/dut/core/ebu/MemSizeM
add wave -noupdate -group AHB /testbench/dut/core/ebu/HCLK
add wave -noupdate -group AHB /testbench/dut/core/ebu/HRESETn
add wave -noupdate -group AHB /testbench/dut/core/ebu/HRDATA
add wave -noupdate -group AHB /testbench/dut/core/ebu/HREADY
add wave -noupdate -group AHB /testbench/dut/core/ebu/HRESP
add wave -noupdate -group AHB /testbench/dut/core/ebu/HADDR
add wave -noupdate -group AHB /testbench/dut/core/ebu/HWDATA
add wave -noupdate -group AHB /testbench/dut/core/ebu/HWRITE
add wave -noupdate -group AHB /testbench/dut/core/ebu/HSIZE
add wave -noupdate -group AHB /testbench/dut/core/ebu/HBURST
add wave -noupdate -group AHB /testbench/dut/core/ebu/HPROT
add wave -noupdate -group AHB /testbench/dut/core/ebu/HTRANS
add wave -noupdate -group AHB /testbench/dut/core/ebu/HMASTLOCK
add wave -noupdate -group AHB /testbench/dut/core/ebu/HADDRD
add wave -noupdate -group AHB /testbench/dut/core/ebu/HSIZED
add wave -noupdate -group AHB /testbench/dut/core/ebu/HWRITED
add wave -noupdate -group lsu -expand -group {LSU ARB} /testbench/dut/core/lsu/arbiter/SelPTW
add wave -noupdate -group lsu -expand -group dcache -color Gold /testbench/dut/core/lsu.bus.dcache/dcachefsm/CurrState
add wave -noupdate -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/WalkerPageFaultM
add wave -noupdate -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/WriteDataM
add wave -noupdate -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/SRAMBlockWriteEnableM
add wave -noupdate -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/SRAMWordWriteEnableM
add wave -noupdate -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/SRAMWayWriteEnable
add wave -noupdate -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/SRAMWordEnable
add wave -noupdate -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/SRAMBlockWayWriteEnableM
add wave -noupdate -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/SelAdrM
add wave -noupdate -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/ReadDataBlockM
add wave -noupdate -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/DCacheBusWriteData
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 {/testbench/dut/core/lsu.bus.dcache/CacheWays[0]/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 {/testbench/dut/core/lsu.bus.dcache/CacheWays[0]/SetValid}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 {/testbench/dut/core/lsu.bus.dcache/CacheWays[0]/SetDirty}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 -label TAG {/testbench/dut/core/lsu.bus.dcache/CacheWays[0]/CacheTagMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 {/testbench/dut/core/lsu.bus.dcache/CacheWays[0]/DirtyBits}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 {/testbench/dut/core/lsu.bus.dcache/CacheWays[0]/ValidBits}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 -expand -group Way0Word0 {/testbench/dut/core/lsu.bus.dcache/CacheWays[0]/word[0]/CacheDataMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 -expand -group Way0Word0 {/testbench/dut/core/lsu.bus.dcache/CacheWays[0]/word[0]/CacheDataMem/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 -expand -group Way0Word1 {/testbench/dut/core/lsu.bus.dcache/CacheWays[0]/word[1]/CacheDataMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 -expand -group Way0Word1 {/testbench/dut/core/lsu.bus.dcache/CacheWays[0]/word[1]/CacheDataMem/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 -expand -group Way0Word2 {/testbench/dut/core/lsu.bus.dcache/CacheWays[0]/word[2]/CacheDataMem/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 -expand -group Way0Word2 {/testbench/dut/core/lsu.bus.dcache/CacheWays[0]/word[2]/CacheDataMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 -expand -group Way0Word3 {/testbench/dut/core/lsu.bus.dcache/CacheWays[0]/word[3]/CacheDataMem/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 -expand -group Way0Word3 {/testbench/dut/core/lsu.bus.dcache/CacheWays[0]/word[3]/CacheDataMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/core/lsu.bus.dcache/CacheWays[1]/DirtyBits}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/core/lsu.bus.dcache/CacheWays[1]/SetDirty}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/core/lsu.bus.dcache/CacheWays[1]/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/core/lsu.bus.dcache/CacheWays[1]/WriteWordEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -label TAG {/testbench/dut/core/lsu.bus.dcache/CacheWays[1]/CacheTagMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word0 {/testbench/dut/core/lsu.bus.dcache/CacheWays[1]/word[0]/CacheDataMem/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word0 {/testbench/dut/core/lsu.bus.dcache/CacheWays[1]/word[0]/CacheDataMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word1 {/testbench/dut/core/lsu.bus.dcache/CacheWays[1]/word[1]/CacheDataMem/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word1 {/testbench/dut/core/lsu.bus.dcache/CacheWays[1]/word[1]/CacheDataMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word2 {/testbench/dut/core/lsu.bus.dcache/CacheWays[1]/word[2]/CacheDataMem/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word2 {/testbench/dut/core/lsu.bus.dcache/CacheWays[1]/word[2]/CacheDataMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word3 {/testbench/dut/core/lsu.bus.dcache/CacheWays[1]/word[3]/CacheDataMem/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word3 {/testbench/dut/core/lsu.bus.dcache/CacheWays[1]/word[3]/CacheDataMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/core/lsu.bus.dcache/CacheWays[2]/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/core/lsu.bus.dcache/CacheWays[2]/SetValid}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/core/lsu.bus.dcache/CacheWays[2]/SetDirty}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -label TAG {/testbench/dut/core/lsu.bus.dcache/CacheWays[2]/CacheTagMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/core/lsu.bus.dcache/CacheWays[2]/DirtyBits}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/core/lsu.bus.dcache/CacheWays[2]/ValidBits}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word0 {/testbench/dut/core/lsu.bus.dcache/CacheWays[2]/word[0]/CacheDataMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word0 {/testbench/dut/core/lsu.bus.dcache/CacheWays[2]/word[0]/CacheDataMem/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word1 {/testbench/dut/core/lsu.bus.dcache/CacheWays[2]/word[1]/CacheDataMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word1 {/testbench/dut/core/lsu.bus.dcache/CacheWays[2]/word[1]/CacheDataMem/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word2 {/testbench/dut/core/lsu.bus.dcache/CacheWays[2]/word[2]/CacheDataMem/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word2 {/testbench/dut/core/lsu.bus.dcache/CacheWays[2]/word[2]/CacheDataMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word3 {/testbench/dut/core/lsu.bus.dcache/CacheWays[2]/word[3]/CacheDataMem/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word3 {/testbench/dut/core/lsu.bus.dcache/CacheWays[2]/word[3]/CacheDataMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/CacheWays[3]/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/CacheWays[3]/SetValid}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/CacheWays[3]/SetDirty}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -label TAG {/testbench/dut/core/lsu.bus.dcache/CacheWays[3]/CacheTagMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/CacheWays[3]/DirtyBits}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/CacheWays[3]/ValidBits}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word0 {/testbench/dut/core/lsu.bus.dcache/CacheWays[3]/word[0]/CacheDataMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word0 {/testbench/dut/core/lsu.bus.dcache/CacheWays[3]/word[0]/CacheDataMem/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word1 {/testbench/dut/core/lsu.bus.dcache/CacheWays[3]/word[1]/CacheDataMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word1 {/testbench/dut/core/lsu.bus.dcache/CacheWays[3]/word[1]/CacheDataMem/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word2 {/testbench/dut/core/lsu.bus.dcache/CacheWays[3]/word[2]/CacheDataMem/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word2 {/testbench/dut/core/lsu.bus.dcache/CacheWays[3]/word[2]/CacheDataMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word3 {/testbench/dut/core/lsu.bus.dcache/CacheWays[3]/word[3]/CacheDataMem/WriteEnable}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word3 {/testbench/dut/core/lsu.bus.dcache/CacheWays[3]/word[3]/CacheDataMem/StoredData}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group valid/dirty /testbench/dut/core/lsu.bus.dcache/SetValid
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group valid/dirty /testbench/dut/core/lsu.bus.dcache/ClearValid
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group valid/dirty /testbench/dut/core/lsu.bus.dcache/SetDirty
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group valid/dirty /testbench/dut/core/lsu.bus.dcache/ClearDirty
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} -group way0 {/testbench/dut/core/lsu.bus.dcache/CacheWays[0]/HitWay}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} -group way0 {/testbench/dut/core/lsu.bus.dcache/CacheWays[0]/Valid}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} -group way0 {/testbench/dut/core/lsu.bus.dcache/CacheWays[0]/Dirty}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} -group way0 {/testbench/dut/core/lsu.bus.dcache/CacheWays[0]/ReadTag}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way1 {/testbench/dut/core/lsu.bus.dcache/CacheWays[1]/HitWay}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way1 {/testbench/dut/core/lsu.bus.dcache/CacheWays[1]/Valid}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way1 {/testbench/dut/core/lsu.bus.dcache/CacheWays[1]/Dirty}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way1 {/testbench/dut/core/lsu.bus.dcache/CacheWays[1]/ReadTag}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way2 {/testbench/dut/core/lsu.bus.dcache/CacheWays[2]/HitWay}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way2 {/testbench/dut/core/lsu.bus.dcache/CacheWays[2]/Valid}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way2 {/testbench/dut/core/lsu.bus.dcache/CacheWays[2]/Dirty}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way2 {/testbench/dut/core/lsu.bus.dcache/CacheWays[2]/ReadTag}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/CacheWays[3]/HitWay}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/CacheWays[3]/Valid}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/CacheWays[3]/Dirty}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/CacheWays[3]/ReadTag}
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} /testbench/dut/core/lsu.bus.dcache/HitWay
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} /testbench/dut/core/lsu.bus.dcache/ReadDataBlockWayMaskedM
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} /testbench/dut/core/lsu.bus.dcache/ReadDataWordM
add wave -noupdate -group lsu -expand -group dcache -group {Cache SRAM read} /testbench/dut/core/lsu.bus.dcache/ReadDataWordMuxM
add wave -noupdate -group lsu -expand -group dcache -group Victim /testbench/dut/core/lsu.bus.dcache/VictimTag
add wave -noupdate -group lsu -expand -group dcache -group Victim /testbench/dut/core/lsu.bus.dcache/VictimWay
add wave -noupdate -group lsu -expand -group dcache -group Victim /testbench/dut/core/lsu.bus.dcache/VictimDirtyWay
add wave -noupdate -group lsu -expand -group dcache -group Victim /testbench/dut/core/lsu.bus.dcache/VictimDirty
add wave -noupdate -group lsu -expand -group dcache -group {CPU side} /testbench/dut/core/lsu.bus.dcache/MemRWM
add wave -noupdate -group lsu -expand -group dcache -group {CPU side} /testbench/dut/core/lsu.bus.dcache/MemAdrE
add wave -noupdate -group lsu -expand -group dcache -group {CPU side} /testbench/dut/core/lsu.bus.dcache/MemPAdrM
add wave -noupdate -group lsu -expand -group dcache -group {CPU side} /testbench/dut/core/lsu.bus.dcache/Funct3M
add wave -noupdate -group lsu -expand -group dcache -group {CPU side} /testbench/dut/core/lsu.bus.dcache/Funct7M
add wave -noupdate -group lsu -expand -group dcache -group {CPU side} /testbench/dut/core/lsu.bus.dcache/AtomicM
add wave -noupdate -group lsu -expand -group dcache -group {CPU side} /testbench/dut/core/lsu.bus.dcache/FlushDCacheM
add wave -noupdate -group lsu -expand -group dcache -group {CPU side} /testbench/dut/core/lsu.bus.dcache/CacheableM
add wave -noupdate -group lsu -expand -group dcache -group {CPU side} /testbench/dut/core/lsu.bus.dcache/WriteDataM
add wave -noupdate -group lsu -expand -group dcache -group {CPU side} /testbench/dut/core/lsu.bus.dcache/ReadDataM
add wave -noupdate -group lsu -expand -group dcache -group {CPU side} /testbench/dut/core/lsu.bus.dcache/DCacheStallM
add wave -noupdate -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/FlushAdrFlag
add wave -noupdate -group lsu -expand -group dcache -group status /testbench/dut/core/lsu.bus.dcache/HitWay
add wave -noupdate -group lsu -expand -group dcache -group status -color {Medium Orchid} /testbench/dut/core/lsu.bus.dcache/CacheHit
add wave -noupdate -group lsu -expand -group dcache -group status /testbench/dut/core/lsu.bus.dcache/FetchCount
add wave -noupdate -group lsu -expand -group dcache -expand -group {Memory Side} /testbench/dut/core/lsu.bus.dcache/FetchCountFlag
add wave -noupdate -group lsu -expand -group dcache -expand -group {Memory Side} /testbench/dut/core/lsu.bus.dcache/AHBPAdr
add wave -noupdate -group lsu -expand -group dcache -expand -group {Memory Side} /testbench/dut/core/lsu.bus.dcache/AHBRead
add wave -noupdate -group lsu -expand -group dcache -expand -group {Memory Side} /testbench/dut/core/lsu.bus.dcache/AHBWrite
add wave -noupdate -group lsu -expand -group dcache -expand -group {Memory Side} /testbench/dut/core/lsu.bus.dcache/AHBAck
add wave -noupdate -group lsu -expand -group dcache -expand -group {Memory Side} /testbench/dut/core/lsu.bus.dcache/HRDATA
add wave -noupdate -group lsu -expand -group dcache -expand -group {Memory Side} /testbench/dut/core/lsu.bus.dcache/HWDATA
add wave -noupdate -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/genblk1/tlb/tlbcontrol/EffectivePrivilegeMode
add wave -noupdate -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/genblk1/tlb/tlbcontrol/Translate
add wave -noupdate -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/genblk1/tlb/tlbcontrol/DisableTranslation
add wave -noupdate -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/TLBMiss
add wave -noupdate -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/TLBHit
add wave -noupdate -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/PhysicalAddress
add wave -noupdate -group lsu -group dtlb -expand -group faults /testbench/dut/core/lsu/dmmu/TLBPageFault
add wave -noupdate -group lsu -group dtlb -expand -group faults /testbench/dut/core/lsu/dmmu/LoadAccessFaultM
add wave -noupdate -group lsu -group dtlb -expand -group faults /testbench/dut/core/lsu/dmmu/StoreAmoAccessFaultM
add wave -noupdate -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/genblk1/tlb/TLBPAdr
add wave -noupdate -group lsu -group dtlb -expand -group write /testbench/dut/core/lsu/dmmu/genblk1/tlb/PTE
add wave -noupdate -group lsu -group dtlb -expand -group write /testbench/dut/core/lsu/dmmu/genblk1/tlb/TLBWrite
add wave -noupdate -group lsu -group pma /testbench/dut/core/lsu/dmmu/pmachecker/PhysicalAddress
add wave -noupdate -group lsu -group pma /testbench/dut/core/lsu/dmmu/pmachecker/SelRegions
add wave -noupdate -group lsu -group pma /testbench/dut/core/lsu/dmmu/Cacheable
add wave -noupdate -group lsu -group pma /testbench/dut/core/lsu/dmmu/Idempotent
add wave -noupdate -group lsu -group pma /testbench/dut/core/lsu/dmmu/AtomicAllowed
add wave -noupdate -group lsu -group pma /testbench/dut/core/lsu/dmmu/pmachecker/PMAAccessFault
add wave -noupdate -group lsu -group pma /testbench/dut/core/lsu/dmmu/PMAInstrAccessFaultF
add wave -noupdate -group lsu -group pma /testbench/dut/core/lsu/dmmu/PMALoadAccessFaultM
add wave -noupdate -group lsu -group pma /testbench/dut/core/lsu/dmmu/PMAStoreAmoAccessFaultM
add wave -noupdate -group lsu -group pmp /testbench/dut/core/lsu/dmmu/PMPInstrAccessFaultF
add wave -noupdate -group lsu -group pmp /testbench/dut/core/lsu/dmmu/PMPLoadAccessFaultM
add wave -noupdate -group lsu -group pmp /testbench/dut/core/lsu/dmmu/PMPStoreAmoAccessFaultM
add wave -noupdate -group lsu -group ptwalker -color Gold /testbench/dut/core/lsu/hptw/genblk1/WalkerState
add wave -noupdate -group lsu -group ptwalker /testbench/dut/core/lsu/hptw/PCF
add wave -noupdate -group lsu -group ptwalker /testbench/dut/core/lsu/hptw/genblk1/TranslationVAdr
add wave -noupdate -group lsu -group ptwalker /testbench/dut/core/lsu/hptw/TranslationPAdr
add wave -noupdate -group lsu -group ptwalker /testbench/dut/core/lsu/hptw/HPTWReadPTE
add wave -noupdate -group lsu -group ptwalker /testbench/dut/core/lsu/hptw/PTE
add wave -noupdate -group lsu -group ptwalker -expand -group types /testbench/dut/core/lsu/hptw/ITLBMissF
add wave -noupdate -group lsu -group ptwalker -expand -group types /testbench/dut/core/lsu/hptw/DTLBMissM
add wave -noupdate -group lsu -group ptwalker -expand -group types /testbench/dut/core/lsu/hptw/ITLBWriteF
add wave -noupdate -group lsu -group ptwalker -expand -group types /testbench/dut/core/lsu/hptw/DTLBWriteM
add wave -noupdate -group lsu -group ptwalker -expand -group types /testbench/dut/core/lsu/hptw/WalkerInstrPageFaultF
add wave -noupdate -group lsu -group ptwalker -expand -group types /testbench/dut/core/lsu/hptw/WalkerLoadPageFaultM
add wave -noupdate -group lsu -group ptwalker -expand -group types /testbench/dut/core/lsu/hptw/WalkerStorePageFaultM
add wave -noupdate -group csr /testbench/dut/core/priv/csr/MIP_REGW
add wave -noupdate -group itlb /testbench/dut/core/ifu/immu/TLBWrite
add wave -noupdate -group itlb /testbench/dut/core/ifu/ITLBMissF
add wave -noupdate -group itlb /testbench/dut/core/ifu/immu/PhysicalAddress
add wave -noupdate /testbench/dut/core/lsu.bus.dcache/VAdr
add wave -noupdate /testbench/dut/core/lsu.bus.dcache/MemPAdrM
add wave -noupdate -group plic /testbench/dut/uncore/plic/plic/HCLK
add wave -noupdate -group plic /testbench/dut/uncore/plic/plic/HSELPLIC
add wave -noupdate -group plic /testbench/dut/uncore/plic/plic/HADDR
add wave -noupdate -group plic /testbench/dut/uncore/plic/plic/HWRITE
add wave -noupdate -group plic /testbench/dut/uncore/plic/plic/HREADY
add wave -noupdate -group plic /testbench/dut/uncore/plic/plic/HTRANS
add wave -noupdate -group plic /testbench/dut/uncore/plic/plic/HWDATA
add wave -noupdate -group plic /testbench/dut/uncore/plic/plic/UARTIntr
add wave -noupdate -group plic /testbench/dut/uncore/plic/plic/GPIOIntr
add wave -noupdate -group plic /testbench/dut/uncore/plic/plic/HREADPLIC
add wave -noupdate -group plic /testbench/dut/uncore/plic/plic/HRESPPLIC
add wave -noupdate -group plic /testbench/dut/uncore/plic/plic/HREADYPLIC
add wave -noupdate -group plic /testbench/dut/uncore/plic/plic/ExtIntM
add wave -noupdate -group GPIO /testbench/dut/uncore/gpio/gpio/HCLK
add wave -noupdate -group GPIO /testbench/dut/uncore/gpio/gpio/HSELGPIO
add wave -noupdate -group GPIO /testbench/dut/uncore/gpio/gpio/HADDR
add wave -noupdate -group GPIO /testbench/dut/uncore/gpio/gpio/HWDATA
add wave -noupdate -group GPIO /testbench/dut/uncore/gpio/gpio/HWRITE
add wave -noupdate -group GPIO /testbench/dut/uncore/gpio/gpio/HREADY
add wave -noupdate -group GPIO /testbench/dut/uncore/gpio/gpio/HTRANS
add wave -noupdate -group GPIO /testbench/dut/uncore/gpio/gpio/HREADGPIO
add wave -noupdate -group GPIO /testbench/dut/uncore/gpio/gpio/HRESPGPIO
add wave -noupdate -group GPIO /testbench/dut/uncore/gpio/gpio/HREADYGPIO
add wave -noupdate -group GPIO /testbench/dut/uncore/gpio/gpio/GPIOPinsIn
add wave -noupdate -group GPIO /testbench/dut/uncore/gpio/gpio/GPIOPinsOut
add wave -noupdate -group GPIO /testbench/dut/uncore/gpio/gpio/GPIOPinsEn
add wave -noupdate -group GPIO /testbench/dut/uncore/gpio/gpio/GPIOIntr
add wave -noupdate -group CLINT /testbench/dut/uncore/clint/clint/HCLK
add wave -noupdate -group CLINT /testbench/dut/uncore/clint/clint/HSELCLINT
add wave -noupdate -group CLINT /testbench/dut/uncore/clint/clint/HADDR
add wave -noupdate -group CLINT /testbench/dut/uncore/clint/clint/HWRITE
add wave -noupdate -group CLINT /testbench/dut/uncore/clint/clint/HWDATA
add wave -noupdate -group CLINT /testbench/dut/uncore/clint/clint/HREADY
add wave -noupdate -group CLINT /testbench/dut/uncore/clint/clint/HTRANS
add wave -noupdate -group CLINT /testbench/dut/uncore/clint/clint/HREADCLINT
add wave -noupdate -group CLINT /testbench/dut/uncore/clint/clint/HRESPCLINT
add wave -noupdate -group CLINT /testbench/dut/uncore/clint/clint/HREADYCLINT
add wave -noupdate -group CLINT /testbench/dut/uncore/clint/clint/MTIME
add wave -noupdate -group CLINT /testbench/dut/uncore/clint/clint/MTIMECMP
add wave -noupdate -group CLINT /testbench/dut/uncore/clint/clint/TimerIntM
add wave -noupdate -group CLINT /testbench/dut/uncore/clint/clint/SwIntM
add wave -noupdate -group uart /testbench/dut/uncore/uart/uart/HCLK
add wave -noupdate -group uart /testbench/dut/uncore/uart/uart/HRESETn
add wave -noupdate -group uart /testbench/dut/uncore/uart/uart/HSELUART
add wave -noupdate -group uart /testbench/dut/uncore/uart/uart/HADDR
add wave -noupdate -group uart /testbench/dut/uncore/uart/uart/HWRITE
add wave -noupdate -group uart /testbench/dut/uncore/uart/uart/HWDATA
add wave -noupdate -group uart /testbench/dut/uncore/uart/uart/HREADUART
add wave -noupdate -group uart /testbench/dut/uncore/uart/uart/HRESPUART
add wave -noupdate -group uart /testbench/dut/uncore/uart/uart/HREADYUART
add wave -noupdate -group uart /testbench/dut/uncore/uart/uart/SIN
add wave -noupdate -group uart /testbench/dut/uncore/uart/uart/DSRb
add wave -noupdate -group uart /testbench/dut/uncore/uart/uart/DCDb
add wave -noupdate -group uart /testbench/dut/uncore/uart/uart/CTSb
add wave -noupdate -group uart /testbench/dut/uncore/uart/uart/RIb
add wave -noupdate -group uart -expand -group outputs /testbench/dut/uncore/uart/uart/SOUT
add wave -noupdate -group uart -expand -group outputs /testbench/dut/uncore/uart/uart/RTSb
add wave -noupdate -group uart -expand -group outputs /testbench/dut/uncore/uart/uart/DTRb
add wave -noupdate -group uart -expand -group outputs /testbench/dut/uncore/uart/uart/OUT1b
add wave -noupdate -group uart -expand -group outputs /testbench/dut/uncore/uart/uart/OUT2b
add wave -noupdate -group uart -expand -group outputs /testbench/dut/uncore/uart/uart/INTR
add wave -noupdate -group uart -expand -group outputs /testbench/dut/uncore/uart/uart/TXRDYb
add wave -noupdate -group uart -expand -group outputs /testbench/dut/uncore/uart/uart/RXRDYb
add wave -noupdate -group UART /testbench/dut/uncore/uart/uart/HCLK
add wave -noupdate -group UART /testbench/dut/uncore/uart/uart/HSELUART
add wave -noupdate -group UART /testbench/dut/uncore/uart/uart/HADDR
add wave -noupdate -group UART /testbench/dut/uncore/uart/uart/HWRITE
add wave -noupdate -group UART /testbench/dut/uncore/uart/uart/HWDATA
add wave -noupdate -radix unsigned /testbench/dut/core/priv/csr/genblk1/counters/genblk1/CYCLE_REGW
add wave -noupdate -radix unsigned /testbench/dut/core/priv/csr/genblk1/counters/genblk1/INSTRET_REGW
add wave -noupdate -label LoadStall -radix unsigned {/testbench/dut/core/priv/csr/genblk1/counters/genblk1/HPMCOUNTER_REGW[3]}
add wave -noupdate -label {Branch Instr} -radix unsigned {/testbench/dut/core/priv/csr/genblk1/counters/genblk1/HPMCOUNTER_REGW[5]}
add wave -noupdate -label {BP Dir Wrong} -radix unsigned {/testbench/dut/core/priv/csr/genblk1/counters/genblk1/HPMCOUNTER_REGW[4]}
add wave -noupdate -label {Jump, Jal, Jalr} -radix unsigned {/testbench/dut/core/priv/csr/genblk1/counters/genblk1/HPMCOUNTER_REGW[7]}
add wave -noupdate -label {RAS Wrong} -radix unsigned {/testbench/dut/core/priv/csr/genblk1/counters/genblk1/HPMCOUNTER_REGW[8]}
add wave -noupdate -label {BTB Wrong} -radix unsigned {/testbench/dut/core/priv/csr/genblk1/counters/genblk1/HPMCOUNTER_REGW[6]}
add wave -noupdate -label {BP Class Non CFI Wrong} -radix unsigned {/testbench/dut/core/priv/csr/genblk1/counters/genblk1/HPMCOUNTER_REGW[10]}
add wave -noupdate -label DCacheAccess -radix unsigned {/testbench/dut/core/priv/csr/genblk1/counters/genblk1/HPMCOUNTER_REGW[11]}
add wave -noupdate -label DCacheMiss -radix unsigned {/testbench/dut/core/priv/csr/genblk1/counters/genblk1/HPMCOUNTER_REGW[12]}
add wave -noupdate -label Return -radix unsigned {/testbench/dut/core/priv/csr/genblk1/counters/genblk1/HPMCOUNTER_REGW[9]}
add wave -noupdate /testbench/dut/core/priv/csr/genblk1/counters/genblk1/HPMCOUNTER_REGW
add wave -noupdate /testbench/dut/core/priv/csr/genblk1/counters/MCOUNTINHIBIT_REGW
add wave -noupdate /testbench/dut/core/priv/csr/genblk1/counters/InstrValidM
add wave -noupdate /testbench/dut/core/priv/csr/genblk1/counters/genblk1/InstrValidNotFlushedM
add wave -noupdate /testbench/dut/core/priv/csr/genblk1/counters/BPPredDirWrongM
add wave -noupdate /testbench/dut/core/priv/csr/genblk1/counters/genblk1/genblk1/genblk1/LoadStallM
add wave -noupdate /testbench/dut/core/priv/csr/genblk1/counters/genblk1/genblk1/NextHPMCOUNTERM
add wave -noupdate /testbench/dut/core/priv/csr/genblk1/counters/DCacheMiss
add wave -noupdate /testbench/dut/core/priv/csr/genblk1/counters/DCacheAccess
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 6} {17923831 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 250
configure wave -valuecolwidth 297
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
WaveRestoreZoom {0 ns} {18715695 ns}
