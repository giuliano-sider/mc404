#include <stdio.h>

int main(int argc, char **argv) {

  for(i = 0 ; i < argc ; i++)
    printf("arg %i: %s\n", i , argv[i] );
  return 0;

}
