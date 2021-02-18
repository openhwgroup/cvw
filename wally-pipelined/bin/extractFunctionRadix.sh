#!/bin/bash

for objDumpFile in "$@";
do

    # get the lines with named labels from the obj files.
    listOfAddr=`egrep -i '^[0-9]{8} <[0-9a-zA-Z_]+>' $objDumpFile`

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

done
