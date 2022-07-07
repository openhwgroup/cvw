#!/usr/bin/python3
# Madeleine Masser-Frye mmasserfrye@hmc.edu 6/22

import subprocess
from multiprocessing import Pool
import time

def runCommand(config, tech, freq):
    commands = ["make fresh", "make synth DESIGN=wallypipelinedcore CONFIG={} TECH={} DRIVE=FLOP FREQ={} MAXOPT=0 MAXCORES=1".format(config, tech, freq)]
    for c in commands:
        subprocess.Popen(c, shell=True)
    # time.sleep(60) fix only do this when diff configs

testFreq = [3000, 10000]

if __name__ == '__main__':

    techs = ['sky90', 'tsmc28']
    sweepCenter = [870, 2940]
    synthsToRun = []

    arr = [-8, -6, -4, -2, 0, 2, 4, 6, 8]
    pool = Pool()

    for i in [0]: 
        tech = techs[i]
        sc = sweepCenter[i]
        f = testFreq[i]
        for freq in [round(sc+sc*x/100) for x in arr]: # rv32e freq sweep
            synthsToRun += [['rv32e', tech, freq]]
        # for config in ['rv32gc', 'rv32ic', 'rv64gc', 'rv64ic', 'rv32e']: # configs
        #     config = config + '_FPUoff' # while FPU under rennovation
        #     synthsToRun += [[config, tech, f]]
        # for mod in ['noMulDiv', 'noPriv', 'PMP0', 'PMP16']: # rv64gc path variations
        #     config = 'rv64gc_' + mod
        #     synthsToRun += [[config, tech, f]]

        for x in synthsToRun:
            pool.starmap(runCommand, [x])