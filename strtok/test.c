#include "strtok.h"
#include <stdio.h>


int main(int argc, char **argv) {

  char mystr[] = "this is a string like any other, really\n"
                 ", there is nothing special about it. But it\n"
                 "will be tokenized, to be sure, like no other";
  char delim[] = "\n ,.\t";
  char *ptr = strtok(mystr, delim);

  while(ptr!=NULL){
    printf("%s\t", ptr);
    ptr = strtok(NULL, delim);
  }
  putc('\n');

  return 0;

}









  return 0;

}
