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

widths = ['8', '16', '32', '64', '128']
modules = ['shifter']
freqs = ['10', '5000']
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