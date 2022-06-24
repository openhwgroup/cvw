#!/usr/bin/python3
# Madeleine Masser-Frye mmasserfrye@hmc.edu 6/22

import subprocess
from multiprocessing import Pool

def runCommand(config, tech, freq):
    command = "make synth DESIGN=wallypipelinedcore CONFIG={} TECH={} DRIVE=FLOP FREQ={} MAXOPT=0 MAXCORES=1".format(config, tech, freq)
    subprocess.Popen(command, shell=True)

if __name__ == '__main__':

    techs = ['sky90', 'tsmc28']
    bestAchieved = [750, 3000]
    synthsToRun = []

    
    arr = [-8, -6, -4, -2, 0, 2, 4, 6, 8]
    for i in [0, 1]:
        tech = techs[i]
        f = bestAchieved[i]
        for freq in [round(f+f*x/100) for x in arr]: # rv32e freq sweep
            synthsToRun += [['rv32e', tech, freq]]
        for config in ['rv32gc', 'rv32ic', 'rv64gc', 'rv64i', 'rv64ic']: # configs
            synthsToRun += [[config, tech, f]]
        for mod in ['FPUoff', 'noMulDiv', 'noPriv', 'PMP0', 'PMP16']: # rv64gc path variations
            config = 'rv64gc_' + mod
            synthsToRun += [[config, tech, f]]

    pool = Pool()
    pool.starmap(runCommand, synthsToRun)