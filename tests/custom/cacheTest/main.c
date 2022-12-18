#include "header.h"

int main(){
  long int array [1024];
  int index;
  for(index = 0; index < 1024; index++) {
    array[index] = index;
  }
  return 0;
}
