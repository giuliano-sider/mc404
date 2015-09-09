/* verifica se um inteiro e' potencia de dois usando:
   n & (n-1) : desliga apenas o bit 1 menos significativo de n, produz 0 se nenhumi existe
Explicacao:  seja n =abcd1000 entao n-1= abcd0111 e n & (n-1)= abcd0000

*/
.syntax unified
.align 2
.text
msgyes: .asciz "%u is a power of 2\n"
msgno: .asciz "%u is not a power of 2\n"
.align 2
.global main
/******************************************************
unsigned int powerof2(int n){
	return (n&(n-1));
}
******************************************************/
pwof2:	@ if  r0 is a power of 2 flag Z=1, 0 otherwise 
	@ returns Z status bit
	@ no registers changed
	push {r1}
	sub r1,r0,#1    @ r1:= r0-1
	ands r1, r0	@ r1:= n & (n-1)
	pop {r1}
	bx lr
/******************************************************/
main:
	push {lr}
	ldr r0,=65536
	bl pwof2
	bne no
	mov r1,r0
	ldr r0,=msgyes
	bl printf
	pop {pc}
no:	mov r1,r0
	ldr r0,=msgno
	bl printf
	pop {pc}
