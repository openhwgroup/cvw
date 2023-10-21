#!/bin/bash

# RADIX 2
setRADIXeq2 () {
sed -i "157s/RADIX.*/RADIX = 32\'h2;/" $WALLY/config/rv64gc/config.vh
sed -i "157s/RADIX.*/RADIX = 32\'h2;/" $WALLY/config/rv32gc/config.vh
}

# RADIX 4
setRADIXeq4 () {
sed -i "157s/RADIX.*/RADIX = 32\'h4;/" $WALLY/config/rv64gc/config.vh
sed -i "157s/RADIX.*/RADIX = 32\'h4;/" $WALLY/config/rv32gc/config.vh
}

# K = 1
setKeq1 () {
sed -i "158s/DIVCOPIES.*/DIVCOPIES = 32\'h1;/" $WALLY/config/rv64gc/config.vh
sed -i "158s/DIVCOPIES.*/DIVCOPIES = 32\'h1;/" $WALLY/config/rv32gc/config.vh
}

# K = 2
setKeq2 () {
sed -i "158s/DIVCOPIES.*/DIVCOPIES = 32\'h2;/" $WALLY/config/rv64gc/config.vh
sed -i "158s/DIVCOPIES.*/DIVCOPIES = 32\'h2;/" $WALLY/config/rv32gc/config.vh
}

# K = 4
setKeq4 () {
sed -i "158s/DIVCOPIES.*/DIVCOPIES = 32\'h4;/" $WALLY/config/rv64gc/config.vh
sed -i "158s/DIVCOPIES.*/DIVCOPIES = 32\'h4;/" $WALLY/config/rv32gc/config.vh
}

# IDIVBITS = 1
setIDIVBITSeq1 () {
sed -i "80s/IDIV_BITSPERCYCLE.*/IDIV_BITSPERCYCLE = 32;\'d1/" $WALLY/config/rv64gc/config.vh
sed -i "80s/IDIV_BITSPERCYCLE.*/IDIV_BITSPERCYCLE = 32;\'d1/" $WALLY/config/rv32gc/config.vh
}

# IDIVBITS = 2
setIDIVBITSeq2 () {
sed -i "80s/IDIV_BITSPERCYCLE.*/IDIV_BITSPERCYCLE = 32;\'d2/" $WALLY/config/rv64gc/config.vh
sed -i "80s/IDIV_BITSPERCYCLE.*/IDIV_BITSPERCYCLE = 32;\'d2/" $WALLY/config/rv32gc/config.vh
}

# IDIVBITS = 4
setIDIVBITSeq4 () {
sed -i "80s/IDIV_BITSPERCYCLE.*/IDIV_BITSPERCYCLE = 32;\'d4/" $WALLY/config/rv64gc/config.vh
sed -i "80s/IDIV_BITSPERCYCLE.*/IDIV_BITSPERCYCLE = 32;\'d4/" $WALLY/config/rv32gc/config.vh
}

# IDIV ON FPU
setIDIVeq1 () {
sed -i "81s/IDIV_ON_FPU.*/IDIV_ON_FPU = 1;/" $WALLY/config/rv64gc/config.vh
sed -i "81s/IDIV_ON_FPU.*/IDIV_ON_FPU = 1;/" $WALLY/config/rv32gc/config.vh
}

# IDIV NOT ON FPU
setIDIVeq0 () {
sed -i "81s/IDIV_ON_FPU.*/IDIV_ON_FPU = 0;/" $WALLY/config/rv64gc/config.vh
sed -i "81s/IDIV_ON_FPU.*/IDIV_ON_FPU = 0;/" $WALLY/config/rv32gc/config.vh
}

# Synthesize Integer Divider
synthIntDiv () {
make -C $WALLY/synthDC synth DESIGN=div TECH=tsmc28 CONFIG=rv32gc FREQ=3000 WRAPPER=1 TITLE=$(getTitle) &
make -C $WALLY/synthDC synth DESIGN=div TECH=tsmc28 CONFIG=rv64gc FREQ=3000 WRAPPER=1 TITLE=$(getTitle) &
make -C $WALLY/synthDC synth DESIGN=div TECH=tsmc28 CONFIG=rv32gc FREQ=100 WRAPPER=1 TITLE=$(getTitle) &
make -C $WALLY/synthDC synth DESIGN=div TECH=tsmc28 CONFIG=rv64gc FREQ=100 WRAPPER=1 TITLE=$(getTitle) &
wait
}

# Synthesize FP Divider Unit

synthFPDiv () {
make -C $WALLY/synthDC synth DESIGN=drsu TECH=tsmc28 CONFIG=rv32gc FREQ=3000 WRAPPER=1 TITLE=$(getTitle) &
make -C $WALLY/synthDC synth DESIGN=drsu TECH=tsmc28 CONFIG=rv64gc FREQ=3000 WRAPPER=1 TITLE=$(getTitle) &
make -C $WALLY/synthDC synth DESIGN=drsu TECH=tsmc28 CONFIG=rv32gc FREQ=100 WRAPPER=1 TITLE=$(getTitle) &
make -C $WALLY/synthDC synth DESIGN=drsu TECH=tsmc28 CONFIG=rv64gc FREQ=100 WRAPPER=1 TITLE=$(getTitle) &
wait
}

synthAll () {
    synthIntDiv &
    synthFPDiv &
    wait

}


# Synthesize DivSqrt Preprocessor

synthFPDivsqrtpreproc () {
make -C $WALLY/synthDC synth DESIGN=fdivsqrtpreproc TECH=tsmc28 CONFIG=rv32gc FREQ=3000 WRAPPER=1 TITLE=$(getTitle)
make -C $WALLY/synthDC synth DESIGN=fdivsqrtpreproc TECH=tsmc28 CONFIG=rv64gc FREQ=3000 WRAPPER=1 TITLE=$(getTitle)
make -C $WALLY/synthDC synth DESIGN=fdivsqrtpreproc TECH=tsmc28 CONFIG=rv32gc FREQ=100 WRAPPER=1 TITLE=$(getTitle)
make -C $WALLY/synthDC synth DESIGN=fdivsqrtpreproc TECH=tsmc28 CONFIG=rv64gc FREQ=100 WRAPPER=1 TITLE=$(getTitle)
}

synthFPDiviter () {
make -C $WALLY/synthDC synth DESIGN=fdivsqrtiter TECH=tsmc28 CONFIG=rv32gc FREQ=3000 WRAPPER=1 TITLE=$(getTitle)
make -C $WALLY/synthDC synth DESIGN=fdivsqrtiter TECH=tsmc28 CONFIG=rv64gc FREQ=3000 WRAPPER=1 TITLE=$(getTitle)
make -C $WALLY/synthDC synth DESIGN=fdivsqrtiter TECH=tsmc28 CONFIG=rv32gc FREQ=100 WRAPPER=1 TITLE=$(getTitle)
make -C $WALLY/synthDC synth DESIGN=fdivsqrtiter TECH=tsmc28 CONFIG=rv64gc FREQ=100 WRAPPER=1 TITLE=$(getTitle)
}

# forms title for synthesis

getTitle () {
RADIX=$(sed -n "157p" $WALLY/config/rv64gc/config.vh | tail -c 3 | head -c 1)
K=$(sed -n "158p" $WALLY/config/rv64gc/config.vh | tail -c 3 | head -c 1)
IDIV=$(sed -n "81p" $WALLY/config/rv64gc/config.vh | tail -c 3 | head -c 1)
IDIVBITS=$(sed -n "80p" $WALLY/config/rv64gc/config.vh | tail -c 3 | head -c 1)
title="RADIX_${RADIX}_K_${K}_INTDIV_${IDIV}_IDIVBITS_${IDIVBITS}"
echo $title
}

# writes area delay of runs to csv
writeCSV () {
    echo "design,area,timing" > $WALLY/synthDC/fp-synth.csv
    # iterate over all files in runs/
    for FILE in $WALLY/synthDC/runs/*;
    do
        design="${FILE##*/}"

        # grab area
        areaString=($(grep "Total cell area" $FILE/reports/area.rep))
        area=${areaString[3]}

        # grab timing
        timingString=($(grep "data arrival time" $FILE/reports/timing.rep))
        timing=${timingString[3]}

        # write to csv
        echo $design,$area,$timing >> $WALLY/synthDC/fp-synth.csv
        
    done;
}

go() {

setKeq1
setRADIXeq4
synthAll
setKeq2
setRADIXeq2
synthAll

}
