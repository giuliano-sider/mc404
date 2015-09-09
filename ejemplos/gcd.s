/***** GCD.s **********
Um teste de algoritmo ingênuo para calcular o máximo divisor comum
de dois números... em assembler. it is possible to program in a sane way... in assembler.
**********************/

.syntax unified
.align
.text
.global main
/* scratch registers: r0-r3. return register: r0. (actually... we print to stdout)*/
main:
.equ main_framesize, 8 @bytes to be held for local variables
.equ local_a, 0 @2 integers whose GCD we are computing
.equ local_b, 4
	push { r4, lr }
	sub sp, main_framesize @main function prologue

gcd_prompt:
	ldr r0, =Prompt
	bl printf
	ldr r0, =ScanString
	add r1, sp, local_a
	add r2, sp, local_b
	bl scanf
	ldr r1, [sp, local_a] @tell scanf to store both in our local stack
	ldr r2, [sp, local_b]
	cmp r1, 0
	ITT eq
	cmpeq r2, 0
	beq quit @quits if both are zero
gcd_loop:
	cmp r1, r2
	beq gcd_print @if r1==r2, we have the gcd; print it
	ITE lt
	sublt r2, r2, r1 @if r2 is bigger, find gcd of r1 and r2-r1
	subge r1, r1, r2 @if r1 is bigger, find gcd of r2 and r1-r2
	b gcd_loop
gcd_print:
	ldr r0, =ResponseString
	bl printf
	b gcd_prompt
quit:
	add sp, main_framesize @main function epilogue
	pop { r4, pc }

.align
Prompt: .asciz "Enter two positive integers whose GCD will be calculated. Enter '0 0' to quit\n"
ScanString: .asciz "%i %i"
ResponseString: .asciz "the answer is %i\n"
.word 0

.data

.bss

.end
