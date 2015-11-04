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
	ror r1, 8 @ b0 and b2 in place
	and r2, r1, 0x00ff00ff @ convenient constant which can be encoded into the instruction
							@ according to the Cortex M3 manual
	bic r1, 0x00ff00ff @ clear b1 and b3 so the rotated by 16 version can be orr'ed in
	orr r1, r1, r2, ror 16						

mov pc, lr

.data
UserInput: .word 0

/* CORRECTNESS PROOFS:

The ARM way: 
	@ r1: b3, b2, b1, b0		r2: -- -- -- --		(initially)	
eor r2, r1, r1, ror 16
	@ r2: b1 XOR b3, b0 XOR b2, b1 XOR b3, b0 XOR b2		r1: unchanged
bic r2, 0x00ff0000
	@ r2: b1 XOR b3, 0, b1 XOR b3, b0 XOR b2		r1: unchanged
mov r1, r1, ror 8
	@ r2: unchanged		r1: b0, b3, b2, b1
eor r1, r1, r2, lsr 8
	r1: 0 XOR b0, b3 XOR b1 XOR b3, 0 XOR b2, b1 XOR b1 XOR b3
	r1: b0, b1, b2, b3
(XOR is associative, commutative and done bit by bit, where 0 XOR x == x and 1 XOR x == ~x)

My way:
	r1: b3, b2, b1, b0		r2: -- -- -- --		(initially)
ror r1, 8
	r1: b0, b3, b2, b1		r2: unchanged
and r2, r1, 0x00ff00ff
	r1: unchanged		r2: 0, b3, 0, b1
bic r1, 0x00ff00ff
	r1: b0, 0, b2, 0	r2: unchanged
orr r1, r1, r2, ror 16
	r1: b0, b1, b2, b3















*/
