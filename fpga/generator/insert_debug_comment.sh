#!/bin/bash
###########################################
## insert_debug_comment.sh
##
## Written: Rose Thompson ross1728@gmail.com
## Created: 20 January 2023
## Modified: 16 April 2024
##
## A component of the CORE-V-WALLY configurable RISC-V project.
## https://github.com/openhwgroup/cvw
##
## Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
##
## SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
##
## Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
## except in compliance with the License, or, at your option, the Apache License version 2.0. You 
## may obtain a copy of the License at
##
## https:##solderpad.org#licenses#SHL-2.1#
##
## Unless required by applicable law or agreed to in writing, any work distributed under the 
## License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
## either express or implied. See the License for the specific language governing permissions 
## and limitations under the License.
################################################################################################

# This script copies wally's pipelined#src to fpga#src#CopiedFiles_do_not_add_to_repo
# Then it processes them to add mark_debug on signals needed by the FPGA's ILA.
copiedDir="../src/CopiedFiles_do_not_add_to_repo"
while read line; do
    # older versions of bash are incompatible with readarray -d :(
    #readarray -d ":" -t StrArray <<< "$line"
    #file="${copiedDir}/${StrArray[0]}"
    #signal=`echo "${StrArray[1]}" | awk '{$1=$1};1'`
    fileName=`echo $line | cut -d  ":" -f 1`
    file=${copiedDir}/$fileName
    signal=`echo $line | cut -d  ":" -f 2`
    echo $file
    echo $signal
    readarray -d " " -t SigArray <<< $signal
    sigType=`echo $signal | cut -d " " -f 1`
    sigType=`echo $sigType | awk '{$1=$1};1'`
    sigName=`echo $signal | cut -d " " -f 2`
    sigName=`echo $sigName | awk '{$1=$1};1'`
    #sigType=`echo "${SigArray[0]}" | awk '{$1=$1};1'`
    #sigName=`echo "${SigArray[1]}" | awk '{$1=$1};1'`
    find $copiedDir -wholename $file | xargs sed -i "s/\(.*${sigType}.*${sigName}\)/(\* mark_debug = \"true\" \*)\1/g" 
done < ../constraints/marked_debug.txt
