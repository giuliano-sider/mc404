#include "strtok.h"
#include <stdio.h>



int main(int argc, char **argv) {

  char mystr[] = "this is a string like any other, really\n"
    ", there is nothing special about it. But it\n"
    "will be tokenized, to be sure, like no other";

  char delimiters[] = " \n\t.,-";
  char *ptr = strtok(test, delimiters);

  while(ptr != NULL) {
    printf("%s-", ptr);
    ptr = strtok(NULL, delimiters);
  }
  putchar('\n');


  return 0;

}

