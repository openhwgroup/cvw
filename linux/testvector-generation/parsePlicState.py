#!/usr/bin/env python3
import sys, os
from functools import reduce

################
# Helper Funcs #
################

def tokenize(string):
    tokens = []
    token = ''
    whitespace = 0
    prevWhitespace = 0
    for char in string:
        prevWhitespace = whitespace
        whitespace = char in ' \t\n'
        if (whitespace):
            if ((not prevWhitespace) and (token != '')): 
                tokens.append(token)
            token = ''
        else:
            token = token + char
    return tokens

def strip0x(num):
    return num[2:]

def stripZeroes(num):
    num = int(num,16)
    return hex(num)[2:]

#############
# Main Code #
#############
print("Begin parsing PLIC state.")

# Parse Args
if len(sys.argv) != 2:
    sys.exit('Error parsePlicState.py expects 1 arg: <path_to_checkpoint_dir>')
outDir = sys.argv[1]+'/'
rawPlicStateFile = outDir+'plicStateGDB.txt'
if not os.path.exists(rawPlicStateFile):
    sys.exit('Error input file '+rawPlicStateFile+'not found')

with open(rawPlicStateFile, 'r') as rawPlicStateFile:
    plicIntPriorityArray = [] # iterates over number of different sources
    # 0x0C000004 thru 0x0C000010
    plicIntPriorityArray += tokenize(rawPlicStateFile.readline())[1:]
    # 0x0C000014 thru 0x0C000020
    plicIntPriorityArray += tokenize(rawPlicStateFile.readline())[1:]
    # 0x0C000024 thru 0x0C000030
    plicIntPriorityArray += tokenize(rawPlicStateFile.readline())[1:]
    # 0x0C000034 thru 0x0C000040
    plicIntPriorityArray += tokenize(rawPlicStateFile.readline())[1:]
    # 0x0C000044 thru 0x0C000050
    plicIntPriorityArray += tokenize(rawPlicStateFile.readline())[1:]
    # 0x0C000054 thru 0x0C000060
    plicIntPriorityArray += tokenize(rawPlicStateFile.readline())[1:]
    # 0x0C000064 thru 0x0C000070
    plicIntPriorityArray += tokenize(rawPlicStateFile.readline())[1:]
    # 0x0C000074 thru 0x0C000080
    plicIntPriorityArray += tokenize(rawPlicStateFile.readline())[1:]
    # 0x0C000084 thru 0x0C000090
    plicIntPriorityArray += tokenize(rawPlicStateFile.readline())[1:]
    # 0x0C000094 thru 0x0C0000a0
    plicIntPriorityArray += tokenize(rawPlicStateFile.readline())[1:]
    # 0x0C0000a4 thru 0x0C0000b0
    plicIntPriorityArray += tokenize(rawPlicStateFile.readline())[1:]
    # 0x0C0000b4 thru 0x0C0000c0
    plicIntPriorityArray += tokenize(rawPlicStateFile.readline())[1:]
    # 0x0C0000c4 thru 0x0C0000d0
    plicIntPriorityArray += tokenize(rawPlicStateFile.readline())[1:]
    # 0x0C0000d4 thru 0x0C0000e0
    plicIntPriorityArray += tokenize(rawPlicStateFile.readline())[1:]
    # 0x0C0000e4 thru 0x0C0000f0
    plicIntPriorityArray += tokenize(rawPlicStateFile.readline())[1:]
    # 0x0C0000f4 thru 0x0C0000fc
    plicIntPriorityArray += tokenize(rawPlicStateFile.readline())[1:]

    plicIntEnableArray = [] # iterates over number of different contexts
    # 0x0C020000 thru 0x0C020004
    plicIntEnable = tokenize(rawPlicStateFile.readline())[1:]
    plicIntEnable = map(strip0x,plicIntEnable)
    plicIntEnableArray.append(reduce(lambda x,y: y+x,plicIntEnable))
    # 0x0C020080 thru 0x0C020084
    plicIntEnable = tokenize(rawPlicStateFile.readline())[1:]
    plicIntEnable = map(strip0x,plicIntEnable)
    plicIntEnableArray.append(reduce(lambda x,y: y+x,plicIntEnable))

    plicIntPriorityThresholdArray = [] # iterates over number of different contexts
    # 0x0C200000
    plicIntPriorityThresholdArray += tokenize(rawPlicStateFile.readline())[1:]
    # 0x0C201000
    plicIntPriorityThresholdArray += tokenize(rawPlicStateFile.readline())[1:]

with open(outDir+'checkpoint-PLIC_INT_PRIORITY', 'w') as outFile:
    for word in plicIntPriorityArray:
        outFile.write(stripZeroes(word[2:])+'\n')
with open(outDir+'checkpoint-PLIC_INT_ENABLE', 'w') as outFile:
    for word in plicIntEnableArray:
        outFile.write(stripZeroes(word[2:])+'\n')
with open(outDir+'checkpoint-PLIC_THRESHOLD', 'w') as outFile:
    for word in plicIntPriorityThresholdArray:
        outFile.write(stripZeroes(word[2:])+'\n')

print("Finished parsing PLIC state!")
