.syntax unified
.text
.align
.global main

main:
	push { lr }
	ldr r0, =main @ print instructions for curiosity
	mov r1, 1 << 12 @ print 4096 words
	bl PrintIntArray
	pop { pc }

PrintIntArray: @ for debugging/curiosity. 'x' command from gdb works just as well
	push { r4-r6, lr }
	mov r4, 0 @ index
	mov r5, r1 @ array size
	mov r6, r0 @ array pointer
printnext:
	cmp r4, r5
	bge exitprintarray @until we get to the end of the array, print
	ldr r0, =PrintFormat
	ldr r1, [r6, r4, lsl 2]
	bl printf
	add r4, 1
	b printnext
exitprintarray:
	ldr r0, =DonePrinting
	bl printf
	pop { r4-r6, pc }
.align
PrintFormat: .asciz "%08X\n"
DonePrinting: .asciz "\n\n"
