#!/usr/bin/env python3
import sys, os

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

#############
# Main Code #
#############
print("Begin parsing UART state.")

# Parse Args
if len(sys.argv) != 2:
    sys.exit('Error parseUartState.py expects 1 arg: <path_to_checkpoint_dir>')
outDir = sys.argv[1]+'/'
rawUartStateFile = outDir+'uartStateGDB.txt'
if not os.path.exists(rawUartStateFile):
    sys.exit('Error input file '+rawUartStateFile+'not found')

with open(rawUartStateFile, 'r') as rawUartStateFile:
    uartBytes = []
    for i in range(0,8):
        uartBytes += tokenize(rawUartStateFile.readline())[1:]
with open(outDir+'checkpoint-UART_IER', 'w') as outFile:
    outFile.write(uartBytes[1][2:])
with open(outDir+'checkpoint-UART_LCR', 'w') as outFile:
    outFile.write(uartBytes[3][2:])
with open(outDir+'checkpoint-UART_MCR', 'w') as outFile:
    outFile.write(uartBytes[4][2:])
with open(outDir+'checkpoint-UART_SCR', 'w') as outFile:
    outFile.write(uartBytes[7][2:])

print("Finished parsing UART state!")
