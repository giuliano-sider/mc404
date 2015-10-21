#include <unistd.h>

int main(){
	const char lala_tongpo[] = "lutador tailandês\n";
	write(1, lala_tongpo, 18);
	return 0;
}