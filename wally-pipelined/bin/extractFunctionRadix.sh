#!/bin/bash

######################
# extractFunctionRadix.sh
#
# Written: Ross Thompson
# email: ross1728@gmail.com
# Created: March 1, 2021
# Modified: March 10, 2021
#
# Purpose: Processes all compiled object files into 4 files which assist in debuging applications.
#          File 1: FunctionRadix.do: a custom modelsim radix which provides a human readable (string) name for each function
#                  When a the PCE is greater than or equal to the function's starting address, the label will be associated with this address.
#          File 2 and 3: FunctionRadix_32.addr and FunctionRadix_64.addr: These files contain the shorted starting addresses for each
#                        function or global assmelby label.  There are multiple applications so the adddress is program's compile index (16 bit)
#                        concatenated with the instruction address. The 32 bit version is for 32 bit programs while the 64 bit version is for 64 bit
#                        programs.
#          File 4: ProgramMap.txt: This is a list of all programs in the order in which they are compiled (32 or 64 bit).  In modelsim this is used as
#                  an associate array to find the compile index.
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
    #local size=$2
    #local numBits=$(($size*4))    
    local numBits=$2
    local size=$(($numBits/4))
    local index=$3

    # when size = 16 => 64 bit
    # when size = 8 => 32 bit
    local listOfAddr=`egrep -i "^[0-9]{$size} <[0-9a-zA-Z_]+>" $objDumpFile`
    #echo "$objDumpFile, $size, $index, $listOfAddr"

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
    #local prefix=`yes "    16#" | head -n  $numLines`
    #local midfix=`yes "# " | head -n $numLines`

    # old version which used a modelsim radix    
    # paste echos each of the 4 parts on a per line basis.
    #-d'\0' sets no delimiter
    #local temp=`paste -d'\0' <(echo "$prefix") <(echo "$addresses") <(echo "$midfix") <(echo "$labels")`
    

    # remove the last comma
    #local temp2=${temp::-1}

    #echo "radix define Functions {" > $objDumpFile.do
    #echo "$temp2" >> $objDumpFile.do
    #echo "    -default hex -color green" >> $objDumpFile.do
    #echo "}" >> $objDumpFile.do

    # now create the all in one version
    # put the index at the begining of each line

    # first convert the index to a string, 16 bits length
    # then duplicate the index numlines times
    # concat the index with the address
    local indexStr=`printf "%04x" "$index"`
    local copyIndex=`yes "$indexStr" | head -n $numLines`
    local allAddresses=`paste -d'\0' <(printf "%s" "$copyIndex") <(echo "$addresses")`
    printf "%s\n" "$allAddresses" >> ${allProgramRadixFile}_$numBits.addr

    #local allAddressesTemp=`paste -d'\0' <(echo "$prefix") <(echo "$allAddresses") <(echo "$midfix") <(echo "$labels")`
    #printf "%s\n" "$allAddressesTemp" >> $allProgramRadixFile.do

    return 0
}


allProgramRadixFile="FunctionRadix"
programToIndexMap="ProgramMap.txt"
index=0

# clear the files
#rm -rf ${allProgramRadixFile}_32.addr ${allProgramRadixFile}_64.addr $allProgramRadixFile.do $programToIndexMap
rm -rf $programToIndexMap

#echo "radix define Functions {" > $allProgramRadixFile.do

for objDumpFile in "$@";
do

    # record the file names into a table so modelsim can know which application is running.
    testName=`echo "$objDumpFile" | sed -e "s/.*work\/\(.*\)\.elf\.objdump/\1/g"`
    printf "$testName\n" >>  $programToIndexMap

    processProgram "$objDumpFile" 32 "$index"
    processProgram "$objDumpFile" 64 "$index"

    index=$(($index+1))
    
done


# remove the last comma from the all radix
# '$ selects the last line
#sed -i '$ s/,$//g' $allProgramRadixFile.do

#echo "}" >> $allProgramRadixFile.do

exit 0

