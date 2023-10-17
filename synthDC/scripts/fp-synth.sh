#!/bin/bash

# RADIX 2
setRADIXeq2 () {
sed -i "157s/RADIX.*/RADIX = 32\'h2/" $WALLY/config/rv64gc/config.vh
sed -i "157s/RADIX.*/RADIX = 32\'h2/" $WALLY/config/rv32gc/config.vh
}

# K = 1
setKeq1 () {
sed -i "158s/DIVCOPIES.*/DIVCOPIES = 32\'h1/" $WALLY/config/rv64gc/config.vh
sed -i "158s/DIVCOPIES.*/DIVCOPIES = 32\'h1/" $WALLY/config/rv32gc/config.vh
}

# K = 2
setKeq2 () {
sed -i "158s/DIVCOPIES.*/DIVCOPIES = 32\'h2/" $WALLY/config/rv64gc/config.vh
sed -i "158s/DIVCOPIES.*/DIVCOPIES = 32\'h2/" $WALLY/config/rv32gc/config.vh
}

# K = 4
setKeq4 () {
sed -i "158s/DIVCOPIES.*/DIVCOPIES = 32\'h4/" $WALLY/config/rv64gc/config.vh
sed -i "158s/DIVCOPIES.*/DIVCOPIES = 32\'h4/" $WALLY/config/rv32gc/config.vh
}

# RADIX 4
setRADIXeq4 () {
sed -i "157s/RADIX.*/RADIX = 32\'h4/" $WALLY/config/rv64gc/config.vh
sed -i "157s/RADIX.*/RADIX = 32\'h4/" $WALLY/config/rv32gc/config.vh
}

# IDIVBITS = 1
setIDIVBITSeq1 () {
sed -i "80s/IDIV_BITSPERCYCLE.*/IDIV_BITSPERCYCLE = 32\'d1/" $WALLY/config/rv64gc/config.vh
sed -i "80s/IDIV_BITSPERCYCLE.*/IDIV_BITSPERCYCLE = 32\'d1/" $WALLY/config/rv32gc/config.vh
}

# IDIVBITS = 2
setIDIVBITSeq2 () {
sed -i "80s/IDIV_BITSPERCYCLE.*/IDIV_BITSPERCYCLE = 32\'d2/" $WALLY/config/rv64gc/config.vh
sed -i "80s/IDIV_BITSPERCYCLE.*/IDIV_BITSPERCYCLE = 32\'d2/" $WALLY/config/rv32gc/config.vh
}

# IDIVBITS = 4
setIDIVBITSeq1 () {
sed -i "80s/IDIV_BITSPERCYCLE.*/IDIV_BITSPERCYCLE = 32\'d4/" $WALLY/config/rv64gc/config.vh
sed -i "80s/IDIV_BITSPERCYCLE.*/IDIV_BITSPERCYCLE = 32\'d4/" $WALLY/config/rv32gc/config.vh
}

# IDIV ON FPU
setIDIVeq1 () {
sed -i "81s/IDIV_ON_FPU.*/IDIV_ON_FPU = 1/" $WALLY/config/rv64gc/config.vh
sed -i "81s/IDIV_ON_FPU.*/IDIV_ON_FPU = 1/" $WALLY/config/rv32gc/config.vh
}

# IDIV NOT ON FPU
setIDIVeq0 () {
sed -i "81s/IDIV_ON_FPU.*/IDIV_ON_FPU = 0/" $WALLY/config/rv64gc/config.vh
sed -i "81s/IDIV_ON_FPU.*/IDIV_ON_FPU = 0/" $WALLY/config/rv32gc/config.vh
}

