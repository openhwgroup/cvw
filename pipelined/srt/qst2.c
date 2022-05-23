/*
  Program:      qst2.c
  Description:  Prints out QST (assumes CPA is utilized to reduce memory)
  User:         James E. Stine

*/

#include <stdio.h>
#include <math.h>

#define DIVISOR_SIZE 3
#define CARRY_SIZE 7
#define SUM_SIZE 7
#define TOT_SIZE 7

void disp_binary(double, int, int);

struct bits {
  unsigned int divisor : DIVISOR_SIZE;
  int tot : TOT_SIZE;
} pla;

/* 

   Function:      disp_binary
   Description:   This function displays a Double-Precision number into
                  four 16 bit integers using the global union variable 
		  dp_number
   Argument List: double x            The value to be converted
                  int bits_to_left    Number of bits left of radix point
		  int bits_to_right   Number of bits right of radix point
   Return value:  none

*/
void disp_binary(double x, int bits_to_left, int bits_to_right) {
  int i; 
  double diff;

  if (fabs(x) <  pow(2.0, ((double) -bits_to_right)) ) {
    for (i = -bits_to_left + 1; i <= bits_to_right; i++) {
      printf("0");
    }
    if (i == bits_to_right+1) 
      printf(" ");
    
    return;
  }

  if (x < 0.0) 
    x = pow(2.0, ((double) bits_to_left)) + x;

  for (i = -bits_to_left + 1; i <= bits_to_right; i++) {
    diff = pow(2.0, ((double) -i) );
    if (x < diff) 
      printf("0");
    else {
      printf("1");
      x -= diff;
    }
    if (i == 0) 
      printf(" ");
    
  }

}


int main() {

  int m;
  int n;
  int o;
  pla.divisor = 0;
  pla.tot = 0;

  for (o=0; o < pow(2.0, DIVISOR_SIZE); o++) {
    for (m=0; m < pow(2.0, TOT_SIZE); m++) {
	disp_binary((double) pla.divisor, DIVISOR_SIZE, 0);
	disp_binary((double) pla.tot, TOT_SIZE, 0);

	/*
	  4 bits for Radix 4 (a=2)
	  1000 = +2
	  0100 = +1
	  0000 =  0
	  0010 = -1
	  0001 = -2
	  
	*/

	switch (pla.divisor) {

	case 0:
	  if ((pla.tot) >= 12)
	    printf(" 1000");
	  else if ((pla.tot) >= 4)
	    printf(" 0100");
	  else if ((pla.tot) >= -4)
	    printf(" 0000");
	  else if ((pla.tot) >= -13)
	    printf(" 0010");
	  else
	    printf(" 0001");
	  break;
	case 1:
	  if ((pla.tot) >= 14)
	    printf(" 1000");
	  else if ((pla.tot) >= 4)
	    printf(" 0100");
	  else if ((pla.tot) >= -6)
	    printf(" 0000");
	  else if ((pla.tot) >= -15)
	    printf(" 0010");
	  else
	    printf(" 0001");
	  break;
	case 2:
	  if ((pla.tot) >= 15)
	    printf(" 1000");
	  else if ((pla.tot) >= 4)
	    printf(" 0100");
	  else if ((pla.tot) >= -6)
	    printf(" 0000");
	  else if ((pla.tot) >= -16)
	    printf(" 0010");
	  else
	    printf(" 0001");
	  break;
	case 3:
	  if ((pla.tot) >= 16)
	    printf(" 1000");
	  else if ((pla.tot) >= 4)
	    printf(" 0100");
	  else if ((pla.tot) >= -6)
	    printf(" 0000");
	  else if ((pla.tot) >= -18)
	    printf(" 0010");
	  else
	    printf(" 0001");
	  break;
	case 4:
	  if ((pla.tot) >= 18)
	    printf(" 1000");
	  else if ((pla.tot) >= 6)
	    printf(" 0100");
	  else if ((pla.tot) >= -8)
	    printf(" 0000");
	  else if ((pla.tot) >= -20)
	    printf(" 0010");
	  else
	    printf(" 0001");
	  break;
	case 5:
	  if ((pla.tot) >= 20)
	    printf(" 1000");
	  else if ((pla.tot) >= 6)
	    printf(" 0100");
	  else if ((pla.tot) >= -8)
	    printf(" 0000");
	  else if ((pla.tot) >= -20)
	    printf(" 0010");
	  else
	    printf(" 0001");
	  break;
	case 6:
	  if ((pla.tot) >= 20)
	    printf(" 1000");
	  else if ((pla.tot) >= 8)
	    printf(" 0100");
	  else if ((pla.tot) >= -8)
	    printf(" 0000");
	  else if ((pla.tot) >= -22)
	    printf(" 0010");
	  else
	    printf(" 0001");
	  break;
	case 7:
	  if ((pla.tot) >= 24)
	    printf(" 1000");
	  else if ((pla.tot) >= 8)
	    printf(" 0100");
	  else if ((pla.tot) >= -8)
	    printf(" 0000");
	  else if ((pla.tot) >= -24)
	    printf(" 0010");
	  else
	    printf(" 0001");
	  break;
	default:
	  printf (" XXX");
	  
	}
	  
	printf("\n");
	(pla.tot)++;
    }
    (pla.divisor)++;
  }


}
