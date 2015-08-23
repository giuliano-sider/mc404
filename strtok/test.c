#include "strtok.h"
#include <stdio.h>

int main(/*int argc, char **argv*/) {

	char test[] = "this is a test string that will be mercilessly, totally, and utterly\n"
	              "tokenized. totally, man";
	char delimiters[] = " \n\t.,-";
	char *ptr = strtok(test, delimiters);

	while(ptr != NULL) {
		printf("%s-", ptr);
		ptr = strtok(NULL, delimiters);
	}
	putchar('\n');


	return 0;
}