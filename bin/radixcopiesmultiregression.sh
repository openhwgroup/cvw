#!/bin/bash
# Alessandro Maiuolo 2022
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

configFile=config/shared/wally-shared.vh

searchRadix="define RADIX 32'"..
searchCopies="define DIVCOPIES 32'"..

currRadix="define RADIX 32'h2"
currCopies="define DIVCOPIES 32'h1"
sed -i "s/$searchRadix/$currRadix/" $configFile
sed -i "s/$searchCopies/$currCopies/" $configFile
echo regression on Radix :$currRadix: and Copies :$currCopies:
./sim/regression-wally

currRadix="define RADIX 32'h2"
currCopies="define DIVCOPIES 32'h2"
sed -i "s/$searchRadix/$currRadix/" $configFile
sed -i "s/$searchCopies/$currCopies/" $configFile
echo regression on Radix :$currRadix: and Copies :$currCopies:
./sim/regression-wally

currRadix="define RADIX 32'h2"
currCopies="define DIVCOPIES 32'h4"
sed -i "s/$searchRadix/$currRadix/" $configFile
sed -i "s/$searchCopies/$currCopies/" $configFile
echo regression on Radix :$currRadix: and Copies :$currCopies:
./sim/regression-wally

currRadix="define RADIX 32'h4"
currCopies="define DIVCOPIES 32'h1"
sed -i "s/$searchRadix/$currRadix/" $configFile
sed -i "s/$searchCopies/$currCopies/" $configFile
echo regression on Radix :$currRadix: and Copies :$currCopies:
./sim/regression-wally

currRadix="define RADIX 32'h4"
currCopies="define DIVCOPIES 32'h2"
sed -i "s/$searchRadix/$currRadix/" $configFile
sed -i "s/$searchCopies/$currCopies/" $configFile
echo regression on Radix :$currRadix: and Copies :$currCopies:
./sim/regression-wally

currRadix="define RADIX 32'h4"
currCopies="define DIVCOPIES 32'h4"
sed -i "s/$searchRadix/$currRadix/" $configFile
sed -i "s/$searchCopies/$currCopies/" $configFile
echo regression on Radix :$currRadix: and Copies :$currCopies:
./sim/regression-wally