#include <stdio.h>
#include <stdlib.h>

int main(){

  const int amount = 1000;
  unsigned char *cp = (unsigned char *) malloc(sizeof(unsigned char) * amount);

  free(cp);

  return 0;

}
