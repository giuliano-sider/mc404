


/**************
in C:
int printf ( int (*outputfunc) (const char *), const char *formatstr, const char *argstr);

grammar of printf:
int printf( <outputfunc>, <format str>, <arg str> ) // follows ARM calling convention

outputfunc := function that takes a pointer to a null-byte-terminated array of characters and 
prints it to standard output. the function returns an integer (doesn't actually matter. the model is puts from libc)

format str := string containing regular characters and '%' followed by format specifications.
format specification := %[flags][width][lengthspec]specifier
flags := [ 0#+-]
width := <decimal number> | *
lengthspec := ll | l | h | hh | l<decimal number> | l* 
// The last two specify the length of the number (must be a number in memory) in bytes, in little endian format.
// last one is same as width argument (*): argument string contains an argument that specifies the length (in bytes)
specifier := c|s|d|i|x|X|n|u|o|%
arg str := argument specifier [, argument specifier ... ] \0 
// whitespace is ignored
argument := [ "[" ] <reg>|<const> [+- <reg>|<const> [lsl <reg>|<const>]] [ "]" ]
reg := r0|r1| ... r15 | sp | pc @ but not lr | r14
const := [0x|0]<digits>

BUG REPORTS ARE WELCOME !!
giuliano.sider@gmail.com
https://github.com/giuliano-sider/mc404

***************/

.syntax unified
.text


.include "macros.s" 


.global main
main:
push { lr }
	ldr r0, =WelcomeMsg
	bl printf
UserPromptLoop:
	ldr r0, =UserPromptMsg
	bl printf
	ldr r0, =PromptString @ USER PROMPT LOOP
	ldr r1, =FormatString @ USER PROMPT LOOP
	ldr r2, =ArgumentString @ read 2 strings from the user @ USER PROMPT LOOP
	bl scanf @ USER PROMPT LOOP
	cmp r0, 2 @ check if input was read (both format specifiers having been filled) @ USER PROMPT LOOP
	bne InputError @ USER PROMPT LOOP
	ldr r0, =puts @ glibc function used for writing string to stdout 
	ldr r1, =FormatString @ TESTING ldr r1, =FormatStringTest @
	ldr r2, =ArgumentString @ TESTING ldr r2, =ArgumentStringTest @
	bl printf_baremetal
	cmp r0, -1
	itt eq
	moveq r0, r1 @ load error message
	bleq puts
	@ b ExitUserPromptLoop
	b UserPromptLoop
InputError:
	mov r0, 0
	ldr r1, =ModeStr
	bl fdopen @ fdopen(0, "r")
	bl feof @ if ( feof ( fdopen ( 0, "r") ) != 0 ) goto ExitUserPromptLoop
	bne ExitUserPromptLoop @ EOF is set for stdin
	b UserPromptLoop
ModeStr: .asciz "r"
ExitUserPromptLoop:
	ldr r0, =GoodbyeMsg
	bl printf
pop { pc }

FormatStringTest: 
	.asciz "%#x"
ArgumentStringTest: 
	.asciz "[sp+4]"

WelcomeMsg: .asciz "Welcome to the printf bare metal test module. The world's finest bare metal ARM assembly printf. ^D to quit\n"
UserPromptMsg: .asciz "USAGE: <FormatString> \\n <ArgumentString> \\n \n"
PromptString: .asciz " %255[^\n] %255[^\n]" @ should be enough for testing purposes
GoodbyeMsg: .asciz "thanks for testing out the world's finest when it comes to printfs. buhbye\n"

.align
.include "printfcode.s" 

@ int printf_baremetal( int (*outputfunc)(const char*) , const char *formatstr, const char *argstr)
@ outputfunc used for testing is puts (wrapper not necessary in asm: no typing)

.include "data.s" 
