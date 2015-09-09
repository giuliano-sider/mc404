#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(){

  const int amt = 1000000000;
  int *a = (int *) malloc(sizeof(int)*amt);
  free(a);

  int i=0, j=1, k=2, l=3, m=4, n=5, o=6;
  printf("%i %i %i %i %i %i %i\n", i, j, k, l, m, n, o);

  return 0;

}
