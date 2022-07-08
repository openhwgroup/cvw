#!/usr/bin/python3
# Madeleine Masser-Frye mmasserfrye@hmc.edu 6/22

import subprocess
from multiprocessing import Pool
import time
import sys

def runSynth(config, tech, freq):
    global pool
    command = "make synth DESIGN=wallypipelinedcore CONFIG={} TECH={} DRIVE=FLOP FREQ={} MAXOPT=1 MAXCORES=1".format(config, tech, freq)
    pool.map(mask, [command])

def mask(command):
    subprocess.Popen(command, shell=True)

testFreq = [3000, 10000]

if __name__ == '__main__':

    i = 0
    techs = ['sky90', 'tsmc28']
    synthsToRun = []
    tech = techs[i]
    freq = testFreq[i]
    arr = [-8, -6, -4, -2, 0, 2, 4, 6, 8]
    pool = Pool()
    staggerPeriod = 60 #seconds

    typeToRun = sys.argv[1]

    if 'configs' in typeToRun:
        for config in ['rv32gc', 'rv32ic', 'rv64gc', 'rv64ic', 'rv32e']: # configs
            config = config + '_orig' # until memory integrated
            runSynth(config, tech, freq)
            time.sleep(staggerPeriod)
    elif 'features' in typeToRun:
        for mod in ['FPUoff', 'noMulDiv', 'noPriv', 'PMP0', 'PMP16']: # rv64gc path variations
            config = 'rv64gc_' + mod
            runSynth(config, tech, freq)
            time.sleep(staggerPeriod)
    elif 'freqs' in typeToRun:
        sc = int(sys.argv[2])
        config = 'rv32e'
        for freq in [round(sc+sc*x/100) for x in arr]: # rv32e freq sweep
            runSynth(config, tech, freq)