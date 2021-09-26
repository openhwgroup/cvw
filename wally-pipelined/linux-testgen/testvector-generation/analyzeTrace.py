#! /usr/bin/python3
import sys,os
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import matplotlib.ticker as ticker

# Argument Parsing
if len(sys.argv) != 4:
    sys.exit('Error analyzeTrace.py expects 3 args:\n <trace> <addresses> <labels>')
traceFile = sys.argv[1]
addressFile = sys.argv[2]
labelFile = sys.argv[3]
if not os.path.exists(traceFile):
    sys.exit('Error trace file '+traceFile+'not found')
if not os.path.exists(addressFile):
    sys.exit('Error address file '+addressFile+'not found')
if not os.path.exists(labelFile):
    sys.exit('Error label file '+labelFile+'not found')

print('Loading labels')
funcList=[]
with open(addressFile, 'r') as addresses, open(labelFile, 'r') as labels: 
    for address, label in zip(addresses, labels):
        funcList.append([int(address.strip('\n'),16),label.strip('\n'),0])

def lookupAdr(address):
    labelCount = len(funcList)
    guessIndex = labelCount
    guessAdr = funcList[guessIndex-1][0]
    if address < funcList[0][0]:
        return 0
    while (address < guessAdr):
        guessIndex-=1
        if guessIndex == -1:
            return 0
        guessAdr=funcList[guessIndex][0]
    funcList[guessIndex][2] += 1
    #print(funcList[guessIndex][1])
    return 1 
                
print('Parsing trace')
with open(traceFile, 'r') as trace:
    iCount = 0
    for l in trace:
        lookupAdr(int(l.split(' ')[0],16))
        iCount += 1
        if (iCount % 1e5==0):
            print('Reached '+str(iCount/1e6)+' million instructions')

print('Sorting by function frequency')
funcListSorted = sorted(funcList, key=lambda labelEntry: -labelEntry[2])
with open('traceAnalysis.txt','w') as outFile:
    outFile.write('Virtual Address    \t'+('%-50s'%'Function')+'Occurences\n')
    for labelEntry in funcListSorted:
        addr = '%x' % labelEntry[0]
        outFile.write(addr+'\t'+('%-50s' % labelEntry[1])+str(labelEntry[2])+'\n')
print('Logged results to traceAnalysis.txt')
