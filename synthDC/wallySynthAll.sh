# Run all Wally synthesis experiments from chapter 8
./wallySynth.py --freqsweep 330 --tech sky130 
./wallySynth.py --freqsweep 870 --tech sky90 
./wallySynth.py --freqsweep 2800 --tech tsmc28psyn --usesram
./wallySynth.py --configsweep --tech sky130 --targetfreq 330
./wallySynth.py --configsweep --tech sky90 --targetfreq 870
./wallySynth.py --configsweep --tech tsmc28psyn --targetfreq 2800 --usesram
./wallySynth.py --featuresweep --tech sky130 --targetfreq 330
./wallySynth.py --featuresweep --tech sky90 --targetfreq 870
./wallySynth.py --featuresweep --tech tsmc28psyn --targetfreq 2800 --usesram
# Extract summary data (run this by hand after all experiments finish)
#./extractSummary.py --sky130freq 330 --sky90freq 870 --tsmcfreq 2800

