#!/usr/bin/python3
# Shreya Sanghai (ssanghai@hmc.edu) 2/28/2022
# Madeleine Masser-Frye (mmmasserfrye@hmc.edu) 06/2022
from collections import namedtuple
import glob 
import re
import csv
import subprocess
from matplotlib.cbook import flatten
import matplotlib.pyplot as plt
import matplotlib.lines as lines
import numpy as np

# field_names = [ 'Name', 'Critical Path Length', 'Cell Area', 'Synth Time']
# data = []
# for name in glob.glob("/home/ssanghai/riscv-wally/synthDC/runs/*/reports/wallypipelinedcore_qor.rep"):   
#     f = open(name, 'r')
#     # trimName = re.search("runs\/(.*?)\/reports", name).group(1)
#     trimName = re.search("wallypipelinedcore_(.*?)_sky9",name).group(1)
#     for line in f:
#         if "Critical Path Length" in line:
#             pathLen = re.search("Length: *(.*?)\\n", line).group(1) 
#         if "Cell Area" in line:
#             area = re.search("Area: *(.*?)\\n", line).group(1) 
#         if "Overall Compile Time" in line:
#             time = re.search("Time: *(.*?)\\n", line).group(1)
#     data += [{'Name' : trimName, 'Critical Path Length': pathLen, 'Cell Area' : area, 'Synth Time' :time}]

def synthsintocsv():
    ''' writes a CSV with one line for every available synthesis
        each line contains the module, tech, width, target freq, and resulting metrics
    '''
    print("This takes a moment...")
    bashCommand = "find . -path '*runs/wallypipelinedcore_*' -prune"
    output = subprocess.check_output(['bash','-c', bashCommand])
    allSynths = output.decode("utf-8").split('\n')[:-1]

    specReg = re.compile('[a-zA-Z0-9]+')
    metricReg = re.compile('-?\d+\.\d+[e]?[-+]?\d*')

    file = open("Summary.csv", "w")
    writer = csv.writer(file)
    writer.writerow(['Width', 'Config', 'Special', 'Tech', 'Target Freq', 'Delay', 'Area'])

    for oneSynth in allSynths:
        descrip = specReg.findall(oneSynth)
        width = descrip[2][:4]
        config = descrip[2][4:]
        if descrip[3][-2:] == 'nm':
            special = ''
        else:
            special = descrip[3]
            descrip = descrip[1:]
        tech = descrip[3][:-2]
        freq = descrip[4]
        metrics = []
        for phrase in ['Path Slack', 'Design Area']:
            bashCommand = 'grep "{}" '+ oneSynth[2:]+'/reports/*qor*'
            bashCommand = bashCommand.format(phrase)
            try: 
                output = subprocess.check_output(['bash','-c', bashCommand])
                nums = metricReg.findall(str(output))
                nums = [float(m) for m in nums]
                metrics += nums
            except: 
                print(config + tech + freq + " doesn't have reports")
        if metrics == []:
            pass
        else:
            delay = 1000/int(freq) - metrics[0]
            area = metrics[1]
            writer.writerow([width, config, special, tech, freq, delay, area])
    file.close()

def synthsfromcsv(filename):
    Synth = namedtuple("Synth", " width config special tech freq delay area")
    with open(filename, newline='') as csvfile:
        csvreader = csv.reader(csvfile)
        global allSynths
        allSynths = list(csvreader)[1:]
        for i in range(len(allSynths)):
            for j in range(len(allSynths[0])):
                try: allSynths[i][j] = int(allSynths[i][j])
                except: 
                    try: allSynths[i][j] = float(allSynths[i][j])
                    except: pass
            allSynths[i] = Synth(*allSynths[i])
    return allSynths

def freqPlot(tech, width, config):
    ''' plots delay, area for syntheses with specified tech, module, width
    '''

    freqsL, delaysL, areasL = ([[], []] for i in range(3))
    for oneSynth in allSynths:
        if (width == oneSynth.width) & (config == oneSynth.config) & (tech == oneSynth.tech) & (oneSynth.special == ''):
            ind = (1000/oneSynth.delay < oneSynth.freq) # when delay is within target clock period
            freqsL[ind] += [oneSynth.freq]
            delaysL[ind] += [oneSynth.delay]
            areasL[ind] += [oneSynth.area]
    
    f, (ax1, ax2) = plt.subplots(2, 1, sharex=True)

    for ind in [0,1]:
        areas = areasL[ind]
        delays = delaysL[ind]
        freqs = freqsL[ind]

        c = 'blue' if ind else 'green'
        ax1.scatter(freqs, delays, color=c)
        ax2.scatter(freqs, areas, color=c)
    
    freqs = list(flatten(freqsL))
    delays = list(flatten(delaysL))
    areas = list(flatten(areasL))

    legend_elements = [lines.Line2D([0], [0], color='green', ls='', marker='o', label='timing achieved'),
                       lines.Line2D([0], [0], color='blue', ls='', marker='o', label='slack violated')]

    ax1.legend(handles=legend_elements)
    ytop = ax2.get_ylim()[1]
    ax2.set_ylim(ymin=0, ymax=1.1*ytop)
    ax2.set_xlabel("Target Freq (MHz)")
    ax1.set_ylabel('Delay (ns)')
    ax2.set_ylabel('Area (sq microns)')
    ax1.set_title(tech + ' ' + width +config)
    plt.savefig('./plots/wally/freqSweep_' + tech + '_' + width + config + '.png')
    # plt.show()

def areaDelay(width, tech, freq, config=None, special=None):
    delays, areas, labels = ([] for i in range(3))

    for oneSynth in allSynths:
        if (width == oneSynth.width) & (tech == oneSynth.tech) & (freq == oneSynth.freq):
            if (special != None) & (oneSynth.special == special):
                delays += [oneSynth.delay]
                areas += [oneSynth.area]
                labels += [oneSynth.config]
            elif (config != None) & (oneSynth.config == config):
                delays += [oneSynth.delay]
                areas += [oneSynth.area]
                labels += [oneSynth.special]
            else:
                delays += [oneSynth.delay]
                areas += [oneSynth.area]
                labels += [oneSynth.config + '_' + oneSynth.special]
    
    f, (ax1) = plt.subplots(1, 1)
    plt.scatter(delays, areas)
    plt.xlabel('Delay (ns)')
    plt.ylabel('Area (sq microns)')
    ytop = ax1.get_ylim()[1]
    plt.ylim(ymin=0, ymax=1.1*ytop)
    titleStr = tech + ' ' + width
    saveStr = tech + '_' + width
    if config: 
        titleStr += config
        saveStr = saveStr + config + '_versions_'
    if (special != None): 
        titleStr += special
        saveStr = saveStr + '_origConfigs_'
    saveStr += str(freq)
    titleStr = titleStr + ' (target freq: ' + str(freq) + ')'
    plt.title(titleStr)

    for i in range(len(labels)):
        plt.annotate(labels[i], (delays[i], areas[i]), textcoords="offset points", xytext=(0,10), ha='center')

    plt.savefig('./plots/wally/areaDelay_' + saveStr + '.png')
    
# ending freq in 42 means fpu was turned off manually

if __name__ == '__main__':
    synthsintocsv()
    synthsfromcsv('Summary.csv')
    freqPlot('tsmc28', 'rv64', 'gc')
    areaDelay('rv32', 'tsmc28', 4200, config='gc')
    areaDelay('rv32', 'tsmc28', 3042, special='')