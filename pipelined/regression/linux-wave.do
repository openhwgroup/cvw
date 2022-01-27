onerror {resume}
quietly virtual function -install /testbench/dut/core/ifu -env /testbench/dut/core/ifu { &{/testbench/dut/core/ifu/BPPredWrongM, /testbench/dut/core/ifu/InvalidateICacheM }} temp
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/reset
add wave -noupdate /testbench/reset_ext
add wave -noupdate -radix unsigned /testbench/InstrCountW
add wave -noupdate /testbench/dut/core/SATP_REGW
add wave -noupdate /testbench/dut/core/IllegalFPUInstrD
add wave -noupdate -group HDU -expand -group hazards /testbench/dut/core/hzu/BPPredWrongE
add wave -noupdate -group HDU -expand -group hazards /testbench/dut/core/hzu/CSRWritePendingDEM
add wave -noupdate -group HDU -expand -group hazards /testbench/dut/core/hzu/RetM
add wave -noupdate -group HDU -expand -group hazards -color Pink /testbench/dut/core/hzu/TrapM
add wave -noupdate -group HDU -expand -group hazards /testbench/dut/core/hzu/LoadStallD
add wave -noupdate -group HDU -expand -group hazards /testbench/dut/core/hzu/StoreStallD
add wave -noupdate -group HDU -expand -group hazards /testbench/dut/core/hzu/LSUStallM
add wave -noupdate -group HDU -expand -group hazards /testbench/dut/core/hzu/DivBusyE
add wave -noupdate -group HDU -expand -group traps /testbench/dut/core/priv/priv/trap/ExceptionM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/core/priv/priv/trap/InstrMisalignedFaultM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/core/priv/priv/trap/InstrAccessFaultM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/core/priv/priv/trap/IllegalInstrFaultM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/core/priv/priv/trap/LoadAccessFaultM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/core/priv/priv/trap/StoreAmoMisalignedFaultM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/core/priv/priv/trap/InstrPageFaultM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/core/priv/priv/trap/LoadPageFaultM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/core/priv/priv/trap/StorePageFaultM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/core/priv/priv/trap/BreakpointFaultM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/core/priv/priv/trap/EcallFaultM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/core/priv/priv/trap/LoadMisalignedFaultM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/core/priv/priv/trap/StoreAmoAccessFaultM
add wave -noupdate -group HDU -expand -group Flush -color Yellow /testbench/dut/core/hzu/FlushF
add wave -noupdate -group HDU -expand -group Flush -color Yellow /testbench/dut/core/FlushD
add wave -noupdate -group HDU -expand -group Flush -color Yellow /testbench/dut/core/FlushE
add wave -noupdate -group HDU -expand -group Flush -color Yellow /testbench/dut/core/FlushM
add wave -noupdate -group HDU -expand -group Flush -color Yellow /testbench/dut/core/FlushW
add wave -noupdate -group HDU -expand -group Stall -color Orange /testbench/dut/core/StallF
add wave -noupdate -group HDU -expand -group Stall -color Orange /testbench/dut/core/StallD
add wave -noupdate -group HDU -expand -group Stall -color Orange /testbench/dut/core/StallE
add wave -noupdate -group HDU -expand -group Stall -color Orange /testbench/dut/core/StallM
add wave -noupdate -group HDU -expand -group Stall -color Orange /testbench/dut/core/StallW
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
add wave -noupdate -group {Execution Stage} /testbench/MepcExpected
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
add wave -noupdate -group PCS /testbench/dut/core/ifu/PCNextF
add wave -noupdate -group PCS /testbench/dut/core/PCF
add wave -noupdate -group PCS /testbench/dut/core/ifu/PCD
add wave -noupdate -group PCS /testbench/dut/core/PCE
add wave -noupdate -group PCS /testbench/dut/core/PCM
add wave -noupdate -group PCS /testbench/PCW
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/PCNextF
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/PCF
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/PCPlus2or4F
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/BPPredPCF
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/PCNext0F
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/PCNext1F
add wave -noupdate -group {PCNext Generation} /testbench/dut/core/ifu/SelBPPredF
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
add wave -noupdate -group {alu execution stage} /testbench/dut/core/ieu/dp/WriteDataE
add wave -noupdate -group {alu execution stage} /testbench/dut/core/ieu/dp/ALUResultE
add wave -noupdate -group {alu execution stage} /testbench/dut/core/ieu/dp/SrcAE
add wave -noupdate -group {alu execution stage} /testbench/dut/core/ieu/dp/SrcBE
add wave -noupdate -group icache -color Gold /testbench/dut/core/ifu/icache/icache/cachefsm/CurrState
add wave -noupdate -group icache /testbench/dut/core/ifu/icache/icache/ReadDataWord
add wave -noupdate -group icache /testbench/dut/core/ifu/icache/icache/SelAdr
add wave -noupdate -group icache /testbench/dut/core/ifu/icache/icache/RAdr
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/core/ifu/icache/icache/CacheHit
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/core/ifu/icache/icache/CacheStall
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/core/ifu/icache/icache/ReadDataLineSets
add wave -noupdate -group icache -expand -group memory /testbench/dut/core/ifu/icache/icache/CacheMemWriteData
add wave -noupdate -group icache /testbench/dut/core/ifu/SpillSupport/SpillDataLine0
add wave -noupdate -group AHB -color Gold /testbench/dut/core/ebu/BusState
add wave -noupdate -group AHB /testbench/dut/core/ebu/NextBusState
add wave -noupdate -group AHB -expand -group {input requests} /testbench/dut/core/ebu/AtomicMaskedM
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
add wave -noupdate -group AMO_ALU /testbench/dut/core/lsu/amo/amoalu/funct
add wave -noupdate -group AMO_ALU /testbench/dut/core/lsu/amo/amoalu/result
add wave -noupdate -group AMO_ALU /testbench/dut/core/lsu/amo/amoalu/srca
add wave -noupdate -group AMO_ALU /testbench/dut/core/lsu/amo/amoalu/srcb
add wave -noupdate -group AMO_ALU /testbench/dut/core/lsu/amo/amoalu/width
add wave -noupdate -expand -group lsu -color Gold /testbench/dut/core/lsu/MEM_VIRTMEM/interlockfsm/InterlockCurrState
add wave -noupdate -expand -group lsu /testbench/dut/core/lsu/SelHPTW
add wave -noupdate -expand -group lsu /testbench/dut/core/lsu/InterlockStall
add wave -noupdate -expand -group lsu /testbench/dut/core/lsu/LSUStallM
add wave -noupdate -expand -group lsu /testbench/dut/core/lsu/ReadDataM
add wave -noupdate -expand -group lsu /testbench/dut/core/lsu/WriteDataM
add wave -noupdate -expand -group lsu -expand -group dcache -color Gold /testbench/dut/core/lsu.bus.dcache/dcache/cachefsm/CurrState
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/dcache/FinalWriteData
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/dcache/SRAMWayWriteEnable
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/dcache/SRAMWordEnable
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/dcache/SelAdr
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu/MEM_VIRTMEM/SelReplayCPURequest
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu/IEUAdrE
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu/IEUAdrM
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/dcache/RAdr
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group flush -radix unsigned /testbench/dut/core/lsu.bus.dcache/dcache/FlushAdr
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group flush /testbench/dut/core/lsu.bus.dcache/dcache/VictimDirtyWay
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group flush /testbench/dut/core/lsu.bus.dcache/dcache/VictimTag
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group flush /testbench/dut/core/lsu.bus.dcache/dcache/CacheBusAdr
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group flush /testbench/dut/core/lsu/WordCount
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group flush /testbench/dut/core/lsu.bus.dcache/dcache/FlushAdr
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group flush /testbench/dut/core/lsu.bus.dcache/dcache/FlushWay
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/dcache/CacheMemWriteData
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/dcache/WayHit
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/core/lsu.bus.dcache/dcache/IgnoreRequest
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[0]/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[0]/SetValid}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[0]/SetDirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 -label TAG {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[0]/CacheTagMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[0]/DirtyBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[0]/ValidBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 -expand -group Way0Word0 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[0]/word[0]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 -expand -group Way0Word0 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[0]/word[0]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 -expand -group Way0Word1 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[0]/word[1]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 -expand -group Way0Word1 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[0]/word[1]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 -expand -group Way0Word2 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[0]/word[2]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 -expand -group Way0Word2 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[0]/word[2]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 -expand -group Way0Word3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[0]/word[3]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way0 -expand -group Way0Word3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[0]/word[3]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[1]/DirtyBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[1]/ValidBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[1]/SetDirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[1]/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[1]/WriteWordEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -label TAG {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[1]/CacheTagMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word0 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[1]/word[0]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word0 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[1]/word[0]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word1 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[1]/word[1]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word1 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[1]/word[1]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word2 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[1]/word[2]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word2 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[1]/word[2]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[1]/word[3]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[1]/word[3]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[2]/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[2]/SetValid}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[2]/SetDirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -label TAG {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[2]/CacheTagMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[2]/DirtyBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[2]/ValidBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word0 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[2]/word[0]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word0 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[2]/word[0]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word1 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[2]/word[1]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word1 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[2]/word[1]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word2 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[2]/word[2]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word2 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[2]/word[2]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[2]/word[3]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[2]/word[3]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/SetValid}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/SetDirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/ClearDirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/VDWriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -label TAG {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/CacheTagMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/DirtyBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/ValidBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word0 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/word[0]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word0 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/word[0]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word1 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/word[1]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word1 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/word[1]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word2 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/word[2]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word2 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/word[2]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/word[3]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/word[3]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group valid/dirty /testbench/dut/core/lsu.bus.dcache/dcache/SetValid
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group valid/dirty /testbench/dut/core/lsu.bus.dcache/dcache/ClearValid
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group valid/dirty /testbench/dut/core/lsu.bus.dcache/dcache/SetDirty
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group valid/dirty /testbench/dut/core/lsu.bus.dcache/dcache/ClearDirty
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} /testbench/dut/core/lsu.bus.dcache/dcache/RAdr
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way0 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[0]/WayHit}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way0 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[0]/Valid}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way0 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[0]/Dirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way0 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[0]/ReadTag}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way1 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[1]/WayHit}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way1 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[1]/Valid}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way1 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[1]/Dirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way1 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[1]/ReadTag}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way2 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[2]/WayHit}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way2 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[2]/Valid}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way2 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[2]/Dirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way2 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[2]/ReadTag}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/WayHit}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/Valid}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/Dirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way3 {/testbench/dut/core/lsu.bus.dcache/dcache/MemWay[3]/ReadTag}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} /testbench/dut/core/lsu.bus.dcache/dcache/WayHit
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} /testbench/dut/core/lsu.bus.dcache/dcache/ReadDataWord
add wave -noupdate -expand -group lsu -expand -group dcache -group Victim /testbench/dut/core/lsu.bus.dcache/dcache/VictimTag
add wave -noupdate -expand -group lsu -expand -group dcache -group Victim /testbench/dut/core/lsu.bus.dcache/dcache/VictimWay
add wave -noupdate -expand -group lsu -expand -group dcache -group Victim /testbench/dut/core/lsu.bus.dcache/dcache/VictimDirtyWay
add wave -noupdate -expand -group lsu -expand -group dcache -group Victim /testbench/dut/core/lsu.bus.dcache/dcache/VictimDirty
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/core/lsu.bus.dcache/dcache/RW
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/core/lsu/IEUAdrM
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/core/lsu.bus.dcache/dcache/FlushCache
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/core/lsu.bus.dcache/dcache/FinalWriteData
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/core/lsu.bus.dcache/dcache/ReadDataWord
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/core/lsu.bus.dcache/dcache/CacheStall
add wave -noupdate -expand -group lsu -expand -group dcache -group status /testbench/dut/core/lsu.bus.dcache/dcache/WayHit
add wave -noupdate -expand -group lsu -expand -group dcache -group status -color {Medium Orchid} /testbench/dut/core/lsu.bus.dcache/dcache/CacheHit
add wave -noupdate -expand -group lsu -expand -group dcache -group status /testbench/dut/core/lsu/WordCount
add wave -noupdate -expand -group lsu -expand -group dcache -group {Memory Side} /testbench/dut/core/lsu.bus.dcache/dcache/CacheBusAdr
add wave -noupdate -expand -group lsu -expand -group dcache -group {Memory Side} /testbench/dut/core/lsu.bus.dcache/dcache/CacheFetchLine
add wave -noupdate -expand -group lsu -expand -group dcache -group {Memory Side} /testbench/dut/core/lsu.bus.dcache/dcache/CacheWriteLine
add wave -noupdate -expand -group lsu -expand -group dcache -group {Memory Side} /testbench/dut/core/lsu.bus.dcache/dcache/CacheBusAck
add wave -noupdate -expand -group lsu -expand -group dcache -group {Memory Side} /testbench/dut/core/lsu.bus.dcache/dcache/CacheMemWriteData
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/tlbcontrol/EffectivePrivilegeMode
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/tlbcontrol/Translate
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/tlbcontrol/DisableTranslation
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/dmmu/TLBMiss
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/dmmu/TLBHit
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/dmmu/PhysicalAddress
add wave -noupdate -expand -group lsu -group dtlb -expand -group faults /testbench/dut/core/lsu/dmmu/dmmu/TLBPageFault
add wave -noupdate -expand -group lsu -group dtlb -expand -group faults /testbench/dut/core/lsu/dmmu/dmmu/LoadAccessFaultM
add wave -noupdate -expand -group lsu -group dtlb -expand -group faults /testbench/dut/core/lsu/dmmu/dmmu/StoreAmoAccessFaultM
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/TLBPAdr
add wave -noupdate -expand -group lsu -group dtlb -expand -group write /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/PTE
add wave -noupdate -expand -group lsu -group dtlb -expand -group write /testbench/dut/core/lsu/dmmu/dmmu/tlb/tlb/TLBWrite
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
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/core/lsu/dmmu/dmmu/pmpchecker/pmpchecker/Match
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/core/lsu/dmmu/dmmu/pmpchecker/pmpchecker/FirstMatch
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/core/lsu/dmmu/dmmu/pmpchecker/pmpchecker/R
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/core/lsu/dmmu/dmmu/pmpchecker/pmpchecker/W
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/core/lsu/dmmu/dmmu/pmpchecker/pmpchecker/X
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/core/lsu/dmmu/dmmu/pmpchecker/pmpchecker/L
add wave -noupdate -expand -group lsu -group ptwalker -color Gold /testbench/dut/core/lsu/MEM_VIRTMEM/hptw/WalkerState
add wave -noupdate -expand -group lsu -group ptwalker /testbench/dut/core/lsu/MEM_VIRTMEM/hptw/PCF
add wave -noupdate -expand -group lsu -group ptwalker /testbench/dut/core/lsu/MEM_VIRTMEM/hptw/HPTWAdr
add wave -noupdate -expand -group lsu -group ptwalker /testbench/dut/core/lsu/MEM_VIRTMEM/hptw/HPTWReadPTE
add wave -noupdate -expand -group lsu -group ptwalker /testbench/dut/core/lsu/MEM_VIRTMEM/hptw/HPTWAdr
add wave -noupdate -expand -group lsu -group ptwalker /testbench/dut/core/lsu/MEM_VIRTMEM/hptw/PTE
add wave -noupdate -expand -group lsu -group ptwalker -expand -group types /testbench/dut/core/lsu/MEM_VIRTMEM/hptw/ITLBMissF
add wave -noupdate -expand -group lsu -group ptwalker -expand -group types /testbench/dut/core/lsu/MEM_VIRTMEM/hptw/DTLBMissM
add wave -noupdate -expand -group lsu -group ptwalker -expand -group types /testbench/dut/core/lsu/MEM_VIRTMEM/hptw/ITLBWriteF
add wave -noupdate -expand -group lsu -group ptwalker -expand -group types /testbench/dut/core/lsu/MEM_VIRTMEM/hptw/DTLBWriteM
add wave -noupdate -group itlb /testbench/dut/core/ifu/immu/TLBWrite
add wave -noupdate -group itlb /testbench/dut/core/ifu/ITLBMissF
add wave -noupdate -group itlb /testbench/dut/core/ifu/immu/PhysicalAddress
add wave -noupdate -group itlb /testbench/dut/core/ifu/immu/PMAInstrAccessFaultF
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
add wave -noupdate -group {pc selection} /testbench/dut/core/ifu/PCNext2F
add wave -noupdate -group {pc selection} /testbench/dut/core/ifu/PrivilegedNextPCM
add wave -noupdate -group {pc selection} /testbench/dut/core/ifu/PrivilegedChangePCM
add wave -noupdate /testbench/dut/core/ifu/PCCorrectE
add wave -noupdate /testbench/dut/core/ifu/PCSrcE
add wave -noupdate /testbench/dut/core/ieu/c/BranchTakenE
add wave -noupdate /testbench/dut/core/ieu/c/BranchE
add wave -noupdate /testbench/dut/core/ifu/PCLinkE
add wave -noupdate /testbench/dut/core/ifu/PCF
add wave -noupdate /testbench/dut/uncore/uart/uart/u/LSR
add wave -noupdate /testbench/dut/uncore/uart/uart/u/DLM
add wave -noupdate /testbench/dut/uncore/uart/uart/u/DLAB
add wave -noupdate /testbench/dut/core/ifu/temp
add wave -noupdate /testbench/dut/core/ifu/BPPredWrongM
add wave -noupdate /testbench/dut/core/ifu/InvalidateICacheM
add wave -noupdate -expand -group ifu /testbench/dut/core/ifu/PCF
add wave -noupdate -expand -group ifu /testbench/dut/core/ifu/PostSpillInstrRawF
add wave -noupdate -expand -group ifu -expand -group {Bus FSM} -color Gold /testbench/dut/core/ifu/busfsm/BusCurrState
add wave -noupdate -expand -group ifu -expand -group {Bus FSM} /testbench/dut/core/ifu/BusStall
add wave -noupdate -expand -group ifu -expand -group Spills /testbench/dut/core/ifu/SpillSupport/Spill
add wave -noupdate -expand -group ifu -expand -group Spills -color Gold /testbench/dut/core/ifu/SpillSupport/CurrState
add wave -noupdate /testbench/dut/core/lsu.bus.dcache/dcache/VictimTag
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 6} {5187387 ns} 1} {{Cursor 5} {88705641 ns} 0}
quietly wave cursor active 2
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
WaveRestoreZoom {88705577 ns} {88705705 ns}
