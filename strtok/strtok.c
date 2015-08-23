#include "strtok.h"

char *strtok(char *str, const char *delimiters) {

  static char *internal_ptr;
  if(str!=NULL){
    tokenfound = 0;
    while(*str != '\0' && !tokenfound) { //scan the string until you reach the beginning of a token (or the end of the string)
      delimfound = 0;
      for(counter = delim; *counter != '\0'; counter++) { //check if the current character is a delimiter
	if(*str == *counter) {
	  delimfound = 1; 
	  break;
	}
      }
      if(delimfound==0) {
	tokenfound = 1;
	retvalue = str;
      }
      str++;
    }
    while(*str != '\0' && !endtokenfound) { //search for the end of the token



    }
    if(*str == '\0')
      internal_ptr = NULL;
    else {
      *str = '\0';

  }
  else {




  }



}


