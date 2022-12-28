#!/bin/bash

configFile=config/shared/wally-shared.vh

searchRadix="define RADIX 32'"..
searchCopies="define DIVCOPIES 32'"..

currRadix="define RADIX 32'h2"
currCopies="define DIVCOPIES 32'h1"
sed -i "s/$searchRadix/$currRadix/" $configFile
sed -i "s/$searchCopies/$currCopies/" $configFile
echo regression on Radix :$currRadix: and Copies :$currCopies:
./regression/regression-wally

currRadix="define RADIX 32'h2"
currCopies="define DIVCOPIES 32'h2"
sed -i "s/$searchRadix/$currRadix/" $configFile
sed -i "s/$searchCopies/$currCopies/" $configFile
echo regression on Radix :$currRadix: and Copies :$currCopies:
./regression/regression-wally

currRadix="define RADIX 32'h2"
currCopies="define DIVCOPIES 32'h4"
sed -i "s/$searchRadix/$currRadix/" $configFile
sed -i "s/$searchCopies/$currCopies/" $configFile
echo regression on Radix :$currRadix: and Copies :$currCopies:
./regression/regression-wally

currRadix="define RADIX 32'h4"
currCopies="define DIVCOPIES 32'h1"
sed -i "s/$searchRadix/$currRadix/" $configFile
sed -i "s/$searchCopies/$currCopies/" $configFile
echo regression on Radix :$currRadix: and Copies :$currCopies:
./regression/regression-wally

currRadix="define RADIX 32'h4"
currCopies="define DIVCOPIES 32'h2"
sed -i "s/$searchRadix/$currRadix/" $configFile
sed -i "s/$searchCopies/$currCopies/" $configFile
echo regression on Radix :$currRadix: and Copies :$currCopies:
./regression/regression-wally

currRadix="define RADIX 32'h4"
currCopies="define DIVCOPIES 32'h4"
sed -i "s/$searchRadix/$currRadix/" $configFile
sed -i "s/$searchCopies/$currCopies/" $configFile
echo regression on Radix :$currRadix: and Copies :$currCopies:
./regression/regression-wally