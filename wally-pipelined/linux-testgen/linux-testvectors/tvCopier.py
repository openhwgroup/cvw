#!/usr/bin/python3
# Copies Linux testvector files from Tera to ./ (which ought to be /riscv-wally/wally-pipelined/linux-testgen/linux-testvectors/)
import os
from datetime import datetime


if not os.path.isfile('sshUname.txt'):
    print("GREETINGS FRIEND")
    print("Please supply your tera username in ./sshUname.txt")
    exit(1)
sshUnameFile = open('sshUname.txt','r')
uname = sshUnameFile.readline().strip('\n')
tera = uname+'@tera.eng.hmc.edu'

logFile = open('tvCopier.log', 'w')
def pyTee(line):
    global logFile
    print(line)
    logFile.write(line+"\n")

pyTee('Copying tvDateReporter.py from Tera')
os.system('scp '+tera+':/courses/e190ax/buildroot_boot/tvDateReporter.py ./')
pyTee('Running tvDateReporter.py Locally')
os.system('./tvDateReporter.py && mv tvDates.txt tvDatesLocal.txt')
pyTee('Running tvDateReporter.py on Tera')
os.system('ssh '+tera+'  \"cd /courses/e190ax/buildroot_boot && ./tvDateReporter.py\"')
pyTee('Copying tvDates.txt from Tera')
os.system('scp '+tera+':/courses/e190ax/buildroot_boot/tvDates.txt ./')

copyList = []

pyTee('_____________________________________________________________________')
pyTee('|         File Name        |  Local_Date  |  Tera_Date   |  Update? |')
with open('tvDatesLocal.txt') as tvDatesLocal, open('tvDates.txt') as tvDatesTera_:
    for tvDateLocal, tvDateTera_ in zip(tvDatesLocal,tvDatesTera_):
        outString = '|  '

        tvDateLocal = tvDateLocal.strip('\n').split(' ')
        tvDateTera_ = tvDateTera_.strip('\n').split(' ')

        tvFile = tvDateLocal[0]
        outString += '{:<24}'.format(tvFile)
        outString += '|  '+tvDateLocal[1]+'  |  '+tvDateTera_[1]

        tvDateLocal = tvDateLocal[1].split('-')
        tvDateTera_ = tvDateTera_[1].split('-')

        tvDateLocal = datetime(int(tvDateLocal[0]),int(tvDateLocal[1]),int(tvDateLocal[2]))
        tvDateTera_ = datetime(int(tvDateTera_[0]),int(tvDateTera_[1]),int(tvDateTera_[2]))
        
        update = tvDateTera_ >= tvDateLocal
        outString += '  |   '+('yes' if update else 'no ') + '    |'
        pyTee(outString)
        if update:
            copyList.append(tvFile)
pyTee('_____________________________________________________________________')

for tvFile in copyList:
    pyTee('Copying '+tvFile+' from Tera')
    os.system('scp '+tera+':/courses/e190ax/buildroot_boot/'+tvFile+' ./')
pyTee('Done!')
logFile.close()
