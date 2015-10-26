/************ MC404C, Giuliano Sider, 20/10/2015 *************
*** Atividade Desafio (MINI CHALLENGE 2)
In this (mini) challenge, the RandInt function is making a comeback from previous 
exercises, but this time it faces a (mortal) hurdle: the link register is broken. Oh no.
We must reopen the black box and modify the implementation so that it can complete the call.

FUNCTION: RandInt: @ int RandInt(int i)
INPUT: r0 = > 32 bit integer, r1 = > 32 bit integer
OUTPUT: r0 = > uniformly random integer in the range [r0, r1]
SIDE EFFECTS: clobber r0-r3 (thanks to rand)
NOTE: recycled from qsort and linked list manager applications

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
	add r2, r1, 4 @ second integer here
	bl scanf
	ldr r2, =UserInput
	ldr r0, [r2]
	ldr r1, [r2, 4] @ second integer here
	ldr r3, =ReturnFromRandInt @ use r3 as our ersatz link register
	add r3, 1 @ must set the THUMB bit
	push { r3 } @ someone must tell RandInt to pick up the return address from here
	b RandInt @ must not forget to save r11 because rand clobbers
ReturnFromRandInt:
	mov r1, r0
	ldr r0, =Output
	bl printf
	b main @ press ctrl-c to quit

Prompt: .asciz "enter 2 integers, low and high\n"
Input: .asciz " %i %i"
Output: .asciz "here is a uniformly distributed integer plucked from the range [low, high]\n%i\n"

.align
RandInt: @ int RandInt(int low_bound, int high_bound) 
range .req r1 @ return a (uniformly) distributed integer in the range [low_bound, high_bound]
q .req r2
low_bound .req r5
high_bound .req r6
push { r4-r6 } @ return address left on the stack until the repairman comes
	mov low_bound, r0 @ low_bound == r5, high_bound == r6 (both defined above at qsort)
	mov high_bound, r1
	bl rand @ 32 bit (pseudo) random integer at r0
	sub range, high_bound, low_bound
	add range, 1 @ high_bound - low_bound + 1 is the size of desired interval
	udiv q, r0, range @ q = floor ( rnd / range ). REFRESHER: UDIV {Rd}, Rm, Rn. Rd := Rm / Rn
	mls r0, q, range, r0 @ rnd - q*range = remainder. REFRESHER: MLS {Rd}, Rm, Rn, Ra. Rd := Ra - Rm*Rn
	add r0, low_bound @ now r0 has an integer plucked from a uniform [low_bound, high_bound] distribution
pop { r4-r6 }
pop { pc } @ link register still at the doctor's office; grab return address from stack

.data
UserInput: .word 0, 0
