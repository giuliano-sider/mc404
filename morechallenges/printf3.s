

.macro StrLenMacro Rstring, Rlength, Rscratch 
	@ pointer to string (input), length (output), scratch register
	sub \Rlength, \Rstring, 1 @ so that we count the empty string as length 0 (by pre-incrementing)
	StrLenMacroLoop\@:
		ldrb \Rscratch, [\Rlength, 1]! @ this pre-increment, coupled with the post loop
	@ calculation, allows us to keep only 3 instructions in the loop: optimize where it matters
		cbz \Rscratch, DoneStrLenMacro\@
		b StrLenMacroLoop\@
	DoneStrLenMacro\@:
	sub \Rlength, \Rlength, \Rstring @ length = strend - strbeginning
.endm





.syntax unified
.text
.global main
main:
	push { lr }
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
	ldr r0, =puts @ glibc function used for writing string to stdout 
	ldr r1, =FormatString
	ldr r2, =ArgumentString
	bl printf_baremetal
	cmp r0, -1
	itt eq
	ldreq r0, [sp] @ load error message
	bleq puts
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

WelcomeMsg: .asciz "Welcome to the printf bare metal test module. The world's finest bare metal ARM assembly printf. ^D to quit\n"
UserPromptMsg: .asciz "USAGE: <FormatString> \\n <ArgumentString> \\n > "
PromptString: " %1023[^\n] %1023[^\n]" @ should be enough for testing purposes
GoodbyeMsg: .asciz "thanks for testing out the world's finest when it comes to printfs. buhbye\n"

.align
printf_baremetal: 

/**************
in C:
int printf ( int (*outputfunc) (const char *), const char *formatstr, const char *argstr);
	// outputfunc used for testing is puts

grammar of printf:
int printf( <outputfunc>, <format str>, <arg str> ) // follows ARM calling convention

outputfunc := function that takes a pointer to a nul-terminated array of characters and 
prints it to standard output. the function returns an integer (model is puts from libc)

format str := string containing regular characters and '%' followed by format specifications.
format specification := %[flags][width][lengthspec]specifier
arg str := string containing comma separated list of arguments. whitespace is ignored.
argument := [ '[' ] <reg>|<const> [+- <reg>|<const> [lsl <reg>|<const>] ] [ ']' ]
reg := r0|r1| ... r15 @ but not lr==r14
const := [0x|0]<digits>
***************/








.equ false, 0
.equ true, 1

.equ BUFFERSIZE, 1024 
	@ actual size of buffer that holds chars before they go out to outputfunc
.equ MAXNUMBYTESIZE, BUFFERSIZE
	@ maximum number of bytes a number (in memory) can have and still be print-formatted by
	@ our printf (given in the "lengthspec" field of the format specifier)
.equ OUTPUTSTRINGSIZE, 4*MAXNUMBYTESIZE @ big enough to hold ceil(MAXNUMBERSIZE*8/3) octal digits
	@ this buffer holds the formatted print number's ascii codes before it is printed


push { r0-r12, lr } @ we keep track of sp. lr is pc. original lr is not available, clobbered during branch and link.





LoopThroughFormatString:
	ldr r0, [regvar_formatstr, regvar_i] 
	//cbz r0, FinishedReadingFormatString @ while formatstr[i] != 0 // nul terminator of format string
	tbb [pc, regvar_state] @ switch (state) // be very careful with the order
BranchByState:
.byte (ReadFormatString-BranchByState)/2
.byte (ReadFlags-BranchByState)/2
.byte (ReadWidth-BranchByState)/2
.byte (ReadLengthSpec-BranchByState)/2
.byte (ReadFormatSpecifier-BranchByState)/2
.byte (ReadFormatArg-BranchByState)/2

	ReadFormatString:
		// compile according to the LAW (the discipline of assembly...)




pop { r0-r12, pc }


@  !! ERROR CONDITIONS !! 

IllegalFormatSpecifier:
	ldr r0, =IllegalFormatSpecifierMsg
	b FatalErrorUnwind
IllegalFormatSpecifierMsg: 
	.asciz "Error: format string ended in the middle of a format specifier\n"

FatalErrorUnwind: @ unwind stack from main routine (other routines must unwind their stack) @@@@
	add sp, stackframesize @ undo printf's stack frame
	pop { r1 } @ can't clobber r0 because that is where the fatal error msg is
	pop { r1-r12, lr } @ restore all the other registers
	str r0, [sp] @ pointer to error message at sp
	mov r0, -1 @ return -1 for error
mov pc, lr @ returns to printf's caller: printf unwound by fatal ("compilation" type) error

FlagsNotInUseWithSpecC:
	ldr r0, =FlagsNotInUseWithSpecCMsg
	b FatalErrorUnwind
FlagsNotInUseWithSpecCMsg:
	.asciz "Error: the '+', ' ', '0', '#' flags not in use with c and s specifiers\n"

FlagAlreadySet:
	ldr r0, =FlagAlreadySetMsg
	b FatalErrorUnwind
FlagAlreadySetMsg: .asciz "Error: repeated flags in format specifier\n"

FormatStringPrematurelyEnded:
	ldr r0, =FormatStringPrematurelyEndedMsg
	b FatalErrorUnwind
FormatStringPrematurelyEndedMsg: 
	.asciz "Error: format string ended in the middle of a format specifier\n"





.data
OutputString: // keeps ascii characters while processing before printout
.rept OUTPUTSTRINGSIZE 
	.byte 0
.endr

ArgValue: // keeps values of argument fetched from the argument string, (in ObtainValueFromNextArg)
// and value calculated if using registers values as arguments (that is, not a buffer/number in memory)
.rept 16 @ enough to store the three arguments from the argument specifier
	.byte 0
.endr

Buffer: // buffer that stores the string to be passed to outputfunc
@ space time tradeoff: make the buffer big and outputfunc will be called only once as a result
.rept BUFFERSIZE+1  @ important to have the \0 terminator for the 'full buffer flushes'
	.byte 0
.endr