onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider <NULL>
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/reset
add wave -noupdate -radix decimal /testbench/instrs
add wave -noupdate -divider Stalls_and_Flushes
add wave -noupdate /testbench/dut/hart/StallF
add wave -noupdate /testbench/dut/hart/StallD
add wave -noupdate /testbench/dut/hart/StallE
add wave -noupdate /testbench/dut/hart/StallM
add wave -noupdate /testbench/dut/hart/StallW
add wave -noupdate /testbench/dut/hart/FlushD
add wave -noupdate /testbench/dut/hart/FlushE
add wave -noupdate /testbench/dut/hart/FlushM
add wave -noupdate /testbench/dut/hart/FlushW
add wave -noupdate -divider InstrTranslator
add wave -noupdate -group InstrTranslator /testbench/SvMode
add wave -noupdate -group InstrTranslator /testbench/PTE_R
add wave -noupdate -group InstrTranslator /testbench/PTE_X
add wave -noupdate -group InstrTranslator /testbench/SATP
add wave -noupdate -group InstrTranslator /testbench/PTE
add wave -noupdate -group InstrTranslator /testbench/BaseAdr
add wave -noupdate -group InstrTranslator /testbench/PAdr
add wave -noupdate -group InstrTranslator /testbench/VPN
add wave -noupdate -group InstrTranslator /testbench/Offset
add wave -noupdate -group InstrTranslator /testbench/readAdrExpected
add wave -noupdate -group InstrTranslator /testbench/readAdrTranslated
add wave -noupdate -group InstrTranslator /testbench/writeAdrExpected
add wave -noupdate -group InstrTranslator /testbench/writeAdrTranslated
add wave -noupdate -divider F
add wave -noupdate -radix hexadecimal /testbench/dut/hart/ifu/PCF
add wave -noupdate -divider D
add wave -noupdate -radix hexadecimal /testbench/PCDexpected
add wave -noupdate -radix hexadecimal /testbench/dut/hart/ifu/PCD
add wave -noupdate -radix hexadecimal /testbench/PCtextD
add wave -noupdate /testbench/InstrDName
add wave -noupdate -radix hexadecimal /testbench/dut/hart/ifu/InstrD
add wave -noupdate -radix hexadecimal /testbench/dut/hart/ieu/c/InstrValidD
add wave -noupdate -radix hexadecimal /testbench/PCDwrong
add wave -noupdate -divider E
add wave -noupdate -radix hexadecimal /testbench/dut/hart/ifu/PCE
add wave -noupdate -radix hexadecimal /testbench/PCtextE
add wave -noupdate /testbench/InstrEName
add wave -noupdate -radix hexadecimal /testbench/dut/hart/ifu/InstrE
add wave -noupdate -radix hexadecimal /testbench/dut/hart/ieu/c/InstrValidE
add wave -noupdate -radix hexadecimal /testbench/dut/hart/ieu/dp/SrcAE
add wave -noupdate -radix hexadecimal /testbench/dut/hart/ieu/dp/SrcBE
add wave -noupdate -radix hexadecimal /testbench/dut/hart/ieu/dp/ALUResultE
add wave -noupdate -divider M
add wave -noupdate -radix hexadecimal /testbench/dut/hart/ifu/PCM
add wave -noupdate -radix hexadecimal /testbench/PCtextM
add wave -noupdate /testbench/InstrMName
add wave -noupdate -radix hexadecimal /testbench/dut/hart/ifu/InstrM
add wave -noupdate -radix hexadecimal /testbench/dut/hart/ieu/c/InstrValidM
add wave -noupdate -radix hexadecimal /testbench/dut/hart/lsu/dcache/MemPAdrM
add wave -noupdate -radix hexadecimal /testbench/dut/hart/lsu/dcache/MemRWM
add wave -noupdate /testbench/dut/hart/lsu/dcache/WriteDataM
add wave -noupdate -radix hexadecimal /testbench/dut/hart/lsu/dcache/ReadDataM
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/DTLBWalk
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/BasePageTablePPN
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/CurrentPPN
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/MemWrite
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/Executable
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/Writable
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/Readable
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/Valid
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/Misaligned
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/MegapageMisaligned
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/ValidPTE
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/LeafPTE
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/ValidLeafPTE
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/ValidNonLeafPTE
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/StartWalk
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/TLBMiss
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/PRegEn
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/NextPageType
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/SvMode
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/TranslationVAdr
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/WalkerState
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/NextWalkerState
add wave -noupdate -group Walker /testbench/dut/hart/lsu/hptw/genblk1/InitialWalkerState
add wave -noupdate -group LSU /testbench/dut/hart/lsu/clk
add wave -noupdate -group LSU /testbench/dut/hart/lsu/reset
add wave -noupdate -group LSU /testbench/dut/hart/lsu/StallM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/FlushM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/StallW
add wave -noupdate -group LSU /testbench/dut/hart/lsu/FlushW
add wave -noupdate -group LSU /testbench/dut/hart/lsu/LSUStall
add wave -noupdate -group LSU /testbench/dut/hart/lsu/MemRWM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/Funct3M
add wave -noupdate -group LSU /testbench/dut/hart/lsu/Funct7M
add wave -noupdate -group LSU /testbench/dut/hart/lsu/AtomicM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/ExceptionM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/PendingInterruptM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/CommittedM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/SquashSCW
add wave -noupdate -group LSU /testbench/dut/hart/lsu/DataMisalignedM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/MemAdrM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/MemAdrE
add wave -noupdate -group LSU /testbench/dut/hart/lsu/WriteDataM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/ReadDataW
add wave -noupdate -group LSU /testbench/dut/hart/lsu/PrivilegeModeW
add wave -noupdate -group LSU /testbench/dut/hart/lsu/DTLBFlushM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/DTLBLoadPageFaultM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/DTLBStorePageFaultM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/LoadMisalignedFaultM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/LoadAccessFaultM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/StoreMisalignedFaultM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/StoreAccessFaultM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/CommitM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/DCtoAHBPAdrM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/DCtoAHBReadM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/DCtoAHBWriteM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/DCfromAHBAck
add wave -noupdate -group LSU /testbench/dut/hart/lsu/DCfromAHBReadData
add wave -noupdate -group LSU /testbench/dut/hart/lsu/DCtoAHBWriteData
add wave -noupdate -group LSU /testbench/dut/hart/lsu/DCtoAHBSizeM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/SATP_REGW
add wave -noupdate -group LSU /testbench/dut/hart/lsu/STATUS_MXR
add wave -noupdate -group LSU /testbench/dut/hart/lsu/STATUS_SUM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/STATUS_MPRV
add wave -noupdate -group LSU /testbench/dut/hart/lsu/STATUS_MPP
add wave -noupdate -group LSU /testbench/dut/hart/lsu/PCF
add wave -noupdate -group LSU /testbench/dut/hart/lsu/ITLBMissF
add wave -noupdate -group LSU /testbench/dut/hart/lsu/PageType
add wave -noupdate -group LSU /testbench/dut/hart/lsu/ITLBWriteF
add wave -noupdate -group LSU /testbench/dut/hart/lsu/WalkerInstrPageFaultF
add wave -noupdate -group LSU /testbench/dut/hart/lsu/WalkerLoadPageFaultM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/WalkerStorePageFaultM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/DTLBHitM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/SquashSCM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/DTLBPageFaultM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/MemAccessM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/CurrState
add wave -noupdate -group LSU /testbench/dut/hart/lsu/NextState
add wave -noupdate -group LSU /testbench/dut/hart/lsu/MemPAdrM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/DTLBMissM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/DTLBWriteM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/HPTWReadPTE
add wave -noupdate -group LSU /testbench/dut/hart/lsu/HPTWStall
add wave -noupdate -group LSU /testbench/dut/hart/lsu/HPTWPAdrE
add wave -noupdate -group LSU /testbench/dut/hart/lsu/HPTWRead
add wave -noupdate -group LSU /testbench/dut/hart/lsu/MemRWMtoDCache
add wave -noupdate -group LSU /testbench/dut/hart/lsu/Funct3MtoDCache
add wave -noupdate -group LSU /testbench/dut/hart/lsu/AtomicMtoDCache
add wave -noupdate -group LSU /testbench/dut/hart/lsu/MemAdrEtoDCache
add wave -noupdate -group LSU /testbench/dut/hart/lsu/ReadDataWfromDCache
add wave -noupdate -group LSU /testbench/dut/hart/lsu/StallWtoDCache
add wave -noupdate -group LSU /testbench/dut/hart/lsu/DataMisalignedMfromDCache
add wave -noupdate -group LSU /testbench/dut/hart/lsu/HPTWReady
add wave -noupdate -group LSU /testbench/dut/hart/lsu/DisableTranslation
add wave -noupdate -group LSU /testbench/dut/hart/lsu/DCacheStall
add wave -noupdate -group LSU /testbench/dut/hart/lsu/CacheableM
add wave -noupdate -group LSU /testbench/dut/hart/lsu/CacheableMtoDCache
add wave -noupdate -group LSU /testbench/dut/hart/lsu/SelPTW
add wave -noupdate -group LSU /testbench/dut/hart/lsu/CommittedMfromDCache
add wave -noupdate -group LSU /testbench/dut/hart/lsu/PendingInterruptMtoDCache
add wave -noupdate -group LSU /testbench/dut/hart/lsu/FlushWtoDCache
add wave -noupdate -group LSU /testbench/dut/hart/lsu/WalkerPageFaultM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/clk
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/reset
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/StallM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/StallW
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/FlushM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/FlushW
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/MemRWM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/Funct3M
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/Funct7M
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/AtomicM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/MemAdrE
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/MemPAdrM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/WriteDataM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/ReadDataW
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/ReadDataM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/DCacheStall
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/CommittedM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/ExceptionM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/PendingInterruptM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/DTLBMissM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/CacheableM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/DTLBWriteM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/ITLBWriteF
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/SelPTW
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/WalkerPageFaultM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/AHBPAdr
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/AHBRead
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/AHBWrite
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/AHBAck
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/HRDATA
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/HWDATA
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/SelAdrM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/SRAMAdr
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/SRAMWriteData
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/DCacheMemWriteData
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/SetValidM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/ClearValidM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/SetDirtyM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/ClearDirtyM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/Valid
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/Dirty
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/WayHit
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/CacheHit
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/NewReplacement
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/ReadDataBlockM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/ReadDataWordM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/ReadDataWordMuxM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/FinalWriteDataM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/FinalAMOWriteDataM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/FinalWriteDataWordsM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/FetchCount
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/NextFetchCount
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/SRAMWordEnable
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/SelMemWriteDataM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/Funct3W
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/SRAMWordWriteEnableM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/SRAMWordWriteEnableW
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/SRAMBlockWriteEnableM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/SRAMWriteEnable
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/SRAMWayWriteEnable
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/SaveSRAMRead
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/AtomicW
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/VictimWay
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/VictimDirtyWay
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/VictimReadDataBlockM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/VictimDirty
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/SelAMOWrite
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/SelUncached
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/Funct7W
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/MemPAdrDecodedW
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/BasePAdrM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/BasePAdrOffsetM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/BasePAdrMaskedM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/VictimTag
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/AnyCPUReqM
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/FetchCountFlag
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/PreCntEn
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/CntEn
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/CntReset
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/CPUBusy
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/PreviousCPUBusy
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/SelEvict
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/CurrState
add wave -noupdate -group DCache /testbench/dut/hart/lsu/dcache/NextState
add wave -noupdate -group EBU /testbench/dut/hart/ebu/clk
add wave -noupdate -group EBU /testbench/dut/hart/ebu/reset
add wave -noupdate -group EBU /testbench/dut/hart/ebu/StallW
add wave -noupdate -group EBU /testbench/dut/hart/ebu/UnsignedLoadM
add wave -noupdate -group EBU /testbench/dut/hart/ebu/AtomicMaskedM
add wave -noupdate -group EBU /testbench/dut/hart/ebu/Funct7M
add wave -noupdate -group EBU /testbench/dut/hart/ebu/InstrPAdrF
add wave -noupdate -group EBU /testbench/dut/hart/ebu/InstrReadF
add wave -noupdate -group EBU /testbench/dut/hart/ebu/InstrRData
add wave -noupdate -group EBU /testbench/dut/hart/ebu/InstrAckF
add wave -noupdate -group EBU /testbench/dut/hart/ebu/DCtoAHBPAdrM
add wave -noupdate -group EBU /testbench/dut/hart/ebu/DCtoAHBReadM
add wave -noupdate -group EBU /testbench/dut/hart/ebu/DCtoAHBWriteM
add wave -noupdate -group EBU /testbench/dut/hart/ebu/DCtoAHBWriteData
add wave -noupdate -group EBU /testbench/dut/hart/ebu/DCfromAHBReadData
add wave -noupdate -group EBU /testbench/dut/hart/ebu/MemSizeM
add wave -noupdate -group EBU /testbench/dut/hart/ebu/DCfromAHBAck
add wave -noupdate -group EBU /testbench/dut/hart/ebu/HRDATA
add wave -noupdate -group EBU /testbench/dut/hart/ebu/HREADY
add wave -noupdate -group EBU /testbench/dut/hart/ebu/HRESP
add wave -noupdate -group EBU /testbench/dut/hart/ebu/HCLK
add wave -noupdate -group EBU /testbench/dut/hart/ebu/HRESETn
add wave -noupdate -group EBU /testbench/dut/hart/ebu/HADDR
add wave -noupdate -group EBU /testbench/dut/hart/ebu/HWDATA
add wave -noupdate -group EBU /testbench/dut/hart/ebu/HWRITE
add wave -noupdate -group EBU /testbench/dut/hart/ebu/HSIZE
add wave -noupdate -group EBU /testbench/dut/hart/ebu/HBURST
add wave -noupdate -group EBU /testbench/dut/hart/ebu/HPROT
add wave -noupdate -group EBU /testbench/dut/hart/ebu/HTRANS
add wave -noupdate -group EBU /testbench/dut/hart/ebu/HMASTLOCK
add wave -noupdate -group EBU /testbench/dut/hart/ebu/HADDRD
add wave -noupdate -group EBU /testbench/dut/hart/ebu/HSIZED
add wave -noupdate -group EBU /testbench/dut/hart/ebu/HWRITED
add wave -noupdate -group EBU /testbench/dut/hart/ebu/CommitM
add wave -noupdate -group EBU /testbench/dut/hart/ebu/GrantData
add wave -noupdate -group EBU /testbench/dut/hart/ebu/AccessAddress
add wave -noupdate -group EBU /testbench/dut/hart/ebu/ISize
add wave -noupdate -group EBU /testbench/dut/hart/ebu/HRDATAMasked
add wave -noupdate -group EBU /testbench/dut/hart/ebu/ReadDataM
add wave -noupdate -group EBU /testbench/dut/hart/ebu/HRDATANext
add wave -noupdate -group EBU /testbench/dut/hart/ebu/CapturedHRDATAMasked
add wave -noupdate -group EBU /testbench/dut/hart/ebu/WriteData
add wave -noupdate -group EBU /testbench/dut/hart/ebu/IReady
add wave -noupdate -group EBU /testbench/dut/hart/ebu/DReady
add wave -noupdate -group EBU /testbench/dut/hart/ebu/CaptureDataM
add wave -noupdate -group EBU /testbench/dut/hart/ebu/CapturedDataAvailable
add wave -noupdate -group EBU /testbench/dut/hart/ebu/BusState
add wave -noupdate -group EBU /testbench/dut/hart/ebu/NextBusState
add wave -noupdate -divider W
add wave -noupdate -radix hexadecimal /testbench/PCW
add wave -noupdate -radix hexadecimal /testbench/PCtextW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/ieu/c/InstrValidW
add wave -noupdate /testbench/dut/hart/ieu/dp/ReadDataW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/ieu/dp/ResultW
add wave -noupdate -divider RegFile
add wave -noupdate /testbench/dut/hart/ieu/dp/RegWriteW
add wave -noupdate -radix unsigned /testbench/regNumExpected
add wave -noupdate -radix unsigned /testbench/dut/hart/ieu/dp/RdW
add wave -noupdate -radix hexadecimal /testbench/regExpected
add wave -noupdate /testbench/dut/hart/ieu/dp/regf/wd3
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[2]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[3]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[4]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[5]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[6]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[7]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[8]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[9]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[10]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[11]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[12]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[13]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[14]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[15]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[16]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[17]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[18]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[19]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[20]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[21]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[22]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[23]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[24]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[25]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[26]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[27]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[28]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[29]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[30]}
add wave -noupdate -radix hexadecimal {/testbench/dut/hart/ieu/dp/regf/rf[31]}
add wave -noupdate -divider CSRs
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/MSTATUS_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/MCOUNTINHIBIT_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/MCOUNTEREN_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csri/MIDELEG_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csri/MIP_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csri/MIE_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrm/MEPC_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrm/MTVEC_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrm/MCOUNTEREN_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrm/MCOUNTINHIBIT_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrm/MEDELEG_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrm/MIDELEG_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrm/MSCRATCH_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrm/MCAUSE_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrm/MTVAL_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/SSTATUS_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/SCOUNTEREN_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csri/SIP_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csri/SIE_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrs/SEPC_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrs/STVEC_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrs/SCOUNTEREN_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrs/SEDELEG_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrs/SIDELEG_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrs/SATP_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/USTATUS_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrn/UEPC_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrn/UTVEC_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrn/UIP_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrn/UIE_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrm/PMPCFG_ARRAY_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrm/PMPADDR_ARRAY_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csrm/MISA_REGW
add wave -noupdate -radix hexadecimal /testbench/dut/hart/priv/csr/genblk1/csru/FRM_REGW
add wave -noupdate -divider <NULL>
add wave -hex -r /testbench/*
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 8} {42752672 ns} 1} {{Cursor 2} {42752634 ns} 0}
quietly wave cursor active 2
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
WaveRestoreZoom {42752559 ns} {42752771 ns}
