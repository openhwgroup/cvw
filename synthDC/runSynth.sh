rm -r runs/*
make clean
make freqs TECH=sky130
python3 scripts/extractSummary.py