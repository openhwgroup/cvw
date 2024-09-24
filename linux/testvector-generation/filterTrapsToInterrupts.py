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
    num = num.strip('0')
    if num=='':
        return '0'
    else:
        return num

#############
# Main Code #
#############
print("Begin filtering traps down to just external interrupts.")

# Parse Args
if len(sys.argv) != 2:
    sys.exit('Error filterTrapsToInterrupts.py expects 1 arg: <path_to_testvector_dir>')
tvDir = sys.argv[1]+'/'
trapsFilePath = tvDir+'traps.txt'
if not os.path.exists(trapsFilePath):
    sys.exit('Error input file '+trapsFilePath+'not found')

with open(tvDir+'interrupts.txt', 'w') as interruptsFile:
    with open(trapsFilePath, 'r') as trapsFile:
        while True:
            trap = trapsFile.readline()
            if trap == '':
                break
            trapType = trap.split(' ')[-1]
            if ('interrupt' in trap) and (('external' in trapType) or ('m_timer' in trapType)): # no s_timer because that is not controlled by CLINT
                interruptsFile.write(trap) # overall line
                interruptsFile.write(trapsFile.readline()) # attempted instr count
                interruptsFile.write(trapsFile.readline()) # hart #
                interruptsFile.write(trapsFile.readline()) # asynchronous
                interruptsFile.write(trapsFile.readline()) # cause
                interruptsFile.write(trapsFile.readline()) # epc
                interruptsFile.write(trapsFile.readline()) # tval
                interruptsFile.write(trapsFile.readline()) # description
            else:
                for i in range(7):
                    trapsFile.readline()
        
print("Finished filtering traps down to just external interrupts.")
