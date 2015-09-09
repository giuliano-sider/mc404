@subr.s          exemplo de uso de subrotinas
.syntax unified
.align 2
.text
sum_msg:    .asciz "Sum 15 + 32= %d  "
sub_msg:    .asciz "Sub 47 - 5= %d\n"
debug_msg:  .asciz "R1= %d R2= %d R3= %d R4= %d\n"
.align 2
.global	main
main:
    	push {lr}
	mov	r0, 15		@ Set up parameters
	mov	r1, 32
	bl	f_add		@ Call the function "f_add"@ result is in R0
	mov r1,r0
	push {r0}		@ save sum to use later
    	ldr r0, =sum_msg
    	bl  printf
	pop {r0}		@ retrieve sum = 47 
	mov	r1, 5		@ Set up the second parameter
	bl	f_sub		@ Call the function "f_sub
	mov r1, r0
    	ldr r0, =sub_msg
    	bl  printf
exit: 	pop {pc}			@ Terminate the program

@********************************************************************
f_add:      @ Function "f_add" for addition
            @input parameters: r0 and r1
            @ output parameter: r0
            @ changes: r0 - on exit r0 is the sum.
	add	r0,r1	        @ Perform R0 := R0 + R1
	mov	pc,lr		@ and return to the caller
@************************************************************************
f_sub:				@ Function "f_sub" for subtraction
            @input parameters: r0 and r1
            @ output parameter: r0
            @ changes: r0 - on exit r0 is the subtraction
	sub	r0,r1	        @ Perform R0 := R0 - R1
	bx	lr		@ and return to the caller
@************************************************************************
	.end			@ from here on all lines are commentaries

