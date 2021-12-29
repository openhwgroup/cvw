onerror {resume}
quietly virtual function -install /testbench/dut/hart/ifu -env /testbench/dut/hart/ifu { &{/testbench/dut/hart/ifu/BPPredWrongM, /testbench/dut/hart/ifu/InvalidateICacheM }} temp
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/reset
add wave -noupdate /testbench/reset_ext
add wave -noupdate /testbench/dut/hart/SATP_REGW
add wave -noupdate -group HDU -expand -group hazards /testbench/dut/hart/hzu/BPPredWrongE
add wave -noupdate -group HDU -expand -group hazards /testbench/dut/hart/hzu/CSRWritePendingDEM
add wave -noupdate -group HDU -expand -group hazards /testbench/dut/hart/hzu/RetM
add wave -noupdate -group HDU -expand -group hazards -color Pink /testbench/dut/hart/hzu/TrapM
add wave -noupdate -group HDU -expand -group hazards /testbench/dut/hart/hzu/LoadStallD
add wave -noupdate -group HDU -expand -group hazards /testbench/dut/hart/hzu/StoreStallD
add wave -noupdate -group HDU -expand -group hazards /testbench/dut/hart/hzu/ICacheStallF
add wave -noupdate -group HDU -expand -group hazards /testbench/dut/hart/hzu/LSUStall
add wave -noupdate -group HDU -expand -group hazards /testbench/dut/hart/MulDivStallD
add wave -noupdate -group HDU -expand -group hazards /testbench/dut/hart/hzu/DivBusyE
add wave -noupdate -group HDU -expand -group traps /testbench/dut/hart/priv/priv/trap/PendingInterruptM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/hart/priv/priv/trap/InterruptM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/hart/priv/priv/BreakpointFaultM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/hart/priv/priv/DTLBLoadPageFaultM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/hart/priv/priv/DTLBStorePageFaultM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/hart/priv/priv/ebreakM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/hart/priv/priv/EcallFaultM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/hart/priv/priv/ecallM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/hart/priv/priv/ExceptionM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/hart/priv/priv/IllegalCSRAccessM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/hart/priv/priv/IllegalFPUInstrM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/hart/priv/priv/IllegalIEUInstrFaultM
add wave -noupdate -group HDU -expand -group traps /testbench/dut/hart/priv/priv/InstrAccessFaultM
add wave -noupdate -group HDU -expand -group Flush -color Yellow /testbench/dut/hart/hzu/FlushF
add wave -noupdate -group HDU -expand -group Flush -color Yellow /testbench/dut/hart/FlushD
add wave -noupdate -group HDU -expand -group Flush -color Yellow /testbench/dut/hart/FlushE
add wave -noupdate -group HDU -expand -group Flush -color Yellow /testbench/dut/hart/FlushM
add wave -noupdate -group HDU -expand -group Flush -color Yellow /testbench/dut/hart/FlushW
add wave -noupdate -group HDU -expand -group Stall -color Orange /testbench/dut/hart/StallF
add wave -noupdate -group HDU -expand -group Stall -color Orange /testbench/dut/hart/StallD
add wave -noupdate -group HDU -expand -group Stall -color Orange /testbench/dut/hart/StallE
add wave -noupdate -group HDU -expand -group Stall -color Orange /testbench/dut/hart/StallM
add wave -noupdate -group HDU -expand -group Stall -color Orange /testbench/dut/hart/StallW
add wave -noupdate -group {instruction pipeline} /testbench/InstrFName
add wave -noupdate -group {instruction pipeline} /testbench/dut/hart/ifu/icache/FinalInstrRawF
add wave -noupdate -group {instruction pipeline} /testbench/dut/hart/ifu/InstrD
add wave -noupdate -group {instruction pipeline} /testbench/dut/hart/ifu/InstrE
add wave -noupdate -group {instruction pipeline} /testbench/dut/hart/ifu/InstrM
add wave -noupdate -group {Decode Stage} /testbench/dut/hart/ifu/PCD
add wave -noupdate -group {Decode Stage} /testbench/dut/hart/ifu/InstrD
add wave -noupdate -group {Decode Stage} /testbench/InstrDName
add wave -noupdate -group {Decode Stage} /testbench/dut/hart/ieu/c/InstrValidD
add wave -noupdate -group {Decode Stage} /testbench/dut/hart/ieu/c/RegWriteD
add wave -noupdate -group {Decode Stage} /testbench/dut/hart/ieu/dp/RdD
add wave -noupdate -group {Decode Stage} /testbench/dut/hart/ieu/dp/Rs1D
add wave -noupdate -group {Decode Stage} /testbench/dut/hart/ieu/dp/Rs2D
add wave -noupdate -group {Execution Stage} /testbench/dut/hart/ifu/PCE
add wave -noupdate -group {Execution Stage} /testbench/dut/hart/ifu/InstrE
add wave -noupdate -group {Execution Stage} /testbench/InstrEName
add wave -noupdate -group {Execution Stage} /testbench/dut/hart/ieu/c/InstrValidE
add wave -noupdate -expand -group {Memory Stage} /testbench/dut/hart/PCM
add wave -noupdate -expand -group {Memory Stage} /testbench/dut/hart/InstrM
add wave -noupdate -expand -group {Memory Stage} /testbench/InstrMName
add wave -noupdate -expand -group {Memory Stage} /testbench/dut/hart/lsu/IEUAdrM
add wave -noupdate -group {WriteBack stage} /testbench/PCW
add wave -noupdate -group {WriteBack stage} /testbench/InstrW
add wave -noupdate -group {WriteBack stage} /testbench/InstrWName
add wave -noupdate -group Bpred -color Orange /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/GHR
add wave -noupdate -group Bpred -group {branch update selection inputs} /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/BPPredF
add wave -noupdate -group Bpred -group {branch update selection inputs} {/testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/InstrClassE[0]}
add wave -noupdate -group Bpred -group {branch update selection inputs} {/testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/BPInstrClassE[0]}
add wave -noupdate -group Bpred -group {branch update selection inputs} /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/BPPredDirWrongE
add wave -noupdate -group Bpred -group {branch update selection inputs} -divider {class check}
add wave -noupdate -group Bpred -group {branch update selection inputs} /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/BPClassRightNonCFI
add wave -noupdate -group Bpred -group {branch update selection inputs} /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/BPClassWrongCFI
add wave -noupdate -group Bpred -group {branch update selection inputs} /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/BPClassWrongNonCFI
add wave -noupdate -group Bpred -group {branch update selection inputs} /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/BPClassRightBPRight
add wave -noupdate -group Bpred -group {branch update selection inputs} /testbench/dut/hart/ifu/bpred/bpred/Predictor/DirPredictor/BPClassRightBPWrong
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
add wave -noupdate -group PCS /testbench/dut/hart/ifu/PCNextF
add wave -noupdate -group PCS /testbench/dut/hart/PCF
add wave -noupdate -group PCS /testbench/dut/hart/ifu/PCD
add wave -noupdate -group PCS /testbench/dut/hart/PCE
add wave -noupdate -group PCS /testbench/dut/hart/PCM
add wave -noupdate -group PCS /testbench/PCW
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/PCNextF
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/PCF
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/PCPlus2or4F
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/BPPredPCF
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/PCNext0F
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/PCNext1F
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/SelBPPredF
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/BPPredWrongE
add wave -noupdate -group {PCNext Generation} /testbench/dut/hart/ifu/PrivilegedChangePCM
add wave -noupdate -group RegFile -expand /testbench/dut/hart/ieu/dp/regf/rf
add wave -noupdate -group RegFile /testbench/dut/hart/ieu/dp/regf/a1
add wave -noupdate -group RegFile /testbench/dut/hart/ieu/dp/regf/a2
add wave -noupdate -group RegFile /testbench/dut/hart/ieu/dp/regf/a3
add wave -noupdate -group RegFile /testbench/dut/hart/ieu/dp/regf/rd1
add wave -noupdate -group RegFile /testbench/dut/hart/ieu/dp/regf/rd2
add wave -noupdate -group RegFile /testbench/dut/hart/ieu/dp/regf/we3
add wave -noupdate -group RegFile /testbench/dut/hart/ieu/dp/regf/wd3
add wave -noupdate -group RegFile -group {write regfile mux} /testbench/dut/hart/ieu/dp/ReadDataW
add wave -noupdate -group RegFile -group {write regfile mux} /testbench/dut/hart/ieu/dp/CSRReadValW
add wave -noupdate -group RegFile -group {write regfile mux} /testbench/dut/hart/ieu/dp/ResultSrcW
add wave -noupdate -group RegFile -group {write regfile mux} /testbench/dut/hart/ieu/dp/ResultW
add wave -noupdate -group alu /testbench/dut/hart/ieu/dp/alu/A
add wave -noupdate -group alu /testbench/dut/hart/ieu/dp/alu/B
add wave -noupdate -group alu /testbench/dut/hart/ieu/dp/alu/ALUControl
add wave -noupdate -group alu -divider internals
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
add wave -noupdate -group icache -color Gold /testbench/dut/hart/ifu/icache/controller/CurrState
add wave -noupdate -group icache /testbench/dut/hart/ifu/icache/controller/NextState
add wave -noupdate -group icache /testbench/dut/hart/ifu/ITLBMissF
add wave -noupdate -group icache /testbench/dut/hart/ifu/icache/ITLBWriteF
add wave -noupdate -group icache /testbench/dut/hart/ifu/icache/ReadLineF
add wave -noupdate -group icache /testbench/dut/hart/ifu/icache/SelAdr
add wave -noupdate -group icache /testbench/dut/hart/ifu/icache/PCNextF
add wave -noupdate -group icache /testbench/dut/hart/ifu/icache/PCPF
add wave -noupdate -group icache /testbench/dut/hart/ifu/icache/PCPSpillF
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/hit
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/spill
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/ICacheStallF
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/spillSave
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/spillSave
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/CntReset
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/PreCntEn
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/CntEn
add wave -noupdate -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/FinalInstrRawF
add wave -noupdate -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/InstrReadF
add wave -noupdate -group icache -expand -group memory /testbench/dut/hart/ifu/icache/InstrPAdrF
add wave -noupdate -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/FetchCountFlag
add wave -noupdate -group icache -expand -group memory /testbench/dut/hart/ifu/icache/FetchCount
add wave -noupdate -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/InstrAckF
add wave -noupdate -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/ICacheMemWriteEnable
add wave -noupdate -group icache -expand -group memory /testbench/dut/hart/ifu/icache/ICacheMemWriteData
add wave -noupdate -group icache /testbench/dut/hart/ifu/icache/ICacheMemReadData
add wave -noupdate -group icache /testbench/dut/hart/ifu/icache/SpillDataBlock0
add wave -noupdate -group AHB -color Gold /testbench/dut/hart/ebu/BusState
add wave -noupdate -group AHB /testbench/dut/hart/ebu/NextBusState
add wave -noupdate -group AHB -expand -group {input requests} /testbench/dut/hart/ebu/AtomicMaskedM
add wave -noupdate -group AHB -expand -group {input requests} /testbench/dut/hart/ebu/InstrReadF
add wave -noupdate -group AHB -expand -group {input requests} /testbench/dut/hart/ebu/LsuBusSize
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
add wave -noupdate -expand -group lsu -color Gold /testbench/dut/hart/lsu/MEM_VIRTMEM/interlockfsm/InterlockCurrState
add wave -noupdate -expand -group lsu /testbench/dut/hart/lsu/SelHPTW
add wave -noupdate -expand -group lsu /testbench/dut/hart/lsu/InterlockStall
add wave -noupdate -expand -group lsu /testbench/dut/hart/lsu/LSUStall
add wave -noupdate -expand -group lsu /testbench/dut/hart/lsu/ReadDataWordMuxM
add wave -noupdate -expand -group lsu /testbench/dut/hart/lsu/ReadDataM
add wave -noupdate -expand -group lsu /testbench/dut/hart/lsu/WriteDataM
add wave -noupdate -expand -group lsu /testbench/dut/hart/lsu/SelUncachedAdr
add wave -noupdate -expand -group lsu -expand -group bus -color Gold /testbench/dut/hart/lsu/busfsm/BusCurrState
add wave -noupdate -expand -group lsu -expand -group bus /testbench/dut/hart/lsu/BusStall
add wave -noupdate -expand -group lsu -expand -group bus /testbench/dut/hart/lsu/LsuBusRead
add wave -noupdate -expand -group lsu -expand -group bus /testbench/dut/hart/lsu/LsuBusWrite
add wave -noupdate -expand -group lsu -expand -group bus /testbench/dut/hart/lsu/LsuBusAdr
add wave -noupdate -expand -group lsu -expand -group bus /testbench/dut/hart/lsu/LsuBusAck
add wave -noupdate -expand -group lsu -expand -group bus /testbench/dut/hart/lsu/LsuBusHWDATA
add wave -noupdate -expand -group lsu -expand -group dcache -color Gold /testbench/dut/hart/lsu/dcache/dcachefsm/CurrState
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/hart/lsu/dcache/WayHit
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/hart/lsu/dcache/SRAMBlockWriteEnableM
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/hart/lsu/dcache/SRAMWordWriteEnableM
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/hart/lsu/dcache/SRAMWayWriteEnable
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/hart/lsu/dcache/SRAMWordEnable
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/hart/lsu/dcache/SRAMBlockWayWriteEnableM
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/hart/lsu/dcache/SelAdrM
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/hart/lsu/dcache/ReadDataBlockM
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/hart/lsu/MEM_VIRTMEM/SelReplayCPURequest
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/hart/lsu/IEUAdrE
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/hart/lsu/IEUAdrM
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/hart/lsu/dcache/RAdr
add wave -noupdate -expand -group lsu -expand -group dcache -group flush -radix unsigned /testbench/dut/hart/lsu/dcache/FlushAdr
add wave -noupdate -expand -group lsu -expand -group dcache -group flush /testbench/dut/hart/lsu/dcache/FlushWay
add wave -noupdate -expand -group lsu -expand -group dcache -group flush /testbench/dut/hart/lsu/dcache/VictimDirtyWay
add wave -noupdate -expand -group lsu -expand -group dcache -group flush /testbench/dut/hart/lsu/dcache/VictimTag
add wave -noupdate -expand -group lsu -expand -group dcache -group flush /testbench/dut/hart/lsu/dcache/CacheableM
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/hart/lsu/dcache/DCacheMemWriteData
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 {/testbench/dut/hart/lsu/dcache/MemWay[0]/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 {/testbench/dut/hart/lsu/dcache/MemWay[0]/SetValid}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 {/testbench/dut/hart/lsu/dcache/MemWay[0]/SetDirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 -label TAG {/testbench/dut/hart/lsu/dcache/MemWay[0]/CacheTagMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 {/testbench/dut/hart/lsu/dcache/MemWay[0]/DirtyBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 {/testbench/dut/hart/lsu/dcache/MemWay[0]/ValidBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 -expand -group Way0Word0 {/testbench/dut/hart/lsu/dcache/MemWay[0]/word[0]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 -expand -group Way0Word0 {/testbench/dut/hart/lsu/dcache/MemWay[0]/word[0]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 -expand -group Way0Word1 {/testbench/dut/hart/lsu/dcache/MemWay[0]/word[1]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 -expand -group Way0Word1 {/testbench/dut/hart/lsu/dcache/MemWay[0]/word[1]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 -expand -group Way0Word2 {/testbench/dut/hart/lsu/dcache/MemWay[0]/word[2]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 -expand -group Way0Word2 {/testbench/dut/hart/lsu/dcache/MemWay[0]/word[2]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 -expand -group Way0Word3 {/testbench/dut/hart/lsu/dcache/MemWay[0]/word[3]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way0 -expand -group Way0Word3 {/testbench/dut/hart/lsu/dcache/MemWay[0]/word[3]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/hart/lsu/dcache/MemWay[1]/DirtyBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/hart/lsu/dcache/MemWay[1]/ValidBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/hart/lsu/dcache/MemWay[1]/SetDirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/hart/lsu/dcache/MemWay[1]/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 {/testbench/dut/hart/lsu/dcache/MemWay[1]/WriteWordEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -label TAG {/testbench/dut/hart/lsu/dcache/MemWay[1]/CacheTagMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word0 {/testbench/dut/hart/lsu/dcache/MemWay[1]/word[0]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word0 {/testbench/dut/hart/lsu/dcache/MemWay[1]/word[0]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word1 {/testbench/dut/hart/lsu/dcache/MemWay[1]/word[1]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word1 {/testbench/dut/hart/lsu/dcache/MemWay[1]/word[1]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word2 {/testbench/dut/hart/lsu/dcache/MemWay[1]/word[2]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word2 {/testbench/dut/hart/lsu/dcache/MemWay[1]/word[2]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word3 {/testbench/dut/hart/lsu/dcache/MemWay[1]/word[3]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way1 -expand -group Way1Word3 {/testbench/dut/hart/lsu/dcache/MemWay[1]/word[3]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/hart/lsu/dcache/MemWay[2]/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/hart/lsu/dcache/MemWay[2]/SetValid}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/hart/lsu/dcache/MemWay[2]/SetDirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -label TAG {/testbench/dut/hart/lsu/dcache/MemWay[2]/CacheTagMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/hart/lsu/dcache/MemWay[2]/DirtyBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 {/testbench/dut/hart/lsu/dcache/MemWay[2]/ValidBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word0 {/testbench/dut/hart/lsu/dcache/MemWay[2]/word[0]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word0 {/testbench/dut/hart/lsu/dcache/MemWay[2]/word[0]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word1 {/testbench/dut/hart/lsu/dcache/MemWay[2]/word[1]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word1 {/testbench/dut/hart/lsu/dcache/MemWay[2]/word[1]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word2 {/testbench/dut/hart/lsu/dcache/MemWay[2]/word[2]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word2 {/testbench/dut/hart/lsu/dcache/MemWay[2]/word[2]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word3 {/testbench/dut/hart/lsu/dcache/MemWay[2]/word[3]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group way2 -expand -group Way2Word3 {/testbench/dut/hart/lsu/dcache/MemWay[2]/word[3]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/hart/lsu/dcache/MemWay[3]/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/hart/lsu/dcache/MemWay[3]/SetValid}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/hart/lsu/dcache/MemWay[3]/SetDirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/hart/lsu/dcache/MemWay[3]/ClearDirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/hart/lsu/dcache/MemWay[3]/VDWriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -label TAG {/testbench/dut/hart/lsu/dcache/MemWay[3]/CacheTagMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/hart/lsu/dcache/MemWay[3]/DirtyBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 {/testbench/dut/hart/lsu/dcache/MemWay[3]/ValidBits}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word0 {/testbench/dut/hart/lsu/dcache/MemWay[3]/word[0]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word0 {/testbench/dut/hart/lsu/dcache/MemWay[3]/word[0]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word1 {/testbench/dut/hart/lsu/dcache/MemWay[3]/word[1]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word1 {/testbench/dut/hart/lsu/dcache/MemWay[3]/word[1]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word2 {/testbench/dut/hart/lsu/dcache/MemWay[3]/word[2]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word2 {/testbench/dut/hart/lsu/dcache/MemWay[3]/word[2]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word3 {/testbench/dut/hart/lsu/dcache/MemWay[3]/word[3]/CacheDataMem/WriteEnable}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -expand -group way3 -expand -group Way3Word3 {/testbench/dut/hart/lsu/dcache/MemWay[3]/word[3]/CacheDataMem/StoredData}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group valid/dirty /testbench/dut/hart/lsu/dcache/SetValid
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group valid/dirty /testbench/dut/hart/lsu/dcache/ClearValid
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group valid/dirty /testbench/dut/hart/lsu/dcache/SetDirty
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM writes} -group valid/dirty /testbench/dut/hart/lsu/dcache/ClearDirty
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} /testbench/dut/hart/lsu/dcache/RAdr
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way0 {/testbench/dut/hart/lsu/dcache/MemWay[0]/WayHit}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way0 {/testbench/dut/hart/lsu/dcache/MemWay[0]/Valid}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way0 {/testbench/dut/hart/lsu/dcache/MemWay[0]/Dirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way0 {/testbench/dut/hart/lsu/dcache/MemWay[0]/ReadTag}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way1 {/testbench/dut/hart/lsu/dcache/MemWay[1]/WayHit}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way1 {/testbench/dut/hart/lsu/dcache/MemWay[1]/Valid}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way1 {/testbench/dut/hart/lsu/dcache/MemWay[1]/Dirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way1 {/testbench/dut/hart/lsu/dcache/MemWay[1]/ReadTag}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way2 {/testbench/dut/hart/lsu/dcache/MemWay[2]/WayHit}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way2 {/testbench/dut/hart/lsu/dcache/MemWay[2]/Valid}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way2 {/testbench/dut/hart/lsu/dcache/MemWay[2]/Dirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way2 {/testbench/dut/hart/lsu/dcache/MemWay[2]/ReadTag}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way3 {/testbench/dut/hart/lsu/dcache/MemWay[3]/WayHit}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way3 {/testbench/dut/hart/lsu/dcache/MemWay[3]/Valid}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way3 {/testbench/dut/hart/lsu/dcache/MemWay[3]/Dirty}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} -expand -group way3 {/testbench/dut/hart/lsu/dcache/MemWay[3]/ReadTag}
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} /testbench/dut/hart/lsu/dcache/WayHit
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} /testbench/dut/hart/lsu/dcache/ReadDataBlockWayMaskedM
add wave -noupdate -expand -group lsu -expand -group dcache -group {Cache SRAM read} /testbench/dut/hart/lsu/dcache/ReadDataWordM
add wave -noupdate -expand -group lsu -expand -group dcache -group Victim /testbench/dut/hart/lsu/dcache/VictimTag
add wave -noupdate -expand -group lsu -expand -group dcache -group Victim /testbench/dut/hart/lsu/dcache/VictimWay
add wave -noupdate -expand -group lsu -expand -group dcache -group Victim /testbench/dut/hart/lsu/dcache/VictimDirtyWay
add wave -noupdate -expand -group lsu -expand -group dcache -group Victim /testbench/dut/hart/lsu/dcache/VictimDirty
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/hart/lsu/dcache/MemRWM
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/hart/lsu/dcache/MemAdrE
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/hart/lsu/dcache/LsuPAdrM
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/hart/lsu/dcache/Funct3M
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/hart/lsu/dcache/Funct7M
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/hart/lsu/dcache/AtomicM
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/hart/lsu/dcache/CacheableM
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/hart/lsu/dcache/FlushDCacheM
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/hart/lsu/dcache/DCacheStall
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/hart/lsu/ReadDataWordM
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {CPU side} /testbench/dut/hart/lsu/FinalWriteDataM
add wave -noupdate -expand -group lsu -expand -group dcache -group status /testbench/dut/hart/lsu/dcache/WayHit
add wave -noupdate -expand -group lsu -expand -group dcache -group status -color {Medium Orchid} /testbench/dut/hart/lsu/dcache/CacheHit
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {Memory Side} /testbench/dut/hart/lsu/dcache/DCacheFetchLine
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {Memory Side} /testbench/dut/hart/lsu/dcache/DCacheWriteLine
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {Memory Side} /testbench/dut/hart/lsu/dcache/DCacheMemWriteData
add wave -noupdate -expand -group lsu -expand -group dcache -expand -group {Memory Side} /testbench/dut/hart/lsu/dcache/DCacheBusAck
add wave -noupdate -expand -group lsu -expand -group dcache /testbench/dut/hart/lsu/dcache/FlushWay
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/hart/lsu/dmmu/dmmu/genblk1/tlb/VAdr
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/hart/lsu/dmmu/dmmu/genblk1/tlb/tlbcontrol/EffectivePrivilegeMode
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/hart/lsu/dmmu/dmmu/genblk1/tlb/PTE
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/hart/lsu/dmmu/dmmu/genblk1/tlb/HitPageType
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/hart/lsu/dmmu/dmmu/genblk1/tlb/tlbcontrol/Translate
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/hart/lsu/dmmu/dmmu/genblk1/tlb/tlbcontrol/DisableTranslation
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/hart/lsu/dmmu/dmmu/TLBMiss
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/hart/lsu/dmmu/dmmu/TLBHit
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/hart/lsu/dmmu/dmmu/PhysicalAddress
add wave -noupdate -expand -group lsu -group dtlb -expand -group faults /testbench/dut/hart/lsu/dmmu/dmmu/TLBPageFault
add wave -noupdate -expand -group lsu -group dtlb -expand -group faults /testbench/dut/hart/lsu/dmmu/dmmu/LoadAccessFaultM
add wave -noupdate -expand -group lsu -group dtlb -expand -group faults /testbench/dut/hart/lsu/dmmu/dmmu/StoreAccessFaultM
add wave -noupdate -expand -group lsu -group dtlb /testbench/dut/hart/lsu/dmmu/dmmu/genblk1/tlb/TLBPAdr
add wave -noupdate -expand -group lsu -group dtlb -expand -group write /testbench/dut/hart/lsu/dmmu/dmmu/genblk1/tlb/PTE
add wave -noupdate -expand -group lsu -group dtlb -expand -group write /testbench/dut/hart/lsu/dmmu/dmmu/genblk1/tlb/PageTypeWriteVal
add wave -noupdate -expand -group lsu -group dtlb -expand -group write /testbench/dut/hart/lsu/dmmu/dmmu/genblk1/tlb/TLBWrite
add wave -noupdate -expand -group lsu -group pma /testbench/dut/hart/lsu/dmmu/dmmu/pmachecker/PhysicalAddress
add wave -noupdate -expand -group lsu -group pma /testbench/dut/hart/lsu/dmmu/dmmu/pmachecker/SelRegions
add wave -noupdate -expand -group lsu -group pma /testbench/dut/hart/lsu/dmmu/dmmu/Cacheable
add wave -noupdate -expand -group lsu -group pma /testbench/dut/hart/lsu/dmmu/dmmu/Idempotent
add wave -noupdate -expand -group lsu -group pma /testbench/dut/hart/lsu/dmmu/dmmu/AtomicAllowed
add wave -noupdate -expand -group lsu -group pma /testbench/dut/hart/lsu/dmmu/dmmu/pmachecker/PMAAccessFault
add wave -noupdate -expand -group lsu -group pma /testbench/dut/hart/lsu/dmmu/dmmu/PMAInstrAccessFaultF
add wave -noupdate -expand -group lsu -group pma /testbench/dut/hart/lsu/dmmu/dmmu/PMALoadAccessFaultM
add wave -noupdate -expand -group lsu -group pma /testbench/dut/hart/lsu/dmmu/dmmu/PMAStoreAccessFaultM
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/hart/lsu/dmmu/dmmu/pmpchecker/pmpchecker/PhysicalAddress
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/hart/lsu/dmmu/dmmu/pmpchecker/pmpchecker/ReadAccessM
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/hart/lsu/dmmu/dmmu/pmpchecker/pmpchecker/WriteAccessM
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/hart/lsu/dmmu/dmmu/pmpchecker/pmpchecker/PMPADDR_ARRAY_REGW
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/hart/lsu/dmmu/dmmu/pmpchecker/pmpchecker/PMPCFG_ARRAY_REGW
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/hart/lsu/dmmu/dmmu/PMPInstrAccessFaultF
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/hart/lsu/dmmu/dmmu/PMPLoadAccessFaultM
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/hart/lsu/dmmu/dmmu/PMPStoreAccessFaultM
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/hart/lsu/dmmu/dmmu/pmpchecker/pmpchecker/Match
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/hart/lsu/dmmu/dmmu/pmpchecker/pmpchecker/FirstMatch
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/hart/lsu/dmmu/dmmu/pmpchecker/pmpchecker/R
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/hart/lsu/dmmu/dmmu/pmpchecker/pmpchecker/W
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/hart/lsu/dmmu/dmmu/pmpchecker/pmpchecker/X
add wave -noupdate -expand -group lsu -group pmp /testbench/dut/hart/lsu/dmmu/dmmu/pmpchecker/pmpchecker/L
add wave -noupdate -expand -group lsu -group ptwalker -color Gold /testbench/dut/hart/lsu/MEM_VIRTMEM/hptw/genblk1/WalkerState
add wave -noupdate -expand -group lsu -group ptwalker /testbench/dut/hart/lsu/MEM_VIRTMEM/hptw/PCF
add wave -noupdate -expand -group lsu -group ptwalker /testbench/dut/hart/lsu/MEM_VIRTMEM/hptw/genblk1/TranslationVAdr
add wave -noupdate -expand -group lsu -group ptwalker /testbench/dut/hart/lsu/MEM_VIRTMEM/hptw/HPTWReadPTE
add wave -noupdate -expand -group lsu -group ptwalker /testbench/dut/hart/lsu/MEM_VIRTMEM/hptw/HPTWAdr
add wave -noupdate -expand -group lsu -group ptwalker /testbench/dut/hart/lsu/MEM_VIRTMEM/hptw/PTE
add wave -noupdate -expand -group lsu -group ptwalker -group types /testbench/dut/hart/lsu/MEM_VIRTMEM/hptw/ITLBMissF
add wave -noupdate -expand -group lsu -group ptwalker -group types /testbench/dut/hart/lsu/MEM_VIRTMEM/hptw/DTLBMissM
add wave -noupdate -expand -group lsu -group ptwalker -group types /testbench/dut/hart/lsu/MEM_VIRTMEM/hptw/ITLBWriteF
add wave -noupdate -expand -group lsu -group ptwalker -group types /testbench/dut/hart/lsu/MEM_VIRTMEM/hptw/DTLBWriteM
add wave -noupdate -group itlb /testbench/dut/hart/ifu/immu/TLBWrite
add wave -noupdate -group itlb /testbench/dut/hart/ifu/ITLBMissF
add wave -noupdate -group itlb /testbench/dut/hart/ifu/immu/PhysicalAddress
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
add wave -noupdate -group {debug trace} -expand -group mem -color Yellow /testbench/dut/hart/FlushW
add wave -noupdate -group {debug trace} -expand -group mem /testbench/dut/hart/PCM
add wave -noupdate -group {debug trace} -expand -group mem -color Brown /testbench/dut/hart/hzu/TrapM
add wave -noupdate -group {debug trace} -expand -group wb /testbench/PCW
add wave -noupdate -group {pc selection} /testbench/dut/hart/ifu/PCNext2F
add wave -noupdate -group {pc selection} /testbench/dut/hart/ifu/PrivilegedNextPCM
add wave -noupdate -group {pc selection} /testbench/dut/hart/ifu/PrivilegedChangePCM
add wave -noupdate /testbench/dut/hart/priv/priv/csr/MEPC_REGW
add wave -noupdate /testbench/dut/hart/lsu/LocalLsuBusAdr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 7} {36865 ns} 1} {{Cursor 5} {49445 ns} 1} {{Cursor 3} {35522 ns} 0} {{Cursor 4} {49574 ns} 1}
quietly wave cursor active 3
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
WaveRestoreZoom {35088 ns} {35954 ns}
