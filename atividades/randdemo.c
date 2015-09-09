#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(){
	
	const int SIZEOFARRAY = 100;
	int i;
	int a[SIZEOFARRAY];

	srand(time(NULL));
	for(i = 0; i < SIZEOFARRAY; i++){
		a[i] = rand();
	}
	for(i = 0; i < SIZEOFARRAY; i++){
		printf("%i ", a[i]);
	}
	putchar('\n');

	/*printf("%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i",
		i++, i++, i++, i++, i++, i++, i++, i++, i++, i++, i++, i++, i++, i++, i++, i++, i++, i++);
	putchar('\n');*/

	return 0;
}