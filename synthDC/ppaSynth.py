#!/usr/bin/python3
import subprocess
from multiprocessing import Pool


def runCommand(module, width, tech, freq):
    command = "make synth DESIGN=ppa_{}_{} TECH={} DRIVE=INV FREQ={} MAXOPT=1".format(module, width, tech, freq)
    subprocess.Popen(command, shell=True)

def deleteRedundant(LoT):
    '''removes any previous runs for the current synthesis specifications'''
    synthStr = "rm -rf runs/ppa_{}_{}_rv32e_{}nm_{}_*"
    for synth in LoT:   
        bashCommand = synthStr.format(*synth)
        outputCPL = subprocess.check_output(['bash','-c', bashCommand])

d = 0.26
f = 1/d * 1000
arr = [-40, -20, -8, -6, -4, -2, 0, 2, 4, 6, 8, 20, 40]

widths = ['128']
modules = ['comparator']
freqs = [str(round(f+f*x/100)) for x in arr]
tech = 'sky90'


LoT = []
for module in modules:
    for width in widths:
        for freq in freqs:
            LoT += [[module, width, tech, freq]]

deleteRedundant(LoT)

pool = Pool()
pool.starmap(runCommand, LoT)
pool.close()

bashCommand = "wait"
outputCPL = subprocess.check_output(['bash','-c', bashCommand])