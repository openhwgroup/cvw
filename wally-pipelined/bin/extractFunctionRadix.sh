#!/bin/bash

allProgramRadixFile="FunctionRadix"
programToIndexMap="ProgramMap.txt"
index=0

# clear the files
rm -rf $allProgramRadixFile.addr $allProgramRadixFile.do $programToIndexMap

echo "radix define Functions {" > $allProgramRadixFile.do

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

    # first convert the index to a string, 16 bits length
    # then duplicate the index numlines times
    # concat the index with the address
    indexStr=`printf "%04x" "$index"`
    copyIndex=`yes "$indexStr" | head -n $numLines`
    allAddresses=`paste -d'\0' <(printf "%s" "$copyIndex") <(echo "$addresses")`
    printf "%s\n" "$allAddresses" >> $allProgramRadixFile.addr

    allAddressesTemp=`paste -d'\0' <(echo "$prefix") <(echo "$allAddresses") <(echo "$midfix") <(echo "$labels")`
    printf "%s\n" "$allAddressesTemp" >> $allProgramRadixFile.do

    testName=`echo "$objDumpFile" | sed -e "s/.*work\/\(.*\)\.elf\.objdump/\1/g"`
    printf "$testName\n" >>  $programToIndexMap

    index=$(($index+1))
    
done

# remove the last comma from the all radix
# '$ selects the last line
sed -i '$ s/,$//g' $allProgramRadixFile.do

echo "}" >> $allProgramRadixFile.do
