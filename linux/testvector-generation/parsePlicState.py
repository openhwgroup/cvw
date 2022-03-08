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
print("Begin parsing PLIC state.")

# Parse Args
if len(sys.argv) != 3:
    sys.exit('Error parsePlicState.py expects 2 args: <raw GDB state dump> <output state file>')
rawPlicStateFile=sys.argv[1]
outPlicStateFile=sys.argv[2]
if not os.path.exists(rawPlicStateFile):
    sys.exit('Error input file '+rawPlicStateFile+'not found')

# Main Loop
with open(rawPlicStateFile, 'r') as rawPlicStateFile:
    plicIntPriorityArray=[]
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

    # 0x0C020000 thru 0x0C020004
    plicIntEnable = tokenize(rawPlicStateFile.readline())[1:]

    # 0x0C200000
    plicIntPriorityThreshold = tokenize(rawPlicStateFile.readline())[1:]

with open(outPlicStateFile, 'w') as outPlicStateFile:
    for word in plicIntPriorityArray:
        outPlicStateFile.write(word[2:]+'\n')
    for word in plicIntEnable:
        outPlicStateFile.write(word[2:]+'\n')
    for word in plicIntPriorityThreshold:
        outPlicStateFile.write(word[2:]+'\n')

print("Finished parsing PLIC state!")
