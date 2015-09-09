.syntax unified
.align
.text
.global main	
@******************************************************************
        .equ    NULL, 0         @ 0 is used for end of C-type string
strcopy:                        @ Entry to "strcopy" function
                                @ r0 = address of source string
                                @ r1 = address of destination string
				@ destroys r2!
l1:
        ldrb    r2,[r0], 1      @ Load source byte into r2 and update r0
        strb    r2,[r1], 1      @ Store the byte and update r1
        cmp     r2, NULL        @ Check for NULL terminator
        bne     l1              @ Repeat loop if not
        mov     pc, lr	        @ return to caller
@*******************************************************************
main:
	push    {lr}
	ldr	r0,=srcstr
	bl	printf	        @ show source string
	ldr	r0, =dststr
	bl	printf	        @ show destination string
	ldr	r0,=srcstr      @ r0 = address of source string
	ldr	r1, =dststr     @ r1  = address of destination string
	bl	strcopy	        @ call the function "strcopy" 
	ldr	r0,=srcstr	
	bl	printf          @ show again source string
	ldr	r0, =dststr     
	bl	printf	        @ and destination string
	pop     {pc}
@*******************************************************************
.data			@ Read/write data follows
.align			@ Align to a 32-bit boundary
srcstr:	.asciz	"Hello World!\n"
dststr:	.asciz	"Minha terra tem palmeiras onde canta o sabiá\n"
@*******************************************************************
/* Exercicio: troque os rotulos das cadeias srcstr e dststr, recompile e execute
   novamente. Explique a razão da mensagem "Segmentation fault"!
*/

