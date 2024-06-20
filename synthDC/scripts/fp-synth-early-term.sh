#!/bin/bash

# RVF
setRVF () {
n64=$(grep -n "MISA =" $WALLY/config/rv64gc/config.vh | cut -d: -f1)
n32=$(grep -n "MISA =" $WALLY/config/rv32gc/config.vh | cut -d: -f1)
sed -i "${n64}s/MISA.*/MISA = (32\'h00000104 | 1 << 20 | 1 << 18 | 1<< 12 | 1 << 0 | 1 << 5);/" $WALLY/config/rv64gc/config.vh
sed -i "${n32}s/MISA.*/MISA = (32\'h00000104 | 1 << 20 | 1 << 18 | 1<< 12 | 1 << 0 | 1 << 5);/" $WALLY/config/rv32gc/config.vh

n64=$(grep -n "F =" $WALLY/config/rv64gc/config.vh | cut -d: -f1)
n32=$(grep -n "F =" $WALLY/config/rv32gc/config.vh | cut -d: -f1)
sed -i "${n64}s/F =.*/F = F/" $WALLY/config/rv64gc/config.vh
sed -i "${n32}s/F =.*/F = F/" $WALLY/config/rv32gc/config.vh

}

# RVD
setRVD () {
n64=$(grep -n "MISA =" $WALLY/config/rv64gc/config.vh | cut -d: -f1)
n32=$(grep -n "MISA =" $WALLY/config/rv32gc/config.vh | cut -d: -f1)
sed -i "${n64}s/MISA.*/MISA = (32\'h00000104 | 1 << 20 | 1 << 18 | 1<< 12 | 1 << 0 | 1 << 5 | 1 << 3);/" $WALLY/config/rv64gc/config.vh
sed -i "${n32}s/MISA.*/MISA = (32\'h00000104 | 1 << 20 | 1 << 18 | 1<< 12 | 1 << 0 | 1 << 5 | 1 << 3);/" $WALLY/config/rv32gc/config.vh

n64=$(grep -n "F =" $WALLY/config/rv64gc/config.vh | cut -d: -f1)
n32=$(grep -n "F =" $WALLY/config/rv32gc/config.vh | cut -d: -f1)
sed -i "${n64}s/F =.*/F = D/" $WALLY/config/rv64gc/config.vh
sed -i "${n32}s/F =.*/F = D/" $WALLY/config/rv32gc/config.vh

}

# RVD
setRVQ () {
n64=$(grep -n "MISA =" $WALLY/config/rv64gc/config.vh | cut -d: -f1)
n32=$(grep -n "MISA =" $WALLY/config/rv32gc/config.vh | cut -d: -f1)
sed -i "${n64}s/MISA.*/MISA = (32\'h00000104 | 1 << 20 | 1 << 16 | 1 << 18 | 1<< 12 | 1 << 0 | 1 << 5 | 1 << 3);/" $WALLY/config/rv64gc/config.vh
sed -i "${n32}s/MISA.*/MISA = (32\'h00000104 | 1 << 20 | 1 << 16 | 1 << 18 | 1<< 12 | 1 << 0 | 1 << 5 | 1 << 3);/" $WALLY/config/rv32gc/config.vh

n64=$(grep -n "F =" $WALLY/config/rv64gc/config.vh | cut -d: -f1)
n32=$(grep -n "F =" $WALLY/config/rv32gc/config.vh | cut -d: -f1)
sed -i "${n64}s/F =.*/F = Q/" $WALLY/config/rv64gc/config.vh
sed -i "${n32}s/F =.*/F = Q/" $WALLY/config/rv32gc/config.vh

}

# RADIX 2
setRADIXeq2 () {
n64=$(grep -n "RADIX" $WALLY/config/rv64gc/config.vh | cut -d: -f1)
n32=$(grep -n "RADIX" $WALLY/config/rv32gc/config.vh | cut -d: -f1)
sed -i "${n64}s/RADIX.*/RADIX = 32\'h2;/" $WALLY/config/rv64gc/config.vh
sed -i "${n32}s/RADIX.*/RADIX = 32\'h2;/" $WALLY/config/rv32gc/config.vh
}

# RADIX 4
setRADIXeq4 () {
n64=$(grep -n "RADIX" $WALLY/config/rv64gc/config.vh | cut -d: -f1)
n32=$(grep -n "RADIX" $WALLY/config/rv32gc/config.vh | cut -d: -f1)
sed -i "${n64}s/RADIX.*/RADIX = 32\'h4;/" $WALLY/config/rv64gc/config.vh
sed -i "${n32}s/RADIX.*/RADIX = 32\'h4;/" $WALLY/config/rv32gc/config.vh
}

# K = 1
setKeq1 () {
n64=$(grep -n "DIVCOPIES" $WALLY/config/rv64gc/config.vh | cut -d: -f1)
n32=$(grep -n "DIVCOPIES" $WALLY/config/rv32gc/config.vh | cut -d: -f1)
sed -i "${n64}s/DIVCOPIES.*/DIVCOPIES = 32\'h1;/" $WALLY/config/rv64gc/config.vh
sed -i "${n32}s/DIVCOPIES.*/DIVCOPIES = 32\'h1;/" $WALLY/config/rv32gc/config.vh
}

# K = 2
setKeq2 () {
n64=$(grep -n "DIVCOPIES" $WALLY/config/rv64gc/config.vh | cut -d: -f1)
n32=$(grep -n "DIVCOPIES" $WALLY/config/rv32gc/config.vh | cut -d: -f1)
sed -i "${n64}s/DIVCOPIES.*/DIVCOPIES = 32\'h2;/" $WALLY/config/rv64gc/config.vh
sed -i "${n32}s/DIVCOPIES.*/DIVCOPIES = 32\'h2;/" $WALLY/config/rv32gc/config.vh
}

# K = 4
setKeq4 () {
n64=$(grep -n "DIVCOPIES" $WALLY/config/rv64gc/config.vh | cut -d: -f1)
n32=$(grep -n "DIVCOPIES" $WALLY/config/rv32gc/config.vh | cut -d: -f1)
sed -i "${n64}s/DIVCOPIES.*/DIVCOPIES = 32\'h4;/" $WALLY/config/rv64gc/config.vh
sed -i "${n32}s/DIVCOPIES.*/DIVCOPIES = 32\'h4;/" $WALLY/config/rv32gc/config.vh
}

# IDIVBITS = 1
setIDIVBITSeq1 () {
n64=$(grep -n "IDIV_BITSPERCYCLE =" $WALLY/config/rv64gc/config.vh | cut -d: -f1)
n32=$(grep -n "IDIV_BITSPERCYCLE =" $WALLY/config/rv32gc/config.vh | cut -d: -f1)
sed -i "${n64}s/IDIV_BITSPERCYCLE.*/IDIV_BITSPERCYCLE = 32\'d1;/" $WALLY/config/rv64gc/config.vh
sed -i "${n32}s/IDIV_BITSPERCYCLE.*/IDIV_BITSPERCYCLE = 32\'d1;/" $WALLY/config/rv32gc/config.vh
}

# IDIVBITS = 2
setIDIVBITSeq2 () {
n64=$(grep -n "IDIV_BITSPERCYCLE =" $WALLY/config/rv64gc/config.vh | cut -d: -f1)
n32=$(grep -n "IDIV_BITSPERCYCLE =" $WALLY/config/rv32gc/config.vh | cut -d: -f1)
sed -i "${n64}s/IDIV_BITSPERCYCLE.*/IDIV_BITSPERCYCLE = 32\'d2;/" $WALLY/config/rv64gc/config.vh
sed -i "${n32}s/IDIV_BITSPERCYCLE.*/IDIV_BITSPERCYCLE = 32\'d2;/" $WALLY/config/rv32gc/config.vh
}

# IDIVBITS = 4
setIDIVBITSeq4 () {
n64=$(grep -n "IDIV_BITSPERCYCLE =" $WALLY/config/rv64gc/config.vh | cut -d: -f1)
n32=$(grep -n "IDIV_BITSPERCYCLE =" $WALLY/config/rv32gc/config.vh | cut -d: -f1)
sed -i "${n64}s/IDIV_BITSPERCYCLE.*/IDIV_BITSPERCYCLE = 32\'d4;/" $WALLY/config/rv64gc/config.vh
sed -i "${n32}s/IDIV_BITSPERCYCLE.*/IDIV_BITSPERCYCLE = 32\'d4;/" $WALLY/config/rv32gc/config.vh
}

# IDIV ON FPU
setIDIVeq1 () {
n64=$(grep -n "IDIV_ON_FPU" $WALLY/config/rv64gc/config.vh | cut -d: -f1)
n32=$(grep -n "IDIV_ON_FPU" $WALLY/config/rv32gc/config.vh | cut -d: -f1)
sed -i "${n64}s/IDIV_ON_FPU.*/IDIV_ON_FPU = 1;/" $WALLY/config/rv64gc/config.vh
sed -i "${n32}s/IDIV_ON_FPU.*/IDIV_ON_FPU = 1;/" $WALLY/config/rv32gc/config.vh
}

# IDIV NOT ON FPU
setIDIVeq0 () {
n64=$(grep -n "IDIV_ON_FPU" $WALLY/config/rv64gc/config.vh | cut -d: -f1)
n32=$(grep -n "IDIV_ON_FPU" $WALLY/config/rv32gc/config.vh | cut -d: -f1)
sed -i "${n64}s/IDIV_ON_FPU.*/IDIV_ON_FPU = 0;/" $WALLY/config/rv64gc/config.vh
sed -i "${n32}s/IDIV_ON_FPU.*/IDIV_ON_FPU = 0;/" $WALLY/config/rv32gc/config.vh
}

# Synthesize Integer Divider
synthIntDiv () {
make -C $WALLY/synthDC synth DESIGN=div TECH=tsmc28 CONFIG=rv32gc FREQ=5000 TITLE=$(getTitle) &
make -C $WALLY/synthDC synth DESIGN=div TECH=tsmc28 CONFIG=rv64gc FREQ=5000 TITLE=$(getTitle) &
make -C $WALLY/synthDC synth DESIGN=div TECH=tsmc28 CONFIG=rv32gc FREQ=100 TITLE=$(getTitle) &
make -C $WALLY/synthDC synth DESIGN=div TECH=tsmc28 CONFIG=rv64gc FREQ=100 TITLE=$(getTitle) &
wait
}

# Synthesize FP Divider Unit

synthFPDiv () {
make -C $WALLY/synthDC synth DESIGN=drsu TECH=tsmc28 CONFIG=rv32gc FREQ=5000 TITLE=$(getTitle) &
make -C $WALLY/synthDC synth DESIGN=drsu TECH=tsmc28 CONFIG=rv64gc FREQ=5000 TITLE=$(getTitle) &
make -C $WALLY/synthDC synth DESIGN=drsu TECH=tsmc28 CONFIG=rv32gc FREQ=100 TITLE=$(getTitle) &
make -C $WALLY/synthDC synth DESIGN=drsu TECH=tsmc28 CONFIG=rv64gc FREQ=100 TITLE=$(getTitle) &
wait
}

synthAll () {
    synthIntDiv &
    wait
    synthFPDiv &
    wait

}


# Synthesize DivSqrt Preprocessor

synthFPDivsqrtpreproc () {
make -C $WALLY/synthDC synth DESIGN=fdivsqrtpreproc TECH=tsmc28 CONFIG=rv32gc FREQ=3000 TITLE=$(getTitle)
make -C $WALLY/synthDC synth DESIGN=fdivsqrtpreproc TECH=tsmc28 CONFIG=rv64gc FREQ=3000 TITLE=$(getTitle)
make -C $WALLY/synthDC synth DESIGN=fdivsqrtpreproc TECH=tsmc28 CONFIG=rv32gc FREQ=100 TITLE=$(getTitle)
make -C $WALLY/synthDC synth DESIGN=fdivsqrtpreproc TECH=tsmc28 CONFIG=rv64gc FREQ=100 TITLE=$(getTitle)
}

synthFPDiviter () {
make -C $WALLY/synthDC synth DESIGN=fdivsqrtiter TECH=tsmc28 CONFIG=rv32gc FREQ=3000 TITLE=$(getTitle)
make -C $WALLY/synthDC synth DESIGN=fdivsqrtiter TECH=tsmc28 CONFIG=rv64gc FREQ=3000 TITLE=$(getTitle)
make -C $WALLY/synthDC synth DESIGN=fdivsqrtiter TECH=tsmc28 CONFIG=rv32gc FREQ=100 TITLE=$(getTitle)
make -C $WALLY/synthDC synth DESIGN=fdivsqrtiter TECH=tsmc28 CONFIG=rv64gc FREQ=100 TITLE=$(getTitle)
}

# forms title for synthesis

getTitle () {
radixline=$(grep -n "RADIX" $WALLY/config/rv64gc/config.vh | cut -d: -f1)p
RADIX=$(sed -n "$radixline" $WALLY/config/rv64gc/config.vh | tail -c 3 | head -c 1)
kline=$(grep -n "DIVCOPIES" $WALLY/config/rv64gc/config.vh | cut -d: -f1)p
K=$(sed -n "$kline" $WALLY/config/rv64gc/config.vh | tail -c 3 | head -c 1)
idivline=$(grep -n "IDIV_ON_FPU" $WALLY/config/rv64gc/config.vh | cut -d: -f1)p
IDIV=$(sed -n "$idivline" $WALLY/config/rv64gc/config.vh | tail -c 3 | head -c 1)
idivbitsline=$(grep -n "IDIV_BITSPERCYCLE =" $WALLY/config/rv64gc/config.vh | cut -d: -f1)p
IDIVBITS=$(sed -n "$idivbitsline" $WALLY/config/rv64gc/config.vh | tail -c 3 | head -c 1)
FPMODELINE=$(grep -n "F =" $WALLY/config/rv64gc/config.vh | cut -d: -f1)p
FPMODELINE=($(sed -n "$FPMODELINE" $WALLY/config/rv64gc/config.vh)) 
FPMODE=${FPMODELINE[3]}
title="RADIX_${RADIX}_K_${K}_INTDIV_${IDIV}_IDIVBITS_${IDIVBITS}_FPMODE_${FPMODE}"
echo $title
}

# writes area delay of runs to csv
writeCSV () {
    echo "design,area,timing,power" > $WALLY/synthDC/fp-synth.csv
    # iterate over all files in runs/
    for FILE in $WALLY/synthDC/runs/drsu*;
    do
        design="${FILE##*/}"

        # grab area
        areaString=($(grep "divremsqrt/fdivsqrtpostproc/earlyterm " $FILE/reports/area.rep))
        area=${areaString[1]}

        # grab timing
        timingString=($(grep "data arrival time" $FILE/reports/timing.rep))
        timing=${timingString[3]}

        # grab power
        powerString=($(grep "100.0" $FILE/reports/power.rep))
        power=${powerString[4]}

        # write to csv
        echo $design,$area,$timing,$power >> $WALLY/synthDC/fp-synth.csv
        
    done;
}

# writes area delay of runs to csv
writeCSVdiv () {
    echo "design,area,timing,power" > $WALLY/synthDC/fp-synth_intdiv.csv
    # iterate over all files in runs/
    for FILE in $WALLY/synthDC/runs/mdudiv*;
    do
        design="${FILE##*/}"

        # grab area
        areaString=($(grep "Total cell area" $FILE/reports/area.rep))
        area=${areaString[3]}

        # grab timing
        timingString=($(grep "data arrival time" $FILE/reports/timing.rep))
        timing=${timingString[3]}

        # grab power
        powerString=($(grep "100.0" $FILE/reports/power.rep))
        power=${powerString[4]}

        # write to csv
        echo $design,$area,$timing,$power >> $WALLY/synthDC/fp-synth_intdiv.csv
        
    done;
}

go() {


setIDIVeq1
# K = 1, R = 4
setKeq1
setRADIXeq4

setRVF
synthFPDiv

setRVD
synthFPDiv

setRVQ
synthFPDiv

# K = 2, R = 2
setKeq2
setRADIXeq2
synthFPDiv

setRVF
synthFPDiv

setRVD
synthFPDiv

setRVQ
synthFPDiv

# K = 1, R = 2
setKeq1
setRADIXeq2

setRVF
synthFPDiv

setRVD
synthFPDiv

setRVQ
synthFPDiv

# K = 2, R =4
setKeq2
setRADIXeq4

setRVF
synthFPDiv

setRVD
synthFPDiv

setRVQ
synthFPDiv

# K = 4, R = 2
setKeq4
setRADIXeq2

setRVF
synthFPDiv

setRVD
synthFPDiv

setRVQ
synthFPDiv

# K = 4, R = 4
setKeq4
setRADIXeq4

setRVF
synthFPDiv

setRVD
synthFPDiv

setRVQ
synthFPDiv

setIDIVeq0

# K = 1, R = 4
setKeq1
setRADIXeq4

setRVF
synthFPDiv

setRVD
synthFPDiv

setRVQ
synthFPDiv

# K = 2, R = 2
setKeq2
setRADIXeq2
synthFPDiv

setRVF
synthFPDiv

setRVD
synthFPDiv

setRVQ
synthFPDiv

# K = 1, R = 2
setKeq1
setRADIXeq2

setRVF
synthFPDiv

setRVD
synthFPDiv

setRVQ
synthFPDiv

# K = 2, R =4
setKeq2
setRADIXeq4

setRVF
synthFPDiv

setRVD
synthFPDiv

setRVQ
synthFPDiv

# K = 4, R = 2
setKeq4
setRADIXeq2

setRVF
synthFPDiv

setRVD
synthFPDiv

setRVQ
synthFPDiv

# K = 4, R = 4
setKeq4
setRADIXeq4

setRVF
synthFPDiv

setRVD
synthFPDiv

setRVQ
synthFPDiv







}

go2() {


setIDIVeq0

setIDIVBITSeq1

synthIntDiv

setIDIVBITSeq2

synthIntDiv

setIDIVBITSeq4

synthIntDiv

}
