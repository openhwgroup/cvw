#!/bin/bash

######################
# extractFunctionRadix.sh
#
# Written: Ross Thompson
# email: ross1728@gmail.com
# Created: March 1, 2021
# Modified: March 10, 2021
#
# Purpose: Processes all compiled object files into 2 types of files which assist in debuging applications.
#          File 1: .addr: A sorted list of function starting addresses. 
#                  When a the PCE is greater than or equal to the function's starting address, the label will be associated with this address.
#          File 2: .lab: A sorted list of funciton labels. The names of functions.  Modelsim will display these names rather than the function address.
# 
# A component of the Wally configurable RISC-V project.
# 
# Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
# modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
# is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
# OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
######################


function processProgram {
    local objDumpFile=$1
    local numBits=$2
    local size=$(($numBits/4))
    local index=$3

    # when size = 16 => 64 bit
    # when size = 8 => 32 bit
    local listOfAddr=`egrep -i "^[0-9]{$size} <[0-9a-zA-Z_]+>" $objDumpFile`

    # skip if the wrong bit width.
    if [ -z "$listOfAddr" ]; then
	return 0
    fi

    # parse out the addresses and the labels
    local addresses=`echo "$listOfAddr" | awk '{print $1}'`
    local labels=`echo "$listOfAddr" | awk '{print  "\""$2"\"", "-color \"SpringGreen\","}' | tr -d '<>:'`
    local labelsName=`echo "$listOfAddr" | awk '{print  ""$2""}' | tr -d '<>:'`

    # output per program function address list
    echo "$addresses" > $objDumpFile.addr
    echo "$labelsName" > $objDumpFile.lab    

    # need to add some formatting to each line
    local numLines=`echo "$listOfAddr" | wc -l`

    return 0
}


index=0

for objDumpFile in "$@";
do

    processProgram "$objDumpFile" 32 "$index"
    processProgram "$objDumpFile" 64 "$index"

    index=$(($index+1))
    
done

exit 0

