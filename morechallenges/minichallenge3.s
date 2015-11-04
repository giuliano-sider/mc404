/************ MC404C, Giuliano Sider, 20/10/2015 *************
*** Atividade Desafio (MINI CHALLENGE 3)
We implement a simple macro to emulate the bfi instruction, but with a difference:
the least significant bit and width of bitfield do not have to be compile time constants:
they can be arbitrary registers.

FUNCTION: macro bfi_regs Rd, Rsrc, Rsbit, Rnbits, Rscratch1, Rscratch2
SIDE EFFECTS: clobbers 2 scratch registers of your choice
NOTE: 

*************************************************************/

.macro bfi_regs Rd, Rsrc, Rsbit, Rnbits, Rscratch1, Rscratch2
	mov \Rscratch1, -1
	rsb \Rnbits, \Rnbits, 32 @ necessary since it's not a constant anymore
	lsr \Rscratch1, \Rscratch1, \Rnbits
	and \Rscratch2, \Rsrc, \Rscratch1
	lsl \Rscratch1, \Rscratch1, \Rsbit
	bic \Rd, \Rd, \Rscratch1 @ clear the bitfield where we make the insertion
	orr \Rd, \Rscratch1
.endm

.syntax unified
.text
.global main
.align
main:
	ldr r0, =Prompt
	bl printf
	ldr r0, =Input
	ldr r1, =UserInput
	add r2, r1, 4
	add r3, r2, 4
	add r4, r3, 4
	push { r4 } @ up to 4 args passed via register; the rest must be pushed onto the stack
	bl scanf
	ldr r5, =UserInput
	ldr r1, [r5]
	ldr r2, [r5, 4]
	ldr r3, [r5, 8]
	ldr r4, [r5, 12]
	bfi_regs r1, r2, r3, r4, r5, r6 @ bfi_regs Rd, Rsrc, Rsbit, Rnbits, Rscratch1, Rscratch2
	ldr r0, =Output
	bl printf
	b main @ press ctrl-c to quit

Prompt: .ascii "enter in hex format, the destination integer, the source integer,"
		.asciz "and in decimal, the least significant bit, and width of the destination field.\n"
Input: .asciz " %8x %8x %i %i"
Output: .asciz "destination integer: %08x\n"

.align
.data
UserInput: .word 0,0,0,0 @ dest, src, sbit, nbits

