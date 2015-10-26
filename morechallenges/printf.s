.syntax unified
.text
.global main
main:
	ldr r0, =WelcomeMsg
	bl printf
UserPromptLoop:
	ldr r0, =UserPromptMsg
	bl printf
	ldr r0, =PromptString
	ldr r1, =FormatString
	ldr r2, =ArgumentString @ read 2 strings from the user
	bl scanf
	cmp r0, 2 @ check if input was read (both format specifiers having been filled)
	bne InputError
	ldr r0, puts @ glibc function used for writing string to stdout 
	ldr r1, =FormatString
	ldr r2, =ArgumentString
	bl printf_baremetal
	b UserPromptLoop

WelcomeMsg: .asciz "Welcome to the printf bare metal test module. The world's finest bare metal ARM assembly printf. ^C to quit\n"
UserPromptMsg: .asciz "USAGE: <FormatString> \\n <ArgumentString> \\n > "
PromptString: " %1023[^\n] %1023[^\n]" @ should be enough for testing purposes

.align
printf_baremetal: 
@ int printf_baremetal( int (*outputfunc)(const char*) , const char *formatstr, const char *argstr)
@ outputfunc used for testing is puts (wrapper not necessary in asm: no typing)
push { r4-r7, lr }





pop { r4-r7, pc }


.data
.align
.equ bufsize_format, 1024 @ should be enough for testing purposes
.equ bufsize_argument, 1024

FormatString: 
.rept bufsize_format
	.byte 0
.endr

ArgumentString:
.rept bufsize_argument
	.byte 0
.endr

