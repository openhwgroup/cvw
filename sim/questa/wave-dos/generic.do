# default-waves.do
restart -f
delete wave /*
view wave

# Diplays All Signals recursively
add wave /testbench/clk
add wave /testbench/reset
add wave -divider
add wave -hex -r /testbench/*

# appearance
TreeUpdate [SetDefaultTree]
WaveRestoreZoom {0 ps} {300 ps}
configure wave -namecolwidth 350
configure wave -valuecolwidth 150
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
set DefaultRadix hexadecimal
