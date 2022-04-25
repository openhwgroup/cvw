rm -r runs/*
make clean
make del
make freqs TECH=$1
python3 scripts/extractSummary.py
make del
