#!/usr/bin/python3
# Madeleine Masser-Frye mmasserfrye@hmc.edu 5/22

from collections import namedtuple
import csv
import subprocess
import re
from multiprocessing import Pool, cpu_count
from ppaAnalyze import synthsfromcsv


def runCommand(module, width, tech, freq):
    command = "make synth DESIGN=ppa_{}_{} TECH={} DRIVE=INV FREQ={} MAXOPT=1".format(module, width, tech, freq)
    subprocess.Popen(command, shell=True)

def deleteRedundant(LoT):
    '''removes any previous runs for the current synthesis specifications'''
    synthStr = "rm -rf runs/ppa_{}_{}_rv32e_{}nm_{}_*"
    for synth in LoT:   
        bashCommand = synthStr.format(*synth)
        outputCPL = subprocess.check_output(['bash','-c', bashCommand])

def getData(filename):
    Synth = namedtuple("Synth", "module tech width freq delay area lpower denergy")
    with open(filename, newline='') as csvfile:
        csvreader = csv.reader(csvfile)
        global allSynths
        allSynths = list(csvreader)
        for i in range(len(allSynths)):
            for j in range(len(allSynths[0])):
                try: allSynths[i][j] = int(allSynths[i][j])
                except: 
                    try: allSynths[i][j] = float(allSynths[i][j])
                    except: pass
            allSynths[i] = Synth(*allSynths[i])


# arr = [-5, -3, -1, 1, 3, 5]
arr2 = [-8, -6, -4, -2, 0, 2, 4, 6, 8]

widths = [128] 
modules = ['mux2', 'mux4', 'mux8', 'shiftleft', 'flop', 'comparator', 'mult', 'priorityencoder', 'add', 'csa']
techs = ['tsmc28']
LoT = []


allSynths = synthsfromcsv('ppaData.csv')

for w in widths:
    for module in modules:
        for tech in techs:
            m = 100000 # large number to start
            for oneSynth in allSynths:
                if (oneSynth.width == w) & (oneSynth.tech == tech) & (oneSynth.module == module):
                    if (oneSynth.delay < m): 
                        m = oneSynth.delay
                        synth = oneSynth
            # f = 1000/synth.delay
            for freq in [10]: #[round(f+f*x/100) for x in arr2]:
                LoT += [[synth.module, str(synth.width), synth.tech, str(freq)]]


bashCommand = "find . -path '*runs/ppa*rv32e*' -prune"
output = subprocess.check_output(['bash','-c', bashCommand])
specReg = re.compile('[a-zA-Z0-9]+')
allSynths = output.decode("utf-8").split('\n')[:-1]
allSynths = [specReg.findall(oneSynth)[2:7] for oneSynth in allSynths]
allSynths = [oneSynth[0:2] + [oneSynth[3][:-2]] + [oneSynth[4]] for oneSynth in allSynths]

synthsToRun = []
for synth in LoT:
    if synth not in allSynths:
        synthsToRun += [synth]

pool = Pool(processes=25)
pool.starmap(runCommand, synthsToRun)
pool.close()