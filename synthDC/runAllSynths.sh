#!/usr/bin/bash
# Madeleine Masser-Frye mmasserfrye@hmc.edu July 2022

helpFunction()
{  echo ""
   echo "Usage: $0 "
   echo -e "\t--configs    Synthesizes wally with configurations 32e, 32ic, 64ic, 32gc, and 64gc"
   echo -e "\t--freqs NUM  Synthesizes rv32e with target frequencies at NUM MHz and +/- 2, 4, 6, 8 %"
   echo -e "\t--features   Synthesizes rv64gc versions FPUoff, noMulDiv, noPriv, PMP0, PMP16"
   exit 1 # Exit script after printing help
}

VALID_ARGS=$(getopt -o cft: --long configs,features,freqs: -- "$@")

eval set -- "$VALID_ARGS"
unset VALID_ARGS

if [[ $1 == "--" ]]; 
    then helpFunction
elif [[ $1 == "--freqs" ]] && [[ ! $2 =~ ^[[:digit:]]+$ ]]
    then echo "Argument must be an integer, target frequnecy is in MHz"
else
    make clean
    make del
    make copy 
    make configs 
    ./wallySynth.py $1 $2
    ./extractSummary.py
fi