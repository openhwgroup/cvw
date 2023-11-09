#!/usr/bin/python3
#
# Python regression test for DC
# Madeleine Masser-Frye mmasserfrye@hmc.edu 5/22
# James Stine james.stine@okstate.edu 15 October 2023
#

import subprocess
import re
from multiprocessing import Pool
from ppaAnalyze import synthsfromcsv

def runCommand(module, width, tech, freq):
    command = "make synth DESIGN={} WIDTH={} TECH={} DRIVE=INV FREQ={} MAXOPT=1 MAXCORES=1".format(module, width, tech, freq)
    print('here we go')

    subprocess.Popen(command, shell=True)

def deleteRedundant(synthsToRun):
    '''removes any previous runs for the current synthesis specifications'''
    synthStr = "rm -rf runs/ppa_{}_{}_rv32e_{}nm_{}_*"
    for synth in synthsToRun:   
        bashCommand = synthStr.format(*synth)
        outputCPL = subprocess.check_output(['bash','-c', bashCommand])

def freqSweep(module, width, tech):
    synthsToRun = []
    arr = [-8, -6, -4, -2, 0, 2, 4, 6, 8]
    allSynths = synthsfromcsv('ppa/bestSynths.csv')
    for synth in allSynths:
        if (synth.module == module) & (synth.tech == tech) & (synth.width == width):
            f = 1000/synth.delay
            for freq in [round(f+f*x/100) for x in arr]:
                synthsToRun += [[synth.module, str(synth.width), synth.tech, str(freq)]]
    return synthsToRun

def filterRedundant(synthsToRun):
    bashCommand = "find . -path '*runs/ppa*rv32e*' -prune"
    output = subprocess.check_output(['bash','-c', bashCommand])
    specReg = re.compile('[a-zA-Z0-9]+')
    allSynths = output.decode("utf-8").split('\n')[:-1]
    allSynths = [specReg.findall(oneSynth)[2:7] for oneSynth in allSynths]
    allSynths = [oneSynth[0:2] + [oneSynth[3][:-2]] + [oneSynth[4]] for oneSynth in allSynths]
    output = []
    for synth in synthsToRun:
        if (synth not in allSynths):
            output += [synth]
    return output

def allCombos(widths, modules, techs, freqs):
    synthsToRun = []
    for w in widths:
        for module in modules:
            for tech in techs:
                for freq in freqs:
                    synthsToRun += [[module, str(w), tech, str(freq)]]
    return synthsToRun


if __name__ == '__main__':
    
    ##### Run specific syntheses
	widths = [8, 16, 32, 64, 128] 
	modules = ['mult', 'add', 'shiftleft', 'flop', 'comparator', 'priorityencoder', 'add', 'csa', 'mux2', 'mux4', 'mux8']
	techs = ['sky90', 'tsmc28']
	freqs = [5000]
	synthsToRun = allCombos(widths, modules, techs, freqs)
    
    ##### Run a sweep based on best delay found in existing syntheses
	module = 'add'
	width = 32
	tech = 'sky90'
	synthsToRun = freqSweep(module, width, tech)
        
    ##### Only do syntheses for which a run doesn't already exist
	synthsToRun = filterRedundant(synthsToRun)
	
	pool = Pool(processes=25)
	pool.starmap(runCommand, synthsToRun)
