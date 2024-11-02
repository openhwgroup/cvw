#!/bin/bash

# This file writes a bunch of bytes to the flash card based on a text
# file input with bytes written in hexadecimal.

usage() { echo "Usage: $0 [-zh] [-b <path/to/buildroot>] <device>" 1>&2; exit 1; }

help() {
    echo "Usage: $0 [OPTIONS] <device>"
    echo "  -i                          Input text file with hex bytes."
    echo "  -b <path/to/buildroot>      Output binary file."
    exit 0;
}

INPUTFILE=""
OUTPUTFILE=""

ARGS=()
while [ $OPTIND -le "$#" ] ; do
    if getopts "hi:o:" arg ; then
        case "${arg}" in
            h) help
               ;;
            i) INPUTFILE=${OPTARG}
               ;;
            o) OUTPUTFILE=${OPTARG}
               ;;
        esac
    else
        ARGS+=("${!OPTIND}")
        ((OPTIND++))
    fi
done

SDCARD=${ARGS[0]}

if [ ! -e $INPUTFILE ] ; then
    echo -e "Error: Input file $INPUTFILE does not exist."
    exit 1
fi

if [ -e $OUTPUTFILE ] ; then
    echo -e "Error: Output file $OUTPUTFILE already exists."
    exit 1
fi

for word in $(cat "$INPUTFILE")
do
    echo -en "\x$word" >> $OUTPUTFILE
done

dd if=$OUTPUTFILE of="$SDCARD"
