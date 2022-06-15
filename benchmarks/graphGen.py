#!/usr/bin/env python
import subprocess
import sys
import json
import plotly.graph_objects as go

coremarkData = {}
embenchData = {}
debug = True

def loadCoremark():
    """loads the coremark data dictionary"""
    coremarkPath = "riscv-coremark/work/coremark.sim.log"
    
    keywordlist = ["CoreMark 1.0", "CoreMark Size", "MTIME", "MINSTRET", "Branches Miss Predictions", "BTB Misses"]
    for keyword in keywordlist:
        bashInst = "cat " + coremarkPath + " | grep \"" + keyword +  "\" | cut -d \':\' -f 2 | cut -d \" \" -f 2 | tail -1"
        result = subprocess.run(bashInst, stdout=subprocess.PIPE, shell=True)
        if (debug): print(result)
        coremarkData[keyword] = int(result.stdout)
    if (debug): print(coremarkData)
    return coremarkData

def loadEmbench():
    """loads the embench data dictionary"""
    embenchPath = "embench/wallySpeed.json"
    f = open(embenchPath)
    embenchData = json.load(f)
    if (debug): print(embenchData)
    return embenchData

def graphEmbench(embenchData):
    ydata = list(embenchData["speed results"]["detailed speed results"].keys()) + ["speed geometric mean","speed geometric sd","speed geometric range"]
    xdata = list(embenchData["speed results"]["detailed speed results"].values()) + [embenchData["speed results"]["speed geometric mean"],embenchData["speed results"]["speed geometric sd"],embenchData["speed results"]["speed geometric range"]]
    fig = go.Figure(go.Bar(
            y=ydata,
            x=xdata,
            orientation='h'))

    fig.show()


def main():
    coremarkData = loadCoremark()
    embenchData = loadEmbench()
    graphEmbench(embenchData)

if __name__ == '__main__':
    sys.exit(main())

# x = 
# y = 

# df = px.data.tips()
# fig = px.bar(df, x="total_bill", y="day", orientation='h')
# fig.show()
# import plotly.express as px


# result = sp.run(['ls', '-l'], stdout=sp.PIPE)
# result.stdout

# fig = go.Figure( go.Bar(
#                 x=[],
#                 y=[],
#                 color="species",
#                 facet_col="species", 
#                 title="Using update_traces() With Plotly Express Figures"),
#                 orientation='h')

# fig.show()

#
# "ls -Art ../addins/embench-iot/logs/*speed* | tail -n 1 " # gets most recent embench speed log
# "ls -Art ../addins/embench-iot/logs/*size* | tail -n 1 " # gets most recent embench speed log

## get coremark score

# cat coremarkPath | grep "CoreMark 1.0" | cut -d ':' -f 2 | cut -d " " -f 2
# cat coremarkPath | grep "MTIME" | cut -d ':' -f 2 | cut -d " " -f 2 | tail -1
# cat coremarkPath | grep "MINSTRET" | cut -d ':' -f 2 | cut -d " " -f 2 | tail -1