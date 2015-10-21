.syntax unified

.text
.global main
.align
.macro ReverseEndianess reg_to_swap, scratch_reg
	ror \reg_to_swap, 8
	ands \scratch_reg, \reg_to_swap, 0x00FF00FF
	bics \reg_to_swap, 0x00FF00FF
	orrs \reg_to_swap, \reg_to_swap, \scratch_reg, ror 16
.endm


main:
	push { lr }
	ldr r0, =InputFormat
	ldr r1, =Number
	bl scanf
	ldr r0, =InputFormat
	ldr r1, =Number
	ldr r1, [r1]
	ReverseEndianess r1, r2
	bl printf
	pop { pc }
.data
.align
Number: .word 0
InputFormat: .asciz "%8x"
