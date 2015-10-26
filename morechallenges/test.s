.syntax unified
.text
.global main
.align

main:
push { lr }
	/*mov r0, 1
	ldr r1, =TestString
	mov r2, TestStringEnd - TestString
	bl write*/
	movs r0, 1
	ldr r1, =FileModeString
	bl fdopen
	ldr r1, =TestString
	bl fprintf
pop { pc }
TestString: .asciz "laka com doolly woooo\n"
.align
TestStringEnd: 
FileModeString: .asciz "a"
