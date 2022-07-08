#!/usr/bin/python3
# Madeleine Masser-Frye (mmmasserfrye@hmc.edu) 06/2022
from collections import namedtuple
import re
import csv
import subprocess
from matplotlib.cbook import flatten
import matplotlib.pyplot as plt
import matplotlib.lines as lines
from wallySynth import testFreq
import numpy as np
from ppa.ppaAnalyze import noOutliers
from matplotlib import ticker


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
                print(width + config + tech + '_' + freq + " doesn't have reports")
        if metrics == []:
            pass
        else:
            delay = 1000/int(freq) - metrics[0]
            area = metrics[1]
            writer.writerow([width, config, special, tech, freq, delay, area])
    file.close()

def synthsfromcsv(filename):
    Synth = namedtuple("Synth", "width config special tech freq delay area")
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
    
    fig, (ax1, ax2) = plt.subplots(2, 1, sharex=True)
    allFreqs = list(flatten(freqsL))
    if allFreqs != []:
        median = np.median(allFreqs)
    else:
        median = 0

    for ind in [0,1]:
        areas = areasL[ind]
        delays = delaysL[ind]
        freqs = freqsL[ind]
        freqs, delays, areas = noOutliers(median, freqs, delays, areas)

        c = 'blue' if ind else 'green'
        targs = [1000/f for f in freqs]

        ax1.scatter(targs, delays, color=c)
        ax2.scatter(targs, areas, color=c)
    
    freqs = list(flatten(freqsL))
    delays = list(flatten(delaysL))
    areas = list(flatten(areasL))

    legend_elements = [lines.Line2D([0], [0], color='green', ls='', marker='o', label='timing achieved'),
                       lines.Line2D([0], [0], color='blue', ls='', marker='o', label='slack violated')]

    ax1.legend(handles=legend_elements)
    ytop = ax2.get_ylim()[1]
    ax2.set_ylim(ymin=0, ymax=1.1*ytop)
    ax2.set_xlabel("Target Cycle Time (ns)")
    ax1.set_ylabel('Cycle Time Achieved (ns)')
    ax2.set_ylabel('Area (sq microns)')
    ax1.set_title(tech + ' ' + width + config)
    ax2.yaxis.set_major_formatter(ticker.StrMethodFormatter('{x:,.0f}'))
    addFO4axis(fig, ax1, tech)

    plt.savefig('./plots/wally/freqSweep_' + tech + '_' + width + config + '.png')
    # plt.show()



def areaDelay(tech, fig=None, ax=None, freq=None, width=None, config=None, norm=False):
    delays, areas, labels = ([] for i in range(3))

    for oneSynth in allSynths:
        if (width==None) or (width == oneSynth.width):
            if (tech == oneSynth.tech) & (freq == oneSynth.freq):
                if (config == None) & (oneSynth.special == 'FPUoff'): #fix
                    delays += [oneSynth.delay]
                    areas += [oneSynth.area]
                    labels += [oneSynth.width + oneSynth.config]
                elif (config != None) & (oneSynth.config == config):
                    delays += [oneSynth.delay]
                    areas += [oneSynth.area]
                    labels += [oneSynth.special]
    if width == None:
        width = ''
    if (fig == None) or (ax == None):
        fig, (ax) = plt.subplots(1, 1)
        ax.ticklabel_format(useOffset=False, style='plain')
        plt.subplots_adjust(left=0.18)

    if norm:
        delays = [d/techdict[tech][0] for d in delays]
        areas = [a/techdict[tech][1] for a in areas]
    
    plt.scatter(delays, areas)
    plt.xlabel('Cycle time (ns)')
    plt.ylabel('Area (sq microns)')
    ytop = ax.get_ylim()[1]
    plt.ylim(ymin=0, ymax=1.1*ytop)
    titleStr = tech + ' ' + width
    saveStr = tech + '_' + width
    if config: 
        titleStr += config
        saveStr = saveStr + config + '_versions_'
    if (config == None): 
        saveStr = saveStr + '_origConfigs_'
    saveStr += str(freq)
    titleStr = titleStr
    plt.title(titleStr)
    
    ax.yaxis.set_major_formatter(ticker.StrMethodFormatter('{x:,.0f}'))

    for i in range(len(labels)):
        plt.annotate(labels[i], (delays[i], areas[i]), textcoords="offset points", xytext=(0,10), ha='center')

    # addFO4axis(fig, ax1, tech)
    
    plt.savefig('./plots/wally/areaDelay_' + saveStr + '.png')

def normAreaDelay():
    fig2, (ax) = plt.subplots(1, 1)
    areaDelay('sky90', fig=fig2, ax=ax, freq=testFreq[0], norm=True)
    areaDelay('tsmc28', fig=fig2, ax=ax, freq=testFreq[1], norm=True)
    ax.set_title('Normalized Area & Cycle Time by Configuration')
    ax.set_xlabel('Cycle Time (FO4)')
    ax.set_ylabel('Area (add32)')
    fullLeg = [lines.Line2D([0], [0], color='royalblue', label='tsmc28')]
    fullLeg += [lines.Line2D([0], [0], color='orange', label='sky90')]
    ax.legend(handles = fullLeg, loc='upper left')
    plt.savefig('./plots/wally/normAreaDelay.png')
    
def addFO4axis(fig, ax, tech):
    fo4 = techdict[tech][0]

    ax3 = fig.add_axes((0.125,0.14,0.775,0.0))
    ax3.yaxis.set_visible(False) # hide the yaxis

    fo4Range = [x/fo4 for x in ax.get_xlim()]
    dif = fo4Range[1] - fo4Range[0]
    for n in [0.02, 0.05, 0.1, 0.25, 0.5, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000]:
        d = dif/n
        if d > 3 and d < 10:
            r = [int(x/n) for x in fo4Range]
            nsTicks = [round(x*n, 2) for x in range(r[0], r[1]+1)]
            break
    new_tick_locations = [fo4*float(x) for x in nsTicks]

    ax3.set_xticks(new_tick_locations)
    ax3.set_xticklabels(nsTicks)
    ax3.set_xlim(ax.get_xlim())
    ax3.set_xlabel("FO4 delays")
    plt.subplots_adjust(left=0.125, bottom=0.25, right=0.9, top=0.9)


if __name__ == '__main__':

    techdict = {'sky90': [43.2e-3, 1440.600027], 'tsmc28': [12.2e-3, 209.286002]}

    # synthsintocsv()
    synthsfromcsv('Summary.csv')
    freqPlot('tsmc28', 'rv32', 'e')
    freqPlot('sky90', 'rv32', 'e')
    areaDelay('tsmc28', freq=testFreq[1], width= 'rv64', config='gc')
    areaDelay('sky90', freq=testFreq[0], width='rv64', config='gc')
    areaDelay('tsmc28', freq=testFreq[1])
    areaDelay('sky90', freq=testFreq[0])

    # normAreaDelay()
