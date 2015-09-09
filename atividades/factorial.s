/******* factorial.s *********
Programa simples em assembly para arm-none-eabi-gcc que calcula o fatorial de um número de
32 bits.
Giuliano Sider, RA 146271, 08/09/2015
Disciplina MC 404 C
****************************/

.syntax unified

/*
int *factorial(int n)
r0: (non negative) number whose factorial is to be computed
Output: r0 (pointer to a buffer of words encoding a large unsigned integer in little endian format)
it is our responsibility to free the buffer once we are done using it.
r1 (size of this buffer in words)
Clobbers r0-r3, r12, as per the ARM calling convention.

void PrintIntArray(int *a, int n) :
r0: pointer to array. r1: size of array in words
Prints array to stdout
Clobbers r0-r3 (ARM calling convention)

void PrintBigNum(int *array, int n): r0: buffer. r1: number of words. r0-r3: clobber (ARM PCS)
*/
.data
.align
input_integer: .word 0

.text
.align
PromptFormat: .asciz "%i"
OutFormat: .asciz "The factorial of %i is:\n"
.align
ptr_input_integer: .word input_integer

.global main
main:
	push { r4-r7, lr }

	ldr r0, =PromptFormat
	ldr r4, =input_integer
	mov r1, r4 
	bl scanf
	ldr r4, [r4] @ integer we read from stdin
	mov r0, r4
	bl Factorial
	mov r5, r0 @ store pointer to buffer with answer
	mov r6, r1 @ store size of this buffer in words
	ldr r0, =OutFormat
	mov r1, r4
	bl printf
	mov r0, r5
	mov r1, r6
	bl PrintBigNum

	mov r0, r5
	bl free @ our responsibility to deallocate the buffer
	pop { r4-r7, pc }

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
	mov r6, 1 @ A.length (r6) is initialized to 1
	str r6, [array] @ we set array[0] = 1 to be the initial value ( 0! == 1! == 1)
	mov i, 2 @ index of the outer loop (numbers to be multiplied into the buffer)
factorialouterloop:
	cmp i, n @ if i<=n
	bgt exitfactorialouterloop 
	mov carry, 0
	mov carrymul, 0 @ haven't performed any mults yet
	mov j, 0 @ index of the inner loop (multiplication of i by large number held in buffer: start at digit 0 (little endian) )
	factorialinnerloop:
		cmp j, length @ if j <= length - 1
		beq exitfactorialinnerloop
		ldr r1, [array, j, lsl 2]
		umull low, high, i, r1 @ (lo, hi) = i*array[j]
		add carrymul, carry @ note: this operation itself will never set carry. 'carry' var is the carry from the addition in the previous iteration, stored here to allow us to use cmp throughout
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
	cmp carrymul, 0
	ITT eq
	streq carrymul, [array, length, lsl 2] @ array[length] = carry_from_prev_mul + carry_from_prev_add
	addeq length, 1 @ we just added a word to the end of our buffer
	add i, 1
	b factorialouterloop
exitfactorialouterloop:
	mov r1, r6 @ use r6 (length) perhaps
	mov r2, r4 @ size of buffer in words (not necessary)

	push { r0-r2 }
		ldr r0, =checkmsg
		bl printf
	pop { r0-r2 }

	pop { r4-r7, pc }
bad_alloc:
	ldr r0, =bad_alloc_msg
	mov r1, pc
	mov r2, lr
	mov r3, sp
	bl printf
	mov r0, 1
	bl exit @ exit(1)
bad_alloc_msg: .asciz "Error: could not obtain memory from the heap\npc = %i, lr = %i, sp = %i\n"

checkmsg: .asciz "length = %i, n = %i\n"
.align

PrintBigNum: @r0: buffer. r1: number of words
	push { r4-r6, lr }
	mov r4, r0 @ buffer containing big num in little endian format
	sub r5, r1, 1 @ offset into that buffer
	ldr r6, =bignumformatstr
printbignumloop:
	mov r0, r6
	ldr r1, [r4, r5, lsl 2]
	bl printf
	subs r5, 1
	bge printbignumloop
	mov r0, '\n'
	bl putchar
	pop { r4-r6, pc }
bignumformatstr: .asciz "%08X"
.align

PrintIntArray:
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
