#include <stdio.h>

int main(){
	char msg[] = "hi\n";
	fwrite(msg, 1, sizeof(msg), stdout);
	//fwrite(stdout, 1, sizeof(stdout), stdout);
	printf("%i\n%x\n", sizeof(stdout) , stdout);
	return 0;
}