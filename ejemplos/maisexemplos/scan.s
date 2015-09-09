/* ex1.s 	MC404  Oct 2012  Celio G
 *******************************************************
*/
.syntax unified
.text
.align 2
.global	main	
main:
	push {lr}   
	ldr r0, =instr1  
	bl printf
	ldr r1, =num1
	ldr r0, =scan_format
	bl scanf	@ read number into num1
	ldr r0, =instr2  
	bl printf
	ldr r1, =num2
	ldr r0, =scan_format
	bl scanf
	ldr r1,=num1
	ldr r1,[r1]	@ retrieve first input
	ldr r2, =num2
	ldr r2,[r2]	@ retrieve 2nd input
	add r0, r1, r2 	@ now store sum in r0 m
	ldr r3, =sum
	str r0, [r3] 	@The source r0 precedes the destination
	sub r0, r1, r2	@ compute the diference
	ldr r3, =difference
	str r0, [r3]	@ save it
	mul r4, r1, r2  @ thumb requires overlap like mul r1, r1, r2
	ldr r3, =product
	str r4, [r3]	@ save product
	ldr r1, =sum
	ldr r1, [r1]	
	ldr r2,= difference
	ldr r2, [r2]
	ldr r3, =product
	ldr r3, [r3]
	ldr r0, =out_format
	bl printf	@ print sum, difference, product
	pop { pc}
scan_format:	.asciz "%d"
out_format: .asciz "Sum: %d    Difference: %d    Product: %d\n"
instr1: .asciz "Enter first integer: "
instr2: .asciz "Enter second integer: "
.data
.align	2
num1: .word 0
num2: .word 0
sum: .word 0
difference: .word 0
product: .word 0
 	.end

