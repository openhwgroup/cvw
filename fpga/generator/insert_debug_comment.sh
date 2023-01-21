#!/bin/bash


fileC="../src/pipelined/ebu/busfsm.sv"
signal="CurrState"
type="busstatetype"
#find ../src/pipelined/ -wholename $fileC | xargs sed "s/\(.*\(logic|statetype|busstatetype\).*$signal\)/(\* mark_debug = \"true\" \*)\1/g" | grep -i $signal

#fileC="../src/pipelined/lsu/lsu.sv"
#signal="IEUAdrM"
#type="logic"
echo "file = $fileC"
echo "signal = $signal"

echo $signal
find ../src/pipelined/ -wholename $fileC | xargs sed "s/\(.*$type.*$signal\)/(\* mark_debug = \"true\" \*)\1/g" | grep -i $signal
#exit 0
while read line; do
    readarray -d ":" -t StrArray <<< "$line"
    file="../src/pipelined/${StrArray[0]}"
    #signal=`echo "${StrArray[1]}" | awk '{$1=$1};1'`
    signal=`echo "${StrArray[1]}" | awk '{$1=$1};1'`
    readarray -d " " -t SigArray <<< $signal
    sigType=`echo "${SigArray[0]}" | awk '{$1=$1};1'`
    sigName=`echo "${SigArray[1]}" | awk '{$1=$1};1'`
    find ../src/pipelined/ -wholename $file | xargs sed -i "s/\(.*${sigType}.*${sigName}\)/(\* mark_debug = \"true\" \*)\1/g" 
done < ../constraints/marked_debug.txt
