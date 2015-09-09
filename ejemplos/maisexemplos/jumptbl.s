@ ***********************************************************************
@ *									*
@ *                   A Multi-way Branch (Jump Table)                   *
@ *									*
@ ***********************************************************************

@ Author:   John Zaitseff <J.Zaitseff@unsw.edu.au>
@ Date:     9th September, 2002
@ Version:  1.3

@ This program illustrates a multi-way branch (also called a jump table),
@ as well as using pointers to functions.  If you know BASIC, you might
@ remember the ON ... GOTO statement@ this is the ARM assembly language
@ equivalent.  The actual example is somewhat contrived (think about
@ operating system calls dispatch code for a better example)@ the real
@ meat is in the technique.
.syntax unified
.align
add_msg: .asciz	"Addition executed!"
sub_msg: .asciz	"Subtracion executed!"
mul_msg: .asciz "Multiplication executed!"
.align
	.text
	.global	main

@ Function call identifiers

	.equ	num_func, 3	@ Number of functions available
	.equ	f_add, 0	@   0 = addition
	.equ	f_sub, 1	@   1 = subtraction
	.equ	f_mul, 2	@   2 = multiplication

main:
	push	{lr}
	mov	r0,#f_sub	@ R0 = function number (an index number)
	mov	r1,#218		@ R1 = first parameter
	mov	r2,#34		@ R2 = second parameter
	bl	dispatch	@ Call the function identified by R0


dispatch:			@ Multi-way branch function
	cmp	r0,#num_func	@ On entry, R0 = function number
	it hs			@**** required by gnu gcc **** Prof Celio
	movhs	pc,lr		@ Simply return if R0 >= number of functions
	adr	r3,func_table	@ Get the address of the function table
	ldr	pc,[r3,r0,lsl #2] @ Jump to the routine (PC = R3 + R0*4)

func_table:			@ The actual table of function addresses
	.word	do_add		@   for entry 0 (f_add)
	.word	do_sub		@   for entry 1 (f_sub)
	.word	do_mul		@   for entry 2 (f_mul)

@ The table "func_table" contains a series of addresses (ie, pointers) to
@ functions.  Each address occupies four bytes (hence the R0*4 above).
@ The "dispatch" function simply uses the function number (in R0) as an
@ index into this table, retrieves the corresponding address, then jumps
@ to that address: all this in four statements!

do_add:				@ Function 0: f_add
	add	r0,r1,r2	@ R0 := R1 + R2
	ldr 	r0, =add_msg
	bl	puts
	pop	{pc}

do_sub:				@ Function 1: f_sub
	sub	r0,r1,r2	@ R0 := R1 - R2
	ldr 	r0, =sub_msg
	bl	puts
	pop	{pc}

do_mul:				@ Function 2: f_mul
	mul	r0,r1,r2	@ R0 := R1 * R2
	ldr 	r0, =mul_msg
	bl	puts
	pop	{pc}

@ By the way, the "dispatch" routine can be rewritten to take only THREE
@ instructions instead of four.  Are you up to the challenge?  Hint: page
@ A9-9 of the ARM Architecture Reference Manual (page 431 of the PDF
@ document) might give you a clue...  In real life, however, do remember
@ that "premature optimisation is the root of all evil" (Donald Knuth).

	.end
