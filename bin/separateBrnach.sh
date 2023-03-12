#!/bin/bash

File="$1"
BeginLineNumbers=`cat $File | grep -n "BEGIN" | awk -NF ':' '{print $1}'`
Name=`cat $File | grep -n "BEGIN" | awk -NF '/' '{print $6}'`
EndLineNumbers=`cat $File | grep -n "END" | awk -NF ':' '{print $1}'`
echo $Name
echo $BeginLineNumbers
echo $EndLineNumbers

NameArray=($Name)
BeginLineNumberArray=($BeginLineNumbers)
EndLineNumberArray=($EndLineNumbers)

mkdir -p branch
Length=${#EndLineNumberArray[@]}
for i in $(seq 0 1 $((Length-1)))
do
    CurrName=${NameArray[$i]}
    CurrStart=$((${BeginLineNumberArray[$i]}+1))
    CurrEnd=$((${EndLineNumberArray[$i]}-1))
    echo $CurrName, $CurrStart, $CurrEnd
    sed -n "${CurrStart},${CurrEnd}p" $File > branch/${CurrName}_branch.log
done
