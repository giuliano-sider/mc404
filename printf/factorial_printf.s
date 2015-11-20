/********* factorial.s *********
Programa simples em assembly para arm-none-eabi-gcc que calcula o fatorial de um número de
32 bits.
Giuliano Sider, RA 146271, 08/09/2015
Disciplina MC 404 C
******************************** MODIFIED TO TEST PRINTF's BIG NUM CAPABILITY
FUNCTION int *factorial(int n)
INPUT: r0 (non negative) number whose factorial is to be computed.
OUTPUT: r0 (pointer to a buffer of 32 bit words encoding a large unsigned integer in little endian format)
r1: length of the big number in words (the other remaining words in high memory are leading zeroes),
r2: actual length of buffer (in bytes) allocated by the function, including those leading zeroes in high memory
SIDE EFFECTS: Clobbers r0-r3, r12, as per the ARM calling convention.
NOTE: It is the caller's responsibility to free the buffer once done using it. 

FUNCTION void PrintIntArray(int *a, int n)
INPUT: r0 (pointer to array), r1 (size of array in words)
SIDE EFFECTS: Prints array to stdout. Clobbers r0-r3, r12 (ARM calling convention)

FUNCTION void PrintBigNum(int *array, int n)
INPUT: r0 (pointer to buffer), r1 (number of words in buffer).
SIDE EFFECTS: prints a big number stored in a buffer (in little endian form). Clobbers: r0-r3, r12.
*******************************/
.syntax unified
.data
.align
input_integer: .word 0

.text
.align
PromptFormat: .asciz "%i"
OutFormat: .asciz "The factorial of %i is %i words long, stored in a buffer %i bytes in size.\n"
.align

.global main
main:
push { r4-r7, lr }
	ldr r0, =PromptFormat
	ldr r4, =input_integer
	mov r1, r4 @ n
	bl scanf
	ldr r4, [r4] @ integer we read from stdin
	mov r0, r4
	bl Factorial
	mov r5, r0 @ store pointer to buffer with answer
	mov r6, r1 @ store size of this number in words
	mov r7, r2 @ store size of this buffer in bytes ('free' doesn't need it, but we can keep it)
	ldr r0, =OutFormat
	mov r1, r4 @ n
	mov r2, r6 @ length of num (in words)
	mov r3, r7 @ buffer size (in bytes)
	bl printf
	@ mov r0, r5 @ buffer
	@ mov r1, r6 @ length of num (in words)
	@ bl PrintBigNum
	ldr r0, =puts @ printing function 
	ldr r1, =NumFormatString
	ldr r2, =NumArgString
	bl printf_baremetal @ bare metal is the law
	cmp r0, -1 
@ returns number of printedchars, or -1 in the event of error, in which case r1 contains a pointer to error msg.
	itt eq
	moveq r0, r1
	bleq puts
	mov r0, r5 @ our responsibility to deallocate the buffer
	bl free
pop { r4-r7, pc }

NumFormatString: .asciz "%l*u\n" @ length (in bytes) specified in argument preceding the number to be formatted.
.align
NumArgString: .asciz "r6 lsl 2, [r5]" @ length in bytes of the number, and number (rest of buffer may have garbage)
.align

Factorial:
n .req r4
array .req r0
length .req r6
i .req r5
carry .req r2
carrymul .req r3
j .req r7
low .req r1
high .req r12 
	push { r4-r7, lr }
	cmp r0, 0
	IT eq
	moveq r0, 1 @ handles special case, n=0. 0! == 1!
	mov r4, r0 @ r4 : number (n) whose factorial will be calculated
	mov r0, r4, lsl 2 @ allocate 4*n bytes from the heap to store the result
	bl malloc @r0 will contain pointer to buffer (array) where we will compute the result
	cmp r0, 0
	beq bad_alloc @ malloc returns zero (NULL) when memory couldn't be allocated
	mov length, 1 @ A.length (r6) is initialized to 1
	str length, [array] @ we set array[0] = 1 to be the initial value ( 0! == 1! == 1)
	mov i, 2 @ index of the outer loop (numbers to be multiplied into the buffer)
factorialouterloop:
	cmp i, n @ if i<=n
	bgt exitfactorialouterloop 
	mov carry, 0
	mov carrymul, 0 @ haven't performed any mults yet
	mov j, 0 @ index of the inner loop (multiplication of i by large number held in buffer:
		@ start at digit 0 (little endian) )
	factorialinnerloop:
		cmp j, length @ if j <= length - 1
		beq exitfactorialinnerloop
		ldr r1, [array, j, lsl 2]
		umull low, high, i, r1 @ (lo, hi) = i*array[j]
		add carrymul, carry @ note: this operation itself will never set carry; 'carry' var is the carry from the
			@ addition in the previous iteration, stored here to allow us to use cmp throughout
		adds low, carrymul
		ITE cs @ update carry based on the previous addition
		movcs carry, 1
		movcc carry, 0
		str low, [array, j, lsl 2] @ array[j] = low + carry_from_prev_op
		mov carrymul, high
		add j, 1
		b factorialinnerloop
exitfactorialinnerloop:
	add carrymul, carry @ this operation never carries: (2^32 - 1)(2^32 - 1) = 2^64 - 2*2^32 + 1
	cmp carrymul, 0 @ if( carrymul != 0 || carry flag set ) if either of them is nonzero,
		@ our carry must be appended to the buffer
	ITT gt
	strgt carrymul, [array, length, lsl 2] @ array[length] = carry_from_prev_mul + carry_from_prev_add
	addgt length, 1 @ we just added a word to the end of our buffer
	add i, 1
	b factorialouterloop
exitfactorialouterloop:
	mov r1, length @ return length of number in words
	mov r2, n, lsl 2 @ return size of buffer in bytes (4*n)
	pop { r4-r7, pc } @ return to main
bad_alloc: @ optional section if you don't want to check for memory allocation error
	ldr r0, =bad_alloc_msg
	mov r1, pc
	mov r2, lr
	mov r3, sp
	bl printf
	mov r0, 1
	bl exit @ exit(1)
bad_alloc_msg: .asciz "Error: could not obtain memory from the heap\npc = %i, lr = %i, sp = %i\n"
.align

PrintBigNum: @ r0: buffer. r1: number of words
	push { r4-r6, lr }
	mov r4, r0 @ buffer containing big num in little endian format
	add r5, r4, r1, lsl 2 @ pointer to iterate over the elements of the buffer.
	ldr r0, =firstbignumformatstr
	ldr r1, [r5, -4]! @ remember, we are iterating over the elements from most to least significant
	bl printf @ we print the first one (most significant one) separately to avoid leading zeroes
	ldr r6, =bignumformatstr
printbignumloop:
	cmp r4, r5
	beq printbignumloopexit
	mov r0, r6
	ldr r1, [r5, -4]! @ from most significant (highest address) to least (lowest address)
	bl printf
	b printbignumloop
printbignumloopexit:
	mov r0, '\n'
	bl putchar
	pop { r4-r6, pc }
bignumformatstr: .asciz "%08X"
firstbignumformatstr: .asciz "%8X" 
.align

PrintIntArray: @ for debugging/curiosity. 'x' command from gdb works just as well
	push { r4-r6, lr }
	mov r4, 0 @ index
	mov r5, r1 @ array size
	mov r6, r0 @ array pointer
printnext:
	cmp r4, r5
	bge exitprintarray @until we get to the end of the array, print
	ldr r0, =PrintFormat
	ldr r1, [r6, r4, lsl 2]
	bl printf
	add r4, 1
	b printnext
exitprintarray:
	ldr r0, =DonePrinting
	bl printf
	pop { r4-r6, pc }
.align
PrintFormat: .asciz "%08X\n"
DonePrinting: .asciz "\n\n"
.align

@ all the printf paraphernalia follows below:

.include "macros.s"
.include "printfcode.s"
.include "data.s"

/*
FactorialNumBuffer: @ we keep the number here
.rept 1024
	.byte 0
.endr 
*/
