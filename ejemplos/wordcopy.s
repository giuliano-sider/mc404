/* wordcopy.s	- copies NUM words from vector src t vector dst
	        - first entry is size NUM of vector
		- after copyying exhibits copied vector
*/
.syntax unified
	.text
	.global main	
	.equ	NUM, 20		@ Number of words to be copied
main:
	push	{lr}
	ldr     r0,=src		@ R0 = pointer to source vector
	ldr     r1,=dst		@ R1 = pointer to destination vector
        bl      copywords
	ldr     r0,=dst		@ r0 = pointer to destination vector
        bl	showvec		@ exhibits it on video
        pop	{pc}
@_______________________________________________________________________
copywords:
		@ input parameters: r0= address of source vector
		@                   r1= address of destination vector
                @ changes: r2, r3, r0, r1
	ldr	r2,[r0], 4	@ Load a word with vector size, update r0
				@ (post-indexed: R0 := R0 + 4)
	str	r2,[r1], 4	@ Store the word and update R1
loop:
	ldr	r3,[r0], 4	@ Load a word from vector, update r0
	str	r3,[r1], 4	@ Store the word and update R1
	subs	r2, 1		@ Decrement the word counter
	bne	loop		@ and repeat loop if not finished
        mov	pc,lr
@_______________________________________________________________________
showvec:			@ exibit words in vector pointed by r0
		@ input: r0= address of vector
                @ changes: r1, r2, r0
        push {lr}
	ldr     r2, [r0],  4	@ get vector size, r0 will point to first element
        mov	r1, r2
        bl print		@ exibit size on video
l2:	ldr     r1, [r0],  4	@ get one word, r0 will point to next word
	bl print		@ show on video
	subs	r2,  1		@ check when done, note s suffix!
	bne l2
        pop {pc}
@_______________________________________________________________________
print:
	push {r0-r4, lr}
	ldr r0,=fmt
	bl printf
	pop {r0-r4, pc}
@_______________________________________________________________________
	.data			@ Read/write data follows
	.align			@ Make sure data is aligned on 32-bit boundaries
src:	.word	 NUM,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10
	.word	11, 12, 13, 14, 15, 16, 17, 18, 19, 20
dst:	.skip   (NUM+1)*4	@ reserves NUM+1 zero initialized words in data segment 
fmt:    .asciz "%4d\n"
	.end


