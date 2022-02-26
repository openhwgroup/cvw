#!/bin/sh
gcc -c -I. -I../../source/include -O2 -o $1.o $1.c
gcc -I -I. -I../../source/include -o $1 $1.o softfloat.a
