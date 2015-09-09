#include <stdio.h>
/*#include <stdlib.h>*/

int main(/*int argc, char **argv*/){
	
	int i = 0;
	/*printf("argc: %i\n", argc);
	for(i = 0; i < argc; i++)
		printf("%s\n", argv[i]);
	for(i = 0; i < 256; i++){
		printf("%3i - %c\t", i, (unsigned char) i);
	}*/

	printf("%i %i %i %i %i %i " 
		   "%i %i %i %i %i %i "
		   "%i %i %i %i %i %i\n",
		1, 2, 3, 4, 5, 6,
		7, 8, 9, 10, 11, 12,
		13, 14, 15, 16, 17, 18);
		/*i++, i++, i++, i++, i++, i++,
		i++, i++, i++, i++, i++, i++,
		i++, i++, i++, i++, i++, i++)*/;
	

	return 0;
}