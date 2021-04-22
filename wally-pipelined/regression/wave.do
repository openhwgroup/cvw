onerror {resume}
quietly virtual function -install /testbench/dut/hart/ifu/icache/cachemem -env /testbench/dut/hart/ifu/icache/cachemem { &{/testbench/dut/hart/ifu/icache/cachemem/OldReadPAdr[4], /testbench/dut/hart/ifu/icache/cachemem/OldReadPAdr[3], /testbench/dut/hart/ifu/icache/cachemem/OldReadPAdr[2], /testbench/dut/hart/ifu/icache/cachemem/OldReadPAdr[1], /testbench/dut/hart/ifu/icache/cachemem/OldReadPAdr[0] }} offset
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/reset
add wave -noupdate /testbench/test
add wave -noupdate -radix ascii /testbench/memfilename
add wave -noupdate -expand -group {Execution Stage} /testbench/functionRadix/function_radix/FunctionName
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
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/hart/hzu/DataStall
add wave -noupdate -expand -group HDU -expand -group hazards /testbench/dut/hart/MulDivStallD
add wave -noupdate -expand -group HDU -expand -group Flush -color Yellow /testbench/dut/hart/hzu/FlushF
add wave -noupdate -expand -group HDU -expand -group Flush -color Yellow /testbench/dut/hart/FlushD
add wave -noupdate -expand -group HDU -expand -group Flush -color Yellow /testbench/dut/hart/FlushE
add wave -noupdate -expand -group HDU -expand -group Flush -color Yellow /testbench/dut/hart/FlushM
add wave -noupdate -expand -group HDU -expand -group Flush -color Yellow /testbench/dut/hart/FlushW
add wave -noupdate -expand -group HDU -expand -group Stall -color Orange /testbench/dut/hart/StallF
add wave -noupdate -expand -group HDU -expand -group Stall -color Orange /testbench/dut/hart/StallD
add wave -noupdate -expand -group HDU -expand -group Stall -color Orange /testbench/dut/hart/StallE
add wave -noupdate -expand -group HDU -expand -group Stall -color Orange /testbench/dut/hart/StallM
add wave -noupdate -expand -group HDU -expand -group Stall -color Orange /testbench/dut/hart/StallW
add wave -noupdate -group Bpred -expand -group direction -divider Update
add wave -noupdate -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/Predictor/DirPredictor/UpdatePC
add wave -noupdate -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/Predictor/DirPredictor/UpdateEN
add wave -noupdate -group Bpred -expand -group direction /testbench/dut/hart/ifu/bpred/Predictor/DirPredictor/UpdatePrediction
add wave -noupdate -group Bpred -group {bp wrong} /testbench/dut/hart/ifu/bpred/TargetWrongE
add wave -noupdate -group Bpred -group {bp wrong} /testbench/dut/hart/ifu/bpred/FallThroughWrongE
add wave -noupdate -group Bpred -group {bp wrong} /testbench/dut/hart/ifu/bpred/PredictionDirWrongE
add wave -noupdate -group Bpred -group {bp wrong} /testbench/dut/hart/ifu/bpred/PredictionPCWrongE
add wave -noupdate -group Bpred -group {bp wrong} /testbench/dut/hart/ifu/bpred/BPPredWrongE
add wave -noupdate -group Bpred -group {bp wrong} /testbench/dut/hart/ifu/bpred/InstrClassE
add wave -noupdate -group Bpred -group BTB -divider Update
add wave -noupdate -group Bpred -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/UpdateEN
add wave -noupdate -group Bpred -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/UpdatePC
add wave -noupdate -group Bpred -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/UpdateTarget
add wave -noupdate -group Bpred -group BTB -divider Lookup
add wave -noupdate -group Bpred -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/TargetPC
add wave -noupdate -group Bpred -group BTB /testbench/dut/hart/ifu/bpred/TargetPredictor/Valid
add wave -noupdate -group Bpred /testbench/dut/hart/ifu/bpred/BPPredWrongE
add wave -noupdate -expand -group {instruction pipeline} /testbench/dut/hart/ifu/InstrD
add wave -noupdate -expand -group {instruction pipeline} /testbench/dut/hart/ifu/InstrE
add wave -noupdate -expand -group {instruction pipeline} /testbench/dut/hart/ifu/InstrM
add wave -noupdate -expand -group {PCNext Generation} /testbench/dut/hart/ifu/PCNextF
add wave -noupdate -expand -group {PCNext Generation} /testbench/dut/hart/ifu/PCF
add wave -noupdate -expand -group {PCNext Generation} /testbench/dut/hart/ifu/PCPlus2or4F
add wave -noupdate -expand -group {PCNext Generation} /testbench/dut/hart/ifu/BPPredPCF
add wave -noupdate -expand -group {PCNext Generation} /testbench/dut/hart/ifu/PCNext0F
add wave -noupdate -expand -group {PCNext Generation} /testbench/dut/hart/ifu/PCNext1F
add wave -noupdate -expand -group {PCNext Generation} /testbench/dut/hart/ifu/SelBPPredF
add wave -noupdate -expand -group {PCNext Generation} /testbench/dut/hart/ifu/BPPredWrongE
add wave -noupdate -expand -group {PCNext Generation} /testbench/dut/hart/ifu/PrivilegedChangePCM
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
add wave -noupdate -group alu /testbench/dut/hart/ieu/dp/alu/a
add wave -noupdate -group alu /testbench/dut/hart/ieu/dp/alu/b
add wave -noupdate -group alu /testbench/dut/hart/ieu/dp/alu/alucontrol
add wave -noupdate -group alu /testbench/dut/hart/ieu/dp/alu/result
add wave -noupdate -group alu /testbench/dut/hart/ieu/dp/alu/flags
add wave -noupdate -group alu -divider internals
add wave -noupdate -group alu /testbench/dut/hart/ieu/dp/alu/overflow
add wave -noupdate -group alu /testbench/dut/hart/ieu/dp/alu/carry
add wave -noupdate -group alu /testbench/dut/hart/ieu/dp/alu/zero
add wave -noupdate -group alu /testbench/dut/hart/ieu/dp/alu/neg
add wave -noupdate -group alu /testbench/dut/hart/ieu/dp/alu/lt
add wave -noupdate -group alu /testbench/dut/hart/ieu/dp/alu/ltu
add wave -noupdate /testbench/InstrFName
add wave -noupdate -expand -group {dcache memory} /testbench/dut/hart/dmem/MemReadM
add wave -noupdate -expand -group {dcache memory} /testbench/dut/hart/dmem/MemWriteM
add wave -noupdate -expand -group {dcache memory} /testbench/dut/hart/dmem/MemAckW
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
add wave -noupdate -expand -group PCS /testbench/dut/hart/ifu/PCNextF
add wave -noupdate -expand -group PCS /testbench/dut/hart/PCF
add wave -noupdate -expand -group PCS /testbench/dut/hart/ifu/PCD
add wave -noupdate -expand -group PCS /testbench/dut/hart/PCE
add wave -noupdate -expand -group PCS /testbench/dut/hart/PCM
add wave -noupdate -expand -group PCS /testbench/PCW
add wave -noupdate -group {function radix debug} /testbench/functionRadix/function_radix/FunctionAddr
add wave -noupdate -group {function radix debug} -radix unsigned /testbench/functionRadix/function_radix/ProgramAddrIndex
add wave -noupdate -group {function radix debug} /testbench/functionRadix/function_radix/reset
add wave -noupdate -group {function radix debug} /testbench/functionRadix/function_radix/ProgramLabelMapLineCount
add wave -noupdate -group {function radix debug} /testbench/functionRadix/function_radix/ProgramLabelMapLine
add wave -noupdate -group {function radix debug} /testbench/functionRadix/function_radix/ProgramLabelMapFP
add wave -noupdate -group {function radix debug} /testbench/functionRadix/function_radix/ProgramLabelMapFile
add wave -noupdate -group {function radix debug} /testbench/functionRadix/function_radix/ProgramAddrMapLineCount
add wave -noupdate -group {function radix debug} /testbench/functionRadix/function_radix/ProgramAddrMapLine
add wave -noupdate -group {function radix debug} /testbench/functionRadix/function_radix/ProgramAddrMapFP
add wave -noupdate -group {function radix debug} /testbench/functionRadix/function_radix/ProgramAddrMapFile
add wave -noupdate -group {function radix debug} /testbench/functionRadix/function_radix/pc
add wave -noupdate -group {function radix debug} /testbench/functionRadix/function_radix/FunctionAddr
add wave -noupdate -group {function radix debug} /testbench/functionRadix/function_radix/ProgramAddrIndex
add wave -noupdate -group {function radix debug} /testbench/functionRadix/function_radix/FunctionName
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
add wave -noupdate -expand -group icache -color Orange /testbench/dut/hart/ifu/icache/controller/CurrState
add wave -noupdate -expand -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/hit
add wave -noupdate -expand -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/spill
add wave -noupdate -expand -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/cachemem/OldReadPAdr
add wave -noupdate -expand -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/ICacheStallF
add wave -noupdate -expand -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/SavePC
add wave -noupdate -expand -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/spillSave
add wave -noupdate -expand -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/UnalignedSelect
add wave -noupdate -expand -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/PCMux
add wave -noupdate -expand -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/spillSave
add wave -noupdate -expand -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/CntReset
add wave -noupdate -expand -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/PreCntEn
add wave -noupdate -expand -group icache -expand -group {fsm out and control} /testbench/dut/hart/ifu/icache/controller/CntEn
add wave -noupdate -expand -group icache -group parameters /testbench/dut/hart/ifu/icache/controller/AHBByteLength
add wave -noupdate -expand -group icache -group parameters /testbench/dut/hart/ifu/icache/controller/AHBOFFETWIDTH
add wave -noupdate -expand -group icache -group parameters /testbench/dut/hart/ifu/icache/controller/BlockByteLength
add wave -noupdate -expand -group icache -group parameters /testbench/dut/hart/ifu/icache/controller/OFFSETWIDTH
add wave -noupdate -expand -group icache -group parameters /testbench/dut/hart/ifu/icache/controller/WORDSPERLINE
add wave -noupdate -expand -group icache -group parameters /testbench/dut/hart/ifu/icache/controller/LOGWPL
add wave -noupdate -expand -group icache -group parameters /testbench/dut/hart/ifu/icache/controller/LINESIZE
add wave -noupdate -expand -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/FetchCountFlag
add wave -noupdate -expand -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/FetchCount
add wave -noupdate -expand -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/InstrPAdrF
add wave -noupdate -expand -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/InstrReadF
add wave -noupdate -expand -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/InstrAckF
add wave -noupdate -expand -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/InstrInF
add wave -noupdate -expand -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/ICacheMemWriteEnable
add wave -noupdate -expand -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/ICacheMemWriteData
add wave -noupdate -expand -group icache -expand -group memory /testbench/dut/hart/ifu/icache/controller/ICacheMemWritePAdr
add wave -noupdate -expand -group icache -expand -group memory -group {tag read} /testbench/dut/hart/ifu/icache/cachemem/DataValidBit
add wave -noupdate -expand -group icache -expand -group memory -group {tag read} /testbench/dut/hart/ifu/icache/cachemem/DataValid
add wave -noupdate -expand -group icache -expand -group memory -group {tag read} /testbench/dut/hart/ifu/icache/cachemem/ReadTag
add wave -noupdate -expand -group icache -expand -group memory -group {tag read} /testbench/dut/hart/ifu/icache/cachemem/DataTag
add wave -noupdate -expand -group icache -expand -group memory -group {tag read} /testbench/dut/hart/ifu/icache/cachemem/cachetags/ReadAddr
add wave -noupdate -expand -group icache -expand -group memory -group {tag read} /testbench/dut/hart/ifu/icache/cachemem/cachetags/ReadData
add wave -noupdate -expand -group icache -expand -group memory -group {tag read} /testbench/dut/hart/ifu/icache/cachemem/ReadPAdr
add wave -noupdate -expand -group icache -expand -group memory -group {tag write} /testbench/dut/hart/ifu/icache/cachemem/WriteEnable
add wave -noupdate -expand -group icache -expand -group memory -group {tag write} /testbench/dut/hart/ifu/icache/cachemem/WriteLine
add wave -noupdate -expand -group icache -expand -group memory -group {tag write} /testbench/dut/hart/ifu/icache/cachemem/WritePAdr
add wave -noupdate -expand -group icache -expand -group memory -group {tag write} /testbench/dut/hart/ifu/icache/cachemem/WriteSet
add wave -noupdate -expand -group icache -expand -group memory -group {tag write} /testbench/dut/hart/ifu/icache/cachemem/WriteTag
add wave -noupdate -expand -group icache -expand -group memory -group {tag write} /testbench/dut/hart/ifu/icache/cachemem/cachetags/StoredData
add wave -noupdate -expand -group icache -expand -group {instr to cpu} /testbench/dut/hart/ifu/icache/controller/FinalInstrRawF
add wave -noupdate -expand -group icache -expand -group {instr to cpu} /testbench/dut/hart/ifu/icache/controller/AlignedInstrRawD
add wave -noupdate -expand -group icache -expand -group {instr to cpu} /testbench/dut/hart/ifu/icache/controller/InstrRawD
add wave -noupdate -expand -group pc /testbench/dut/hart/ifu/icache/controller/PCNextPF
add wave -noupdate -expand -group pc /testbench/dut/hart/ifu/icache/controller/PCPF
add wave -noupdate -expand -group pc /testbench/dut/hart/ifu/icache/controller/PCPreFinalF
add wave -noupdate -expand -group pc /testbench/dut/hart/ifu/icache/controller/PCPFinalF
add wave -noupdate /testbench/dut/hart/ifu/icache/controller/ICacheMemReadData
add wave -noupdate /testbench/dut/hart/ifu/icache/controller/PCPreFinalF
add wave -noupdate /testbench/dut/hart/ifu/icache/cachemem/ReadLine
add wave -noupdate -radix hexadecimal -childformat {{{/testbench/dut/hart/ifu/icache/cachemem/ReadOffset[1]} -radix hexadecimal} {{/testbench/dut/hart/ifu/icache/cachemem/ReadOffset[0]} -radix hexadecimal}} -subitemconfig {{/testbench/dut/hart/ifu/icache/cachemem/ReadOffset[1]} {-height 16 -radix hexadecimal} {/testbench/dut/hart/ifu/icache/cachemem/ReadOffset[0]} {-height 16 -radix hexadecimal}} /testbench/dut/hart/ifu/icache/cachemem/ReadOffset
add wave -noupdate -label {read offset} -radix unsigned -childformat {{(4) -radix unsigned} {(3) -radix unsigned} {(2) -radix unsigned} {(1) -radix unsigned} {(0) -radix unsigned}} -subitemconfig {{/testbench/dut/hart/ifu/icache/cachemem/OldReadPAdr[4]} {-radix unsigned} {/testbench/dut/hart/ifu/icache/cachemem/OldReadPAdr[3]} {-radix unsigned} {/testbench/dut/hart/ifu/icache/cachemem/OldReadPAdr[2]} {-radix unsigned} {/testbench/dut/hart/ifu/icache/cachemem/OldReadPAdr[1]} {-radix unsigned} {/testbench/dut/hart/ifu/icache/cachemem/OldReadPAdr[0]} {-radix unsigned}} /testbench/dut/hart/ifu/icache/cachemem/offset
add wave -noupdate /testbench/dut/hart/ifu/icache/cachemem/OldReadPAdr
add wave -noupdate /testbench/dut/hart/ifu/CompressedF
add wave -noupdate /testbench/dut/hart/ifu/icache/controller/SpillDataBlock0
add wave -noupdate /testbench/dut/hart/ifu/icache/controller/PCPreFinalF_q
add wave -noupdate -expand -group AHB /testbench/dut/hart/ebu/BusState
add wave -noupdate -expand -group AHB /testbench/dut/hart/ebu/HCLK
add wave -noupdate -expand -group AHB /testbench/dut/hart/ebu/HRDATA
add wave -noupdate -expand -group AHB /testbench/dut/hart/ebu/HREADY
add wave -noupdate -expand -group AHB /testbench/dut/hart/ebu/HRESP
add wave -noupdate -expand -group AHB /testbench/dut/hart/ebu/HADDR
add wave -noupdate -expand -group AHB /testbench/dut/hart/ebu/HWDATA
add wave -noupdate -expand -group AHB /testbench/dut/hart/ebu/HWRITE
add wave -noupdate -expand -group AHB /testbench/dut/hart/ebu/HSIZE
add wave -noupdate -expand -group AHB /testbench/dut/hart/ebu/HBURST
add wave -noupdate -expand -group AHB /testbench/dut/hart/ebu/HPROT
add wave -noupdate -expand -group AHB /testbench/dut/hart/ebu/HTRANS
add wave -noupdate -expand -group AHB /testbench/dut/hart/ebu/HMASTLOCK
add wave -noupdate -expand -group AHB /testbench/dut/hart/ebu/HADDRD
add wave -noupdate -expand -group AHB /testbench/dut/hart/ebu/HSIZED
add wave -noupdate -expand -group AHB /testbench/dut/hart/ebu/HWRITED
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {9808206 ns} 0} {{Cursor 3} {9807791 ns} 0} {{Cursor 4} {85 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 250
configure wave -valuecolwidth 513
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
WaveRestoreZoom {9807926 ns} {9808486 ns}
