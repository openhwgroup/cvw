#include "header.h"

#define LIMIT 8192
int main(int argc, char *argv[]){
  long int array [LIMIT];
  int index;
  for(index = 0; index < LIMIT; index++) {
    array[index] = index;
  }
  *argv = array;
  return array[LIMIT-1] + argc;
}
