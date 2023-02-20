#!/usr/bin/python3

###########################################
## Written: Ross Thompson ross1728@gmail.com
## Created: 4 Jan 2022
## Modified: 
##
## Purpose: Parses the performance counters from a modelsim trace.
##
## A component of the CORE-V-WALLY configurable RISC-V project.
##
## Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
##
## SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
##
## Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
## except in compliance with the License, or, at your option, the Apache License version 2.0. You 
## may obtain a copy of the License at
##
## https:##solderpad.org/licenses/SHL-2.1/
##
## Unless required by applicable law or agreed to in writing, any work distributed under the 
## License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
## either express or implied. See the License for the specific language governing permissions 
## and limitations under the License.
################################################################################################

import os
import sys
import matplotlib.pyplot as plt
import re

def ComputeCPI(benchmark):
    'Computes and inserts CPI into benchmark stats.'
    (nameString, opt, dataDict) = benchmark
    CPI = 1.0 * int(dataDict['Mcycle']) / int(dataDict['InstRet'])
    dataDict['CPI'] = CPI

def ComputeBranchDirMissRate(benchmark):
    'Computes and inserts branch direction miss prediction rate.'
    (nameString, opt, dataDict) = benchmark
    branchDirMissRate = 100.0 * int(dataDict['Br Dir Wrong']) / int(dataDict['Br Count'])
    dataDict['BDMR'] = branchDirMissRate

def ComputeBranchTargetMissRate(benchmark):
    'Computes and inserts branch target miss prediction rate.'
    # *** this is wrong in the verilog test bench
    (nameString, opt, dataDict) = benchmark
    branchTargetMissRate = 100.0 * int(dataDict['Br Target Wrong']) / (int(dataDict['Br Count']) + int(dataDict['Jump, JR, Jal']) + int(dataDict['ret']))
    dataDict['BTMR'] = branchTargetMissRate

def ComputeRASMissRate(benchmark):
    'Computes and inserts return address stack miss prediction rate.'
    (nameString, opt, dataDict) = benchmark
    RASMPR = 100.0 * int(dataDict['RAS Wrong']) / int(dataDict['ret'])
    dataDict['RASMPR'] = RASMPR

def ComputeInstrClassMissRate(benchmark):
    'Computes and inserts instruction class miss prediction rate.'
    (nameString, opt, dataDict) = benchmark
    ClassMPR = 100.0 * int(dataDict['Instr Class Wrong']) / int(dataDict['InstRet'])
    dataDict['ClassMPR'] = ClassMPR
    
def ComputeICacheMissRate(benchmark):
    'Computes and inserts instruction class miss prediction rate.'
    (nameString, opt, dataDict) = benchmark
    ICacheMR = 100.0 * int(dataDict['I Cache Miss']) / int(dataDict['I Cache Access'])
    dataDict['ICacheMR'] = ICacheMR

def ComputeDCacheMissRate(benchmark):
    'Computes and inserts instruction class miss prediction rate.'
    (nameString, opt, dataDict) = benchmark
    DCacheMR = 100.0 * int(dataDict['D Cache Miss']) / int(dataDict['D Cache Access'])
    dataDict['DCacheMR'] = DCacheMR

def ComputeAll(benchmarks):
    for benchmark in benchmarks:
        ComputeCPI(benchmark)
        ComputeBranchDirMissRate(benchmark)
        ComputeBranchTargetMissRate(benchmark)
        ComputeRASMissRate(benchmark)
        ComputeInstrClassMissRate(benchmark)
        ComputeICacheMissRate(benchmark)
        ComputeDCacheMissRate(benchmark)
    
def printStats(benchmark):
    (nameString, opt, dataDict) = benchmark
    CPI = dataDict['CPI']
    BDMR = dataDict['BDMR']
    BTMR = dataDict['BTMR']
    RASMPR = dataDict['RASMPR']
    print('Test', nameString)
    print('Compile configuration', opt)
    print('CPI \t\t\t  %1.2f' % CPI)
    print('Branch Dir Pred Miss Rate %2.2f' % BDMR)
    print('Branch Target Pred Miss Rate %2.2f' % BTMR)
    print('RAS Miss Rate \t\t  %1.2f' % RASMPR)
    print('Instr Class Miss Rate  %1.2f' % dataDict['ClassMPR'])
    print('I Cache Miss Rate  %1.4f' % dataDict['ICacheMR'])
    print('D Cache Miss Rate  %1.4f' % dataDict['DCacheMR'])
    print()

def ProcessFile(fileName):
    '''Extract preformance counters from a modelsim log.  Outputs a list of tuples for each test/benchmark.
    The tuple contains the test name, optimization characteristics, and dictionary of performance counters.'''
    # 1 find lines with Read memfile and extract test name
    # 2 parse counters into a list of (name, value) tuples (dictionary maybe?)
    benchmarks = []
    transcript = open(fileName, 'r')
    HPMClist = { }
    testName = ''
    for line in transcript.readlines():
        lineToken = line.split()
        if(len(lineToken) > 3 and lineToken[1] == 'Read' and lineToken[2] == 'memfile'):
            opt = lineToken[3].split('/')[-4]
            testName = lineToken[3].split('/')[-1].split('.')[0]
            HPMClist = { }
        elif(len(lineToken) > 4 and lineToken[1][0:3] == 'Cnt'):
            countToken = line.split('=')[1].split()
            value = int(countToken[0])
            name = ' '.join(countToken[1:])
            HPMClist[name] = value
        elif ('is done' in line):
            benchmarks.append((testName, opt, HPMClist))
    return benchmarks

def ComputeAverage(benchmarks):
    average = {}
    for (testName, opt, HPMClist) in benchmarks:
        for field in HPMClist:
            value = HPMClist[field]
            if field not in average:
                average[field] = value
            else:
                average[field] += value
    benchmarks.append(('All', '', average))

def FormatToPlot(currBenchmark):
    names = []
    values = []
    for config in currBenchmark:
        print ('config' , config)
        names.append(config[0])
        values.append(config[1])
    return (names, values)

if(sys.argv[1] == '-b'):
    configList = []
    summery = 0
    if(sys.argv[2] == '-s'):
        summery = 1
        sys.argv = sys.argv[1::]
    for config in sys.argv[2::]:
        benchmarks = ProcessFile(config)
        ComputeAverage(benchmarks)
        ComputeAll(benchmarks)
        configList.append((config.split('.')[0], benchmarks))

    # Merge all configruations into a single list
    benchmarkAll = []
    for (config, benchmarks) in configList:
        print(config)
        for benchmark in benchmarks:
            (nameString, opt, dataDict) = benchmark
            print("BENCHMARK")
            print(nameString)
            print(opt)
            print(dataDict)
            benchmarkAll.append((nameString, opt, config, dataDict))
    print('ALL!!!!!!!!!!')
    #for bench in benchmarkAll:
    #    print('BENCHMARK')
    #    print(bench)
    #print('ALL!!!!!!!!!!')

    # now extract all branch prediction direction miss rates for each
    # namestring + opt, config
    benchmarkDict = { }
    for benchmark in benchmarkAll:
        (name, opt, config, dataDict) = benchmark
        if name+'_'+opt in benchmarkDict:
            benchmarkDict[name+'_'+opt].append((config, dataDict['BDMR']))
        else:
            benchmarkDict[name+'_'+opt] = [(config, dataDict['BDMR'])]

    size = len(benchmarkDict)
    index = 1
    if(summery == 0):
        print('Number of plots', size)
        for benchmarkName in benchmarkDict:
            currBenchmark = benchmarkDict[benchmarkName]
            (names, values) = FormatToPlot(currBenchmark)
            print(names, values)
            plt.subplot(6, 7, index)
            plt.bar(names, values)
            plt.title(benchmarkName)
            plt.ylabel('BR Dir Miss Rate (%)')
            #plt.xlabel('Predictor')
            index += 1
    else:
        combined = benchmarkDict['All_']
        (name, value) = FormatToPlot(combined)
        lst = []
        dct = {}
        category = []
        length = []
        accuracy = []
        for index in range(0, len(name)):
            match = re.match(r"([a-z]+)([0-9]+)", name[index], re.I)
            percent = 100 -value[index]
            if match:
                (PredType, size) = match.groups()
                category.append(PredType)
                length.append(size)
                accuracy.append(percent)
                if(PredType not in dct):
                    dct[PredType] = ([size], [percent])
                else:
                    (currSize, currPercent) = dct[PredType]
                    currSize.append(size)
                    currPercent.append(percent)
                    dct[PredType] = (currSize, currPercent)
        print(dct)
        for cat in dct:
            (x, y) = dct[cat]
            plt.scatter(x, y, label=cat)
            plt.plot(x, y)
            plt.ylabel('Prediction Accuracy')
            plt.xlabel('Size (b or k)')
            plt.legend(loc='upper left')
    plt.show()
    
            
else:
    # steps 1 and 2
    benchmarks = ProcessFile(sys.argv[1])
    ComputeAverage(benchmarks)
    # 3 process into useful data
    # cache hit rates
    # cache fill time
    # branch predictor status
    # hazard counts
    # CPI
    # instruction distribution
    ComputeAll(benchmarks)
    for benchmark in benchmarks:
        printStats(benchmark)

