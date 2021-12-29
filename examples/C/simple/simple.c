// simple.C
// David_Harris@hmc.edu 24 December 2021
// Simple illustration of compiling C code

long sum(long N) {
   long result, i;
   result = 0;
   for (i=1; i<=N; i++) result = result + i;
   return result;
}

int main(void) {
    return sum(4);
}