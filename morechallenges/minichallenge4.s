/************ MC404C, Giuliano Sider, 20/10/2015 *************
*** Atividade Desafio (MINI CHALLENGE 4)
Here we present an alternative way of reversing the endianness of the bytes in a 32 bit
word, along with the proofs of correctness.

FUNCTION: xchendian_different @ int32 xchendian_different(int32 i) 
INPUT: r1 = > 32 bit integer
OUTPUT: r1 => 32 bit integer with endianness reversed
SIDE EFFECTS: reverses the bytes in a 32 bit word. clobbers r2.
NOTE: doesn't require XOR, but uses the constant 0x00ff00ff

*************************************************************/

.syntax unified
.text
.global main
.align
main:
ldr r0, =Prompt
	bl printf
	ldr r0, =Input
	ldr r1, =UserInput
	bl scanf
	ldr r1, =UserInput
	ldr r1, [r1]
	bl xchendian_different
	ldr r0, =Output
	bl printf
	b main @ press ctrl-c to quit

Prompt: .asciz "enter 32 bit integer in hex format\n"
Input: .asciz " %08x"
Output: .asciz "reversed endian integer: %08x\n"

.align
xchendian_different: @ int32 xchendian_different(int32 i) 
	ror r1, 8
	and r2, r1, 0x00ff00ff @ convenient constant which can be encoded into the instruction
							@ according to the Cortex M3 manual
	bic r1, 0x00ff00ff
	orr r1, r1, r2, ror 16							

mov pc, lr

.data
UserInput: .word 0

/* CORRECTNESS PROOFS:

The ARM way:

	
	
eor r2, r1, r1, ror 16



bic r2, 0x00ff0000



mov r1, r1, ror 8



eor r1, r1, r2, lsr 8



My way:



ror r1, 8



and r2, r1, 0x00ff00ff



bic r1, 0x00ff00ff



orr r1, r1, r2, ror 16

















*/
