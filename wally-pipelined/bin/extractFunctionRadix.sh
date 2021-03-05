#!/bin/bash

allProgramRadixFile="FunctionRadix"

index=0

for objDumpFile in "$@";
do
    # get the lines with named labels from the obj files.
    # 64 bit addresses
    listOfAddr16=`egrep -i '^[0-9]{16} <[0-9a-zA-Z_]+>' $objDumpFile`
    # 32 bit addresses
    listOfAddr8=`egrep -i '^[0-9]{8} <[0-9a-zA-Z_]+>' $objDumpFile`
    listOfAddr=`echo "$listOfAddr16" "$listOfAddr8"`

    # parse out the addresses and the labels
    addresses=`echo "$listOfAddr" | awk '{print $1}'`
    labels=`echo "$listOfAddr" | awk '{print  "\""$2"\"", "-color \"SpringGreen\","}' | tr -d '<>:'`

    echo "$addresses" > $objDumpFile.addr

    # need to add some formatting to each line
    numLines=`echo "$listOfAddr" | wc -l`
    prefix=`yes "    16#" | head -n  $numLines`
    midfix=`yes "# " | head -n $numLines`

    # paste echos each of the 4 parts on a per line basis.
    #-d'\0' sets no delimiter
    temp=`paste -d'\0' <(echo "$prefix") <(echo "$addresses") <(echo "$midfix") <(echo "$labels")`

    # remove the last comma
    temp2=${temp::-1}

    echo "radix define Functions {" > $objDumpFile.do
    echo "$temp2" >> $objDumpFile.do
    echo "    -default hex -color green" >> $objDumpFile.do
    echo "}" >> $objDumpFile.do

    # now create the all in one version
    # put the index at the begining of each line
    allAddresses=`paste -d'\0' <(printf "%04x" "$index") <(echo "$addresses")`

    printf "%04x%s" "$index" "$addresses" >> $allProgramRadixFile.addr

    index=$(($index+1))
    
done
