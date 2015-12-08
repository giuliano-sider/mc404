.syntax unified


.text

.include "macros.s" @ actually just three of them are macros // MOVE THIS AND YOU WILL HAVE RANGE PROBLEMS

.global main
.align
main:
	// simple code for testing out a bunch of format specifiers
push { lr }

	ldr r0, =puts @ glibc function used for writing string to stdout 
	ldr r1, =FormatString @ TESTING 
	ldr r2, =ArgumentString @ TESTING 
	bl printf_baremetal
	cmp r0, -1
	itt eq
	moveq r0, r1 @ load error message
	bleq puts @ print error message returned by printf.

pop { pc }


FormatString:
	.asciz "%c %d %o %s %u %x %X\n"

ArgumentString:
	.asciz "sp, sp, sp, r1, sp, sp, sp"


.align

.include "printfcode.s" 
.include "data.s"

@ int printf_baremetal( int (*outputfunc)(const char*) , const char *formatstr, const char *argstr)
@ outputfunc used for testing is puts (wrapper not necessary in asm: no typing)


TestVariables:
	.word 256*348 + 789

