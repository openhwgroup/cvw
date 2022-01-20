onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider <NULL>
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/reset
add wave -noupdate -radix decimal /testbench/errorCount
add wave -noupdate -radix decimal /testbench/InstrCountW
add wave -noupdate -divider Stalls_and_Flushes
add wave -noupdate /testbench/dut/core/StallF
add wave -noupdate /testbench/dut/core/StallD
add wave -noupdate /testbench/dut/core/StallE
add wave -noupdate /testbench/dut/core/StallM
add wave -noupdate /testbench/dut/core/StallW
add wave -noupdate /testbench/dut/core/FlushD
add wave -noupdate /testbench/dut/core/FlushE
add wave -noupdate /testbench/dut/core/FlushM
add wave -noupdate /testbench/dut/core/FlushW
add wave -noupdate -divider F
add wave -noupdate -radix hexadecimal /testbench/dut/core/ifu/PCF
add wave -noupdate -divider D
add wave -noupdate -radix hexadecimal /testbench/dut/core/ifu/PCD
add wave -noupdate /testbench/InstrDName
add wave -noupdate -radix hexadecimal /testbench/dut/core/ifu/InstrD
add wave -noupdate -radix hexadecimal /testbench/dut/core/ieu/c/InstrValidD
add wave -noupdate -divider E
add wave -noupdate -radix hexadecimal /testbench/dut/core/ifu/PCE
add wave -noupdate /testbench/InstrEName
add wave -noupdate -radix hexadecimal /testbench/dut/core/ifu/InstrE
add wave -noupdate -radix hexadecimal /testbench/dut/core/ieu/c/InstrValidE
add wave -noupdate -radix hexadecimal /testbench/dut/core/ieu/dp/SrcAE
add wave -noupdate -radix hexadecimal /testbench/dut/core/ieu/dp/SrcBE
add wave -noupdate -radix hexadecimal /testbench/dut/core/ieu/dp/ALUResultE
add wave -noupdate -divider M
add wave -noupdate -radix hexadecimal /testbench/dut/core/ifu/PCM
add wave -noupdate /testbench/InstrMName
add wave -noupdate /testbench/textM
add wave -noupdate -radix hexadecimal /testbench/dut/core/ifu/InstrM
add wave -noupdate -radix hexadecimal /testbench/dut/core/ieu/c/InstrValidM
add wave -noupdate -radix hexadecimal /testbench/dut/core/lsu.bus.dcache/MemPAdrM
add wave -noupdate -radix hexadecimal /testbench/dut/core/lsu.bus.dcache/MemRWM
add wave -noupdate /testbench/dut/core/lsu.bus.dcache/WriteDataM
add wave -noupdate -radix hexadecimal /testbench/dut/core/lsu.bus.dcache/ReadDataM
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/DTLBWalk
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/BasePageTablePPN
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/CurrentPPN
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/MemWrite
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/Executable
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/Writable
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/Readable
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/Valid
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/Misaligned
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/MegapageMisaligned
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/ValidPTE
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/LeafPTE
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/ValidLeafPTE
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/ValidNonLeafPTE
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/StartWalk
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/TLBMiss
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/PRegEn
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/NextPageType
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/SvMode
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/TranslationVAdr
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/WalkerState
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/NextWalkerState
add wave -noupdate -group Walker /testbench/dut/core/lsu/hptw/genblk1/InitialWalkerState
add wave -noupdate -group LSU -r /testbench/dut/core/lsu/*
add wave -noupdate -group DCache -r /testbench/dut/core/lsu.bus.dcache/*
add wave -noupdate -group EBU /testbench/dut/core/ebu/clk
add wave -noupdate -group EBU /testbench/dut/core/ebu/reset
add wave -noupdate -group EBU /testbench/dut/core/ebu/StallW
add wave -noupdate -group EBU /testbench/dut/core/ebu/UnsignedLoadM
add wave -noupdate -group EBU /testbench/dut/core/ebu/AtomicMaskedM
add wave -noupdate -group EBU /testbench/dut/core/ebu/Funct7M
add wave -noupdate -group EBU /testbench/dut/core/ebu/InstrPAdrF
add wave -noupdate -group EBU /testbench/dut/core/ebu/InstrReadF
add wave -noupdate -group EBU /testbench/dut/core/ebu/InstrRData
add wave -noupdate -group EBU /testbench/dut/core/ebu/InstrAckF
add wave -noupdate -group EBU /testbench/dut/core/ebu/DCtoAHBPAdrM
add wave -noupdate -group EBU /testbench/dut/core/ebu/DCtoAHBReadM
add wave -noupdate -group EBU /testbench/dut/core/ebu/DCtoAHBWriteM
add wave -noupdate -group EBU /testbench/dut/core/ebu/DCtoAHBWriteData
add wave -noupdate -group EBU /testbench/dut/core/ebu/DCfromAHBReadData
add wave -noupdate -group EBU /testbench/dut/core/ebu/MemSizeM
add wave -noupdate -group EBU /testbench/dut/core/ebu/DCfromAHBAck
add wave -noupdate -group EBU /testbench/dut/core/ebu/HRDATA
add wave -noupdate -group EBU /testbench/dut/core/ebu/HREADY
add wave -noupdate -group EBU /testbench/dut/core/ebu/HRESP
add wave -noupdate -group EBU /testbench/dut/core/ebu/HCLK
add wave -noupdate -group EBU /testbench/dut/core/ebu/HRESETn
add wave -noupdate -group EBU /testbench/dut/core/ebu/HADDR
add wave -noupdate -group EBU /testbench/dut/core/ebu/HWDATA
add wave -noupdate -group EBU /testbench/dut/core/ebu/HWRITE
add wave -noupdate -group EBU /testbench/dut/core/ebu/HSIZE
add wave -noupdate -group EBU /testbench/dut/core/ebu/HBURST
add wave -noupdate -group EBU /testbench/dut/core/ebu/HPROT
add wave -noupdate -group EBU /testbench/dut/core/ebu/HTRANS
add wave -noupdate -group EBU /testbench/dut/core/ebu/HMASTLOCK
add wave -noupdate -group EBU /testbench/dut/core/ebu/HADDRD
add wave -noupdate -group EBU /testbench/dut/core/ebu/HSIZED
add wave -noupdate -group EBU /testbench/dut/core/ebu/HWRITED
add wave -noupdate -group EBU /testbench/dut/core/ebu/GrantData
add wave -noupdate -group EBU /testbench/dut/core/ebu/AccessAddress
add wave -noupdate -group EBU /testbench/dut/core/ebu/ISize
add wave -noupdate -group EBU /testbench/dut/core/ebu/HRDATAMasked
add wave -noupdate -group EBU /testbench/dut/core/ebu/ReadDataM
add wave -noupdate -group EBU /testbench/dut/core/ebu/HRDATANext
add wave -noupdate -group EBU /testbench/dut/core/ebu/CapturedHRDATAMasked
add wave -noupdate -group EBU /testbench/dut/core/ebu/WriteData
add wave -noupdate -group EBU /testbench/dut/core/ebu/IReady
add wave -noupdate -group EBU /testbench/dut/core/ebu/DReady
add wave -noupdate -group EBU /testbench/dut/core/ebu/CaptureDataM
add wave -noupdate -group EBU /testbench/dut/core/ebu/CapturedDataAvailable
add wave -noupdate -group EBU /testbench/dut/core/ebu/BusState
add wave -noupdate -group EBU /testbench/dut/core/ebu/NextBusState
add wave -noupdate -divider W
add wave -noupdate -radix hexadecimal /testbench/PCW
add wave -noupdate -radix hexadecimal /testbench/dut/core/ieu/c/InstrValidW
add wave -noupdate /testbench/textM
add wave -noupdate /testbench/dut/core/ieu/dp/ReadDataW
add wave -noupdate -radix hexadecimal /testbench/dut/core/ieu/dp/ResultW
add wave -noupdate -group RF /testbench/dut/core/ieu/dp/RegWriteW
add wave -noupdate -group RF -radix unsigned /testbench/dut/core/ieu/dp/RdW
add wave -noupdate -group RF /testbench/dut/core/ieu/dp/regf/wd3
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[2]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[3]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[4]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[5]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[6]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[7]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[8]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[9]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[10]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[11]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[12]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[13]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[14]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[15]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[16]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[17]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[18]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[19]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[20]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[21]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[22]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[23]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[24]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[25]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[26]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[27]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[28]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[29]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[30]}
add wave -noupdate -group RF -radix hexadecimal {/testbench/dut/core/ieu/dp/regf/rf[31]}
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/MSTATUS_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/MCOUNTINHIBIT_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/MCOUNTEREN_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csri/MIDELEG_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csri/MIP_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csri/MIE_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrm/MEPC_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrm/MTVEC_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrm/MCOUNTEREN_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrm/MCOUNTINHIBIT_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrm/MEDELEG_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrm/MIDELEG_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrm/MSCRATCH_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrm/MCAUSE_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrm/MTVAL_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/SSTATUS_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/SCOUNTEREN_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csri/SIP_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csri/SIE_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrs/SEPC_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrs/STVEC_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrs/SCOUNTEREN_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrs/SEDELEG_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrs/SIDELEG_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrs/SATP_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/USTATUS_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrn/UEPC_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrn/UTVEC_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrn/UIP_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrn/UIE_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrm/PMPCFG_ARRAY_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrm/PMPADDR_ARRAY_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csrm/MISA_REGW
add wave -noupdate -group CSR -radix hexadecimal /testbench/dut/core/priv/csr/genblk1/csru/FRM_REGW
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
