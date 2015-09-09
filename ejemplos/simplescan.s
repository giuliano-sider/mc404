/* simplescan.s 	MC404  Oct 2014  Celio G
 *******************************************************
*/
.syntax unified
.text
.align 
.global	main	
main:
	push {lr}   
loop:	ldr r0, =inmsg  
	bl printf
	ldr r1, =num1
	ldr r0, =scan_format
	bl scanf	@ read number into num1
	ldr r0, =num1
	ldr r1,[r0]
        ldr r0,=outmsg
	bl printf
        b loop
	pop { pc}
scan_format:	.asciz "%d"
inmsg: .asciz "\nDigite um inteiro, saia comh ^c:  "
outmsg: .asciz "Você digitou: %d"
.data
.align	
num1: .word 0
.end

