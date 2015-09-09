.syntax unified

.align
.text
.global main
main:
	push { r4, lr }
	sub sp, sp, 60
		ldr r0, =Format
		mov r1, 1
		mov r2, 2
		mov r3, 3
		mov r4, 4
		mov r5, 0
LoadRegs:
		str r4, [sp, r5]
		adds r5, 4
		adds r4, 1
		cmp r4, 19
		bne LoadRegs
		bl printf
	add sp, sp, 60
	pop { r4, pc }

Format: .asciz "%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i\n"

