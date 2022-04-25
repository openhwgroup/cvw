rm -r runs/*
make clean
make del
make copy 
make configs 
make allsynth
python3 scripts/extractSummary.py
make del