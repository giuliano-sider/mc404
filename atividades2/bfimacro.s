/********** MC404C, Giuliano Sider, RA 146271, exercício 5 de laboratório, 16/10/2015
simple macro to illustrate the idea of bfi, bit field insert.
the macro bfi_memory takes an address, a register, and two constants as parameters.
it emulates the ARM instruction bit field insert, except that it inserts the bit field
in the memory address passed to it as the first argument (addr is presumed a label)
***********/


.syntax unified
.text
.global main
.align

.macro bfi_memory addr, reg, sbit, nbits @ sbit and nbits are compile time constants
scratch1 .req r1 @ we use these three scratch registers
scratch2 .req r2
scratch3 .req r3

	ldr scratch3, =\addr @ Error: cannot represent T32_OFFSET_IMM relocation in this object file format
	ldr scratch1, [scratch3] @ is there a way to avoid this indirection ???
	mov scratch2, -1
	lsl scratch2, \nbits @ prepare our insertion mask
	.if (\sbit == 0)
		and scratch1, scratch1, scratch2 @ ror takes an integer in interval [1, 31]
	.else 
		and scratch1, scratch1, scratch2, ror (32-\sbit) 
	.endif @ clear the bit field where we will make an insertion
	bic scratch2, \reg, scratch2 @ select bit field to insert
	orr scratch1, scratch1, scratch2, lsl \sbit @ make the insertion
	str scratch1, [scratch3]

.endm

main:
push { r4-r7, lr }
.equ width, 8
scratch1 .req r1 @ we use these two scratch registers
scratch2 .req r2
	ldr r6, =PrintFormat @ standard SUSY format for writing hex values to display
	ldr r5, =TestWord @ address of integer where we will inser the bit field
	ldr r7, [r5] @ the original value is kept here
	
	ldr r4, =TestWordConstantInReg @ value where the bit field will be extracted from
	ldr r4, [r4] @ honestly this extra indirection shouldnt be necessary, but GNU assembler WILL NOT process the pseudo instruction that I want it to, and the assembler itself is not well documented 
	mov r0, r6 @ first print the test word, without any bfi
	mov r1, r7
	bl printf

	.irp lsb 0, 4, 8, 12, 16, 20, 24
		bfi_memory TestWord, r4, \lsb, width
		mov r0, r6
		ldr r1, [r5]
		bl printf
		str r7, [r5] @ restore our old test word
	.endr

pop { r4-r7, pc }

.align
TestWordConstantInReg: .word 0x9abcdf33 @ extract width bits from this for testing
PrintFormat: .asciz "%08x\n"
.data
.align
TestWord: .word 0xaabbccdd @ use this word in memory to test our bfi macro

