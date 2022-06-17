#include "disp.h"

double rnd_zero(double x, double bits) {
  if (x < 0) 
    return ceiling(x, bits);
  else
    return flr(x, bits);
}

double rne(double x, double precision) {
  double scale, x_round;
  scale = pow(2.0, precision);
  x_round = rint(x * scale) / scale;
  return x_round;
}

double flr(double x, double precision) {
  double scale, x_round;
  scale = pow(2.0, precision);
  x_round = floor(x * scale) / scale;
  return x_round;
}

double ceiling(double x, double precision) {
  double scale, x_round;
  scale = pow(2.0, precision);
  x_round = ceil(x * scale) / scale;
  return x_round;
}

void disp_bin(double x, int bits_to_left, int bits_to_right, FILE *out_file) {

  double diff;
  int i;
  if (fabs(x) <  pow(2.0, -bits_to_right)) {
    for (i = -bits_to_left + 1; i <= bits_to_right; i++) {
      fprintf(out_file,"0");
    }
    return;
  }
  if (x < 0.0) {
    // fprintf(out_file, "-");
    // x = - x;
    x = pow(2.0, ((double) bits_to_left)) + x;
  }
  for (i = -bits_to_left + 1; i <= bits_to_right; i++) {
    diff = pow(2.0, -i);
    if (x < diff) {
      fprintf(out_file, "0");
    }
    else {
      fprintf(out_file, "1");
      x -= diff;
    }
    if (i == 0) {
      fprintf(out_file, ".");
    }
  }
}

