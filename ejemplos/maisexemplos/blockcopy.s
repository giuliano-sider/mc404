@ ***********************************************************************
@ *									*
@ *                   Copy an Array of Words En-masse                   *
@ *									*
@ ***********************************************************************
@ Author:   John Zaitseff <J.Zaitseff@unsw.edu.au>
@ Date:     9th September, 2002
@ Version:  1.3
@ This program is a more sophisticated version of "wordcopy.s".  Instead
@ of copying an array one word at a time, it uses the "ldmia" and "stmia"
@ instructions to copy eight words at a time.  Of special note is the
@ method of setting up an independent stack.
.syntax unified
	.text
	.global main
	.equ	num, 20		@ Number of words to be copied
main:
	push {lr}
	mov r0,sp 
	ldr	sp,=stack_top	@ Set up the stack pointer (R13) to some memory
	push {r0}
@ You would not normally set up your own stack: you would just use R13 as
@ it is on entry to your program.  Setting up your own stack (at the
@ beginning of your program) makes sense where the program needs a lot of
@ stack space (eg, some of its functions have large parameters, or are recursive).
	ldr     r0,=src		@ R0 = pointer to source block
	ldr     r1,=dst		@ R1 = pointer to destination block
	mov     r2,#num		@ R2 = number of words to copy
blockcopy:
	movs	r3,r2,lsr #3	@ R3 = number of eight-word multiples
	beq	copywords	@ Do we have less than eight words to move?
	push {r4-r11}           @stmfd	sp!,{r4-r11}	@ Save our working registers (R4-R11)
octcopy:
	ldmia	r0!,{r4-r11}	@ Load 8 words from the source@ update R0
	stmia	r1!,{r4-r11}	@ and store them at the destination@ update R1
	subs	r3,r3,#1	    @ Decrement the counter (num. of 8-words)
	bne	octcopy		        @ and repeat if necessary
	pop {r4-r11}		@ldmfd	sp!,{r4-r11}	@ Restore original register contents
copywords: 
	ands	r2,r2,#7	    @ Number of words left to copy
	beq	done
wordcopy:
	ldr	r3,[r0],#4	        @ Load a word from the source
	str	r3,[r1],#4	        @ and store it at the destination
	subs	r2,r2,#1	    @ Decrement the counter (num. of words)
	bne	wordcopy	        @ and repeat if necessary
done:
	sub r1,r1,#4
        ldr r1,[r1]		@ print last word copied
	pop {r0}		@ restore original sp
        mov sp,r0
	bl debug			        @ Finished copying!
exit:	pop {pc}			@swi	0x11

debug: push {lr}
	ldr r0,=dbg_msg
	bl printf
	pop {pc}

	.data			        @ Read/write data follows
	.align			        @ Make sure data is aligned on 32-bit  boundaries
dbg_msg:.asciz "debug message: last word copied= %u\n"
.align
src:	.word	 1,  2,  3,  4,  5,  6,  7,  8,  9, 10
	.word	11, 12, 13, 14, 15, 16, 17, 18, 19, 20
dst:	.skip	num * 4	    @ Reserve 80 bytes (num 32-bit words)
	.section .bss		    @ Uninitialised storage space follows
	.align
@ The ".section" assembler directive allows you to switch to any arbitrary
@ section in your program (in fact, ".text" is really ".section .text" and
@ ".data" is ".section .data").  Be warned, however, that it is the GNU
@ Linker's job of putting those sections in some sort of order... and it
@ can't do so with sections it does not know about.  In this case, the
@ ".bss" section is reserved by the linker for uninitialised storage
@ space: nothing is stored in the executable file apart from a note
@ saying, in effect, "reserve this many bytes of space for me".
@ Pages 23-27 of the GNU Assembler Manual have more information about
@ sections in a program.  See page 52 of that manual for a fuller
@ description of the ".section" assembler directive.

stack:		.skip	1024	@ Allow 1KB for the local stack
stack_top:		        @ The stack grows downwards in memory, so we need a label to its top
	.end

