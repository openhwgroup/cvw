#!/usr/bin/bash
rm -r runs/*
make clean
make del
make copy 
make configs 
make allsynth
scripts/extractSummary.py
make del