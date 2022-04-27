#!/usr/bin/bash
rm -r runs/*
make clean
make del
make freqs TECH=$1
scripts/extractSummary.py
make del
