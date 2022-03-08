#! /usr/bin/python3
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
if len(sys.argv) != 3:
    sys.exit('Error parseUartState.py expects 2 args: <raw GDB state dump> <output state file>')
rawUartStateFile=sys.argv[1]
outUartStateFile=sys.argv[2]
if not os.path.exists(rawUartStateFile):
    sys.exit('Error input file '+rawUartStateFile+'not found')

# Main Loop
with open(rawUartStateFile, 'r') as rawUartStateFile:
    with open(outUartStateFile, 'w') as outUartStateFile:
        uartBytes = tokenize(rawUartStateFile.readline())[1:]
        # Stores
        # 0: RBR / Divisor Latch Low
        # 1: IER / Divisor Latch High
        # 2: IIR
        # 3: LCR
        # 4: MCR
        # 5: LSR
        # 6: MSR
        # 7: SCR
        for uartByte in uartBytes:
            outUartStateFile.write(uartByte[2:]+'\n')

print("Finished parsing UART state!")
