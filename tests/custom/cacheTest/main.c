#include "header.h"

int main(int argc, char *argv[]){
  long int array [1024];
  int index;
  for(index = 0; index < 1024; index++) {
    array[index] = index;
  }
  *argv = array;
  return array[1023] + argc;
}
