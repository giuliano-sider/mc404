#include "strtok.h"


char *strtok(char *str, const char * delims) {
	
	static char *internal_ptr = NULL;
	char *i, *j, *ret_value;
	int tokenfound, delimiterfound;
	if(str == NULL) {
		if(internal_ptr == NULL)
			return NULL; //already got to the end of the string
		str = internal_ptr; //look from this point onward
	}
	//find beginning of token:
	tokenfound = 0;
	for(i = str; *i != '\0' && !tokenfound; i++) {
		delimiterfound = 0;
		for(j = (char *) delims; *j != '\0' && !delimiterfound; j++) {
			if(*i == *j)
				delimiterfound = 1;
		}
		if(delimiterfound == 0) {
			tokenfound = 1;
			ret_value = i; //return beginning of token string
		}
	}
	/*if (tokenfound == 0) { //failed search
		internal_ptr = NULL;
		return NULL;
	}
	delimiterfound = 0;*/
	//find end of token:
	while(*i != '\0' && !delimiterfound) {
		for(j = (char *) delims; *j != '\0' && !delimiterfound; j++){
			if(*i == *j)
				delimiterfound = 1;
		}
		if(!delimiterfound)
			i++;
	}

	if(*i == '\0')
		internal_ptr = NULL; //dont want to look past the end of the string
	else {
		*i = '\0'; //end of token string
		internal_ptr = i+1; //look at this point next call
	}
	
	return tokenfound == 1 ? ret_value : NULL; //return beginning of token string, or NULL if no token was found

}

