onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench_fma16/clk
add wave -noupdate /testbench_fma16/reset
add wave -noupdate /testbench_fma16/x
add wave -noupdate /testbench_fma16/y
add wave -noupdate /testbench_fma16/z
add wave -noupdate /testbench_fma16/result
add wave -noupdate /testbench_fma16/rexpected
add wave -noupdate /testbench_fma16/dut/x
add wave -noupdate /testbench_fma16/dut/y
add wave -noupdate /testbench_fma16/dut/z
add wave -noupdate /testbench_fma16/dut/mul
add wave -noupdate /testbench_fma16/dut/add
add wave -noupdate /testbench_fma16/dut/negr
add wave -noupdate /testbench_fma16/dut/negz
add wave -noupdate /testbench_fma16/dut/roundmode
add wave -noupdate /testbench_fma16/dut/result
add wave -noupdate /testbench_fma16/dut/XManE
add wave -noupdate /testbench_fma16/dut/YManE
add wave -noupdate /testbench_fma16/dut/ZManE
add wave -noupdate /testbench_fma16/dut/XExpE
add wave -noupdate /testbench_fma16/dut/YExpE
add wave -noupdate /testbench_fma16/dut/ZExpE
add wave -noupdate /testbench_fma16/dut/PExpE
add wave -noupdate /testbench_fma16/dut/Ne
add wave -noupdate /testbench_fma16/dut/upOneExt
add wave -noupdate /testbench_fma16/dut/XSgnE
add wave -noupdate /testbench_fma16/dut/YSgnE
add wave -noupdate /testbench_fma16/dut/ZSgnE
add wave -noupdate /testbench_fma16/dut/PSgnE
add wave -noupdate /testbench_fma16/dut/ProdManE
add wave -noupdate /testbench_fma16/dut/NfracS
add wave -noupdate /testbench_fma16/dut/ProdManAl
add wave -noupdate /testbench_fma16/dut/ZManExt
add wave -noupdate /testbench_fma16/dut/ZManAl
add wave -noupdate /testbench_fma16/dut/Nfrac
add wave -noupdate /testbench_fma16/dut/res
add wave -noupdate -radix decimal /testbench_fma16/dut/AlignCnt
add wave -noupdate /testbench_fma16/dut/NSamt
add wave -noupdate /testbench_fma16/dut/ZExpGreater
add wave -noupdate /testbench_fma16/dut/ACLess
add wave -noupdate /testbench_fma16/dut/upOne
add wave -noupdate /testbench_fma16/dut/KillProd
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3746 ns} 1} {{Cursor 2} {4169 ns} 0}
quietly wave cursor active 2
configure wave -namecolwidth 237
configure wave -valuecolwidth 64
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {4083 ns} {4235 ns}
