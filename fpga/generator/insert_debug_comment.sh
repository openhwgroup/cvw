#!/bin/bash

copiedDir="../src/CopiedFiles_do_not_add_to_repo"
while read line; do
    readarray -d ":" -t StrArray <<< "$line"
    file="${copiedDir}/${StrArray[0]}"
    #signal=`echo "${StrArray[1]}" | awk '{$1=$1};1'`
    signal=`echo "${StrArray[1]}" | awk '{$1=$1};1'`
    readarray -d " " -t SigArray <<< $signal
    sigType=`echo "${SigArray[0]}" | awk '{$1=$1};1'`
    sigName=`echo "${SigArray[1]}" | awk '{$1=$1};1'`
    find $copiedDir -wholename $file | xargs sed -i "s/\(.*${sigType}.*${sigName}\)/(\* mark_debug = \"true\" \*)\1/g" 
done < ../constraints/marked_debug.txt
