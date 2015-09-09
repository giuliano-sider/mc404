/******* asciihex.s *********
Programa simples em assembly para arm-none-eabi-gcc que converte um número de 32 bits
para sua representação hexadecimal em ascii.
Giuliano Sider, RA 146271, 06/09/2015
Disciplina MC 404 C
****************************/

.syntax unified
.align
.text
.global main

/*
function void ConvHexToAscii(uint32 *output, uint32 input)
	This function converts a 32 bit number into an ascii representation
	of its hexadecimal digits. It takes a pointer to a vector where this
	output will be stored, at r0, and takes the number to be stored as the second argument, at r1.
	Clobbers r0-r3 as per the ARM calling convention.
*/
main:
	push { r4-r7, lr }
	ldr r4, =Lab02HexValues
	ldr r5, =AsciiValues
	ldr r6, =Formato
	mov r7, 0 @ offset for addressing the hex values for the assignment
.equ inputsize, 4 @ positive value representing number of integers to be converted
loopthroughinputvalues: 
	cmp r7, inputsize
	beq exitprogram
	mov r0, r5 @ load pointer to array where ascii will be stored
	ldr r1, [r4, r7, LSL 2] @ load integer to be converted to ascii
	add r7, 1
	bl ConvHexToAscii
	mov r0, r6
	mov r1, r5
	bl printf
	b loopthroughinputvalues @ if not zero we still have an integer to convert
exitprogram:
	pop { r4-r7, pc }

ConvHexToAscii:
	mov r3, 7 @offset into the output vector
conversionloop:
	and r2, r1, 15 @ extract four l.s. bits
	cmp r2, 10 @ is it a hex letter or digit
	ITE ge
	addge r2, r2, 55 @ A: 65, B 66, C 67, etc...
	addlt r2, r2, 48 @ 0: 48, 1: 49, etc...
	strb r2, [r0, r3]
	lsr r1, 4 @ inspect next nibble
	subs r3, 1
	bpl conversionloop @ continue if non negative offset

	mov pc, lr

.align
Lab02HexValues: .word 0x1, 0xffffffff, 0x89abcdef, 0x12345678
Formato: .asciz "%8s\n" @ 8 character string followed by newline and nul
.data
.align
AsciiValues: .word 0, 0, 0



