#include <stdlib.h>
#include <math.h>
#include <stdio.h>

#ifndef DISP
#define DISP

double rnd_zero(double x, double bits);

double rne(double x, double precision);

double flr(double x, double precision);

double ceiling(double x, double precision);

void disp_bin(double x, int bits_to_left, int bits_to_right, FILE *out_file);

#endif 
