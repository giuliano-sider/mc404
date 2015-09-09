.syntax unified
.align 2
.text
msgyes: .asciz "%u is a power of 2\n"
msgno: .asciz "%u is not a power of 2\n"
.align 2
.global main
/******************************************************
unsigned int powerof2(int n){
	return ( n==(n&(-n)));
}
******************************************************/
pwof2:	@ check if  r0 is a power of 2
	@ returns Z status bit
	@ no registers changed
	push {r1}
	rsb r1,r0,#0    @ r1:= -r0
	and r1, r0,r1	@ r1:= n & (-n)
	cmp r1,r0	@ compare with n
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
