#!/usr/bin/python3
# Madeleine Masser-Frye mmasserfrye@hmc.edu 6/22

import subprocess
import re
from multiprocessing import Pool
from ppaAnalyze import synthsfromcsv

def runCommand(module, width, tech, freq):
    command = "make synth DESIGN=ppa_{}_{} TECH={} DRIVE=INV FREQ={} MAXOPT=1 MAXCORES=1".format(module, width, tech, freq)
    subprocess.Popen(command, shell=True)

def deleteRedundant(LoT):
    '''removes any previous runs for the current synthesis specifications'''
    synthStr = "rm -rf runs/ppa_{}_{}_rv32e_{}nm_{}_*"
    for synth in LoT:   
        bashCommand = synthStr.format(*synth)
        outputCPL = subprocess.check_output(['bash','-c', bashCommand])

if __name__ == '__main__':
    
    LoT = []
    synthsToRun = []

    ##### Run specific syntheses
    # widths = [8] 
    # modules = ['mult', 'add', 'shiftleft', 'flop', 'comparator', 'priorityencoder', 'add', 'csa', 'mux2', 'mux4', 'mux8']
    # techs = ['sky90']
    # freqs = [5000]
    # for w in widths:
    #     for module in modules:
    #         for tech in techs:
    #             for freq in freqs:
    #                 LoT += [[module, str(w), tech, str(freq)]]

    ##### Run a sweep based on best delay found in existing syntheses
    arr = [-8, -6, -4, -2, 0, 2, 4, 6, 8]
    allSynths = synthsfromcsv('bestSynths.csv')
    for synth in allSynths:
        f = 1000/synth.delay
        for freq in [round(f+f*x/100) for x in arr]:
            LoT += [[synth.module, str(synth.width), synth.tech, str(freq)]]
        
    ##### Only do syntheses for which a run doesn't already exist
    bashCommand = "find . -path '*runs/ppa*rv32e*' -prune"
    output = subprocess.check_output(['bash','-c', bashCommand])
    specReg = re.compile('[a-zA-Z0-9]+')
    allSynths = output.decode("utf-8").split('\n')[:-1]
    allSynths = [specReg.findall(oneSynth)[2:7] for oneSynth in allSynths]
    allSynths = [oneSynth[0:2] + [oneSynth[3][:-2]] + [oneSynth[4]] for oneSynth in allSynths]
    for synth in LoT:
        if (synth not in allSynths):
            synthsToRun += [synth]

    pool = Pool(processes=25)
    pool.starmap(runCommand, synthsToRun)