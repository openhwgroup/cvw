#!/usr/bin/env python3
import sys, os, subprocess

def main():
    maxGoodCount = 400e6 # num instrs that execute sucessfully starting from 0
    currInstrCount = maxGoodCount
    linuxTestvectors = "/opt/riscv/linux-testvectors"
    if not os.path.exists(linuxTestvectors):
        sys.stderr.write("Error: Linux testvectors not found at "+linuxTestvectors+"\n")
        exit(1)
    checkpointList = [int(fileName.strip('checkpoint')) for fileName in os.listdir(linuxTestvectors) if 'checkpoint' in fileName]
    checkpointList.sort()
    
    logDir = "./logs/buildrootBugFinderLogs/"
    os.system("mkdir -p "+logDir)
    summaryLogFilePath = logDir+"summary.log"
    summaryLogFile = open(summaryLogFilePath,'w')
    summaryLogFile.close()
    while True:
        checkpointList = [checkpoint for checkpoint in checkpointList if checkpoint > currInstrCount]
        if len(checkpointList)==0:
            break
        checkpoint = checkpointList[0]
        logFile = logDir+"checkpoint"+str(checkpoint)+".log"
        runCommand="{\nvsim -c <<!\ndo wally-batch.do buildroot buildroot /opt/riscv 0 "+str(checkpoint+1)+" "+str(checkpoint)+"\n!\n} | tee "+logFile 
        print(runCommand)
        os.system(runCommand)
        try:
            logOutput = subprocess.check_output(["grep","-e","Reached",logFile])
            currInstrCount = int(str(logOutput).strip('b').strip('\'').strip('\\n').split(' ')[-2])
        except subprocess.CalledProcessError:
            currInstrCount = checkpoint
        summaryStr="Checkpoint "+str(checkpoint)+" reached "+str(currInstrCount)+" instrs\n"
        summaryLogFile = open(summaryLogFilePath,'a')
        summaryLogFile.write(summaryStr)
        summaryLogFile.close()

    return 0

if __name__ == '__main__':
    exit(main())
