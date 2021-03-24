/*
 * Filename:
 *
 *   sieve.c
 *
 * Description:
 *
 *   The Sieve of Eratosthenes benchmark, from Byte Magazine
 *   early 1980s, when a PC would do well to run this in 10 
 *   seconds. This version really does count prime numbers
 *   but omits the numbers 1, 3 and all even numbers. The
 *   expected count is 1899.
 *
 */

#include <sys/time.h>
#include <stdio.h>

#define SIZE 8190

//#define SIZE 8388608
double time_diff(struct timeval x , struct timeval y);

int sieve () {

  unsigned char flags [SIZE + 1];
  int iter; 
  int count;

  for (iter = 1; iter <= 10; iter++) 
    {
      int i, prime, k;

      count = 0;

      for (i = 0; i <= SIZE; i++)
        flags [i] = 1;

      for (i = 0; i <= SIZE; i++) 
        {
          if (flags [i]) 
            {
              prime = i + i + 3;
              k = i + prime;

              while (k <= SIZE)
                {
                  flags [k] = 0;
                  k += prime;
                }

              count++;
            }
        }
    }

  return count;
}

int main () {

  int ans;

  //struct timeval before , after;
  //gettimeofday(&before , NULL);
    
  ans = sieve ();
  //gettimeofday(&after , NULL);
  if (ans != 1899)
    printf ("Sieve result wrong, ans = %d, expected 1899", ans);

  //printf("Total time elapsed : %.0lf us\n" , time_diff(before , after) );


  printf("Round 2\n");
  //gettimeofday(&before , NULL);
    
  ans = sieve ();
  //gettimeofday(&after , NULL);
  if (ans != 1899)
    printf ("Sieve result wrong, ans = %d, expected 1899", ans);

  //printf("Total time elapsed : %.0lf us\n" , time_diff(before , after) ); 
  
  return 0;

}


double time_diff(struct timeval x , struct timeval y)
{
    double x_ms , y_ms , diff;
     
    x_ms = (double)x.tv_sec*1000000 + (double)x.tv_usec;
    y_ms = (double)y.tv_sec*1000000 + (double)y.tv_usec;
     
    diff = (double)y_ms - (double)x_ms;
     
    return diff;
}
 
