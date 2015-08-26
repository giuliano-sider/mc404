/* simplescan.s 	MC404  Oct 2014  Celio G
	 *******************************************************
	*/
	.syntax unified
	.text
	.align
	.global	main
main:
	push {lr}
loop:
	ldr r0, =inmsg @load string to be printed
	bl printf
	ldr r1, =num1 @load address of place where scanf will place input integer
	ldr r0, =scan_format @load fromat string for scanf to read integer from standard output
	bl scanf	@ read integer into num1
	ldr r0, =num1 @num1 is the place in memory where our integer is
	ldr r1,[r0] @place the integer in r1 to be printed
	cmp r1,-1
	beq done
	ldr r0,=outmsg @format string to print out the integer
	bl printf
	b loop @infinite loop here @not anymore
done:
	ldr r0,=buhbye
	bl printf
	pop { pc}
scan_format:		.asciz "%d"
inmsg:	 .asciz "\nDigite um inteiro, saia comh ^c ou digite -1:  "
outmsg:	 .asciz "VocÃª digitou: %d"
buhbye:	 .asciz "Buh bye jinky\n"
	.data
	.align
num1:	 .word 0
	.end
