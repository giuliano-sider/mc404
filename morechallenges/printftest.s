/*#include <stdio.h>

int main() {


	//unsigned short d, D, quit=0;
	//unsigned short q, r;

	int merda = 0xc3; // 0b11000011;
	int mijo = 20;

	printf ( "%#010x\n", printf );
	








	return 0;
}
*/

.syntax unified
.text
.global main
.align
main:
push { lr }
	ldr r0, =MyTestMsg
	ldr r1, =printf
	blx r1 @ it works because the value of 'printf' does seem to come with bit[0] set
pop { pc }


MyTestMsg: .asciz "printf is at %0#10x\n"



