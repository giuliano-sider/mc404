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
	@ldr r0, =UserInputString
	@ldr r1, =FormatString
	@ldr r2, =ArgumentString @ read 2 strings from the user
	@bl scanf
	@cmp r0, 2 @ check if input was read (both format specifiers having been filled)
	@bne InputError
	ldr r0, =puts @ glibc function used for writing Readstring to stdout 
	ldr r1, =FormatStringTest @ ldr r1, =FormatString
	ldr r2, =ArgumentStringTest @ ldr r2, =ArgumentString
	bl printf_baremetal
	cmp r0, -1
	itt eq
	ldreq r0, [sp] @ load error message
	bleq puts
	b ExitUserPromptLoop @ b UserPromptLoop
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
	.asciz "%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i"
ArgumentStringTest: 
	.asciz "r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, sp, pc"

WelcomeMsg: .asciz "Welcome to the printf bare metal test module. The world's finest bare metal ARM assembly printf. ^D to quit\n"
UserPromptMsg: .asciz "USAGE: <FormatString> \\n <ArgumentString> \\n\n"
UserInputString: .asciz " %1023[^\n] %1023[^\n]" @ should be enough for testing purposes
GoodbyeMsg: .asciz "thanks for testing out the world's finest when it comes to printfs. buhbye\n"
.align

@ helper macros

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

.macro Macro_MakeNegativeNumberPositive  Rnumberptr, Rnumbytes, Rnewnumberptr
@ registers cannot be r7-r8 !!!
	push { r7-r8 }
	mov r7, 0
	lsr r8, \Rnumbytes, 2
	//lsl r8, 2 @ load 4*floor(numbytes/4)
	str r7, [\Rnewnumberptr, r8, lsl 2] @ word store a zero at BufferForNumber[ 4*floor(numbytes/4) ]
		@ byte offset. make sure there is a zero at the last word (in case number is not word aligned )
	WhileThereAreBytesToComplCopy\@:
	cmp r7, \Rnumbytes @ while s < numbytes, do: newnumberptr[s] = ~numberptr[s]
	beq AddOne\@
		ldrb r8, [\Rnumberptr, r7]
		mvn r8, r8
		strb r8, [\Rnewnumberptr, r7]
		add r7, 1
		b WhileThereAreBytesToComplCopy\@
	mov r7, 0
	AddOne\@: @ do
		ldr r8, [\Rnewnumberptr, r7]
		adds r8, 1 @ if carry is set, we must continue to carry 1
		str r8, [\Rnewnumberptr, r7]
		add r7, 1 @ doesnt update carry flag
	bcs AddOne\@ @ while carry is set
	pop { r7-r8 }
	mov \Rnumberptr, \Rnewnumberptr
.endm

.macro Macro_CopyNumberToBuffer  Rnumberptr, Rnumbytes, Rnewnumberptr
@ registers cannot be r7-r8 !!!
	push { r7-r8 }
	mov r7, 0
	lsr r8, \Rnumbytes, 2
	//lsl r8, 2 @ load 4*floor(numbytes/4)
	str r7, [\Rnewnumberptr, r8, lsl 2] @ word store a zero at BufferForNumber[ 4*floor(numbytes/4) ]
		@ byte offset. make sure there is a zero at the last word (in case number is not word aligned )
WhileThereAreBytesToCopy\@:
	cmp r7, \Rnumbytes @ while s < numbytes, do: newnumberptr[s] = ~numberptr[s]
	beq FinishCopyToBuffer\@
		ldrb r8, [\Rnumberptr, r7]
		strb r8, [\Rnewnumberptr, r7]
		add r7, 1
		b WhileThereAreBytesToCopy\@
FinishCopyToBuffer\@:
	pop { r7-r8 }
	mov \Rnumberptr, \Rnewnumberptr
.endm

.macro Macro_IsNumberZero Rnumberptr, Rnumsize, Rresult
	@ r0->numptr, r1->size(words), r2->output (zero if number is zero, nonzero otherwise)
	@ cannot use r7
	push { r7 }
	cmp \Rnumsize, 1 @ is the number one word long
	ite ne
	movne \Rresult, 1 @ it's not zero: number is more than 1 word long
	ldreq \Rresult, [\Rnumberptr] @ zero iff the first word is zero
	pop { r7 }
.endm

.macro Macro_DivVectorByInt16 Rnumberptr, Rnumsize, Rdivisor, Rremainder @ remainder goes to output register
// divides the vector (in little endian format) of 'numwords' words, numberptr, by an up to 16 bit 'divisor'.
@ this changes the number into the quotient of the division. numsize is also adjusted. 
	@ dont use r7, r8, r9 !!
	push { r7-r9 }
	mov \Rremainder, 0
	lsl r7, \Rnumsize, 1 @ we will index by halfwords, as that is how the division is done.
DivideTheNumber\@:
	cbz r7, DoneDividing\@
	sub r7, 1 @ look at next less significant halfword 
	ldrh r8, [\Rnumberptr, r7, lsl 1]
	add r8, r8, \Rremainder, lsl 16 @ "double halfword" dividend, (at most) halfword divisor
	udiv r9, r8, \Rdivisor @ q = ( r*2^16 + numberptr[i] )/divisor
	mls \Rremainder, \Rdivisor, r9, r8 @ r = ( r*2^16 + numberptr[i] ) - q*divisor
	strh r9, [\Rnumberptr, r7, lsl 1]
	b DivideTheNumber\@
// we clobber the value with the quotient as a convenience for this application
DoneDividing\@:
	sub r7, \Rnumberptr, 1 @ last word of the number
AdjustNumSize\@:
	ldr r8, [\Rnumberptr, r7]
	cmp r8, 0
	bne AdjustedNumSize\@ @ while word is zero, decrement numsize.
	cmp r7, 0 @ if we reached the zeroth word, we cant decrement anymore
	beq AdjustedNumSize\@
	sub \Rnumsize, 1 @ otherwise we decrement
	sub r7, 1
	b AdjustNumSize\@
AdjustedNumSize\@:
	pop { r7-r9 }
/*	r = 0
	for i = (numwords/2 - 1) down to 0 // array "value" is indexed by halfword
		q = (r*2^16 + value[i])/divisor
		r = (r*2^16 + value[i]) - q*divisor
		value[i] = q // we clobber the value with the quotient as a convenience for this application
return r
*/
.endm

.macro Macro_PrintStringInReverse Rstring, Rlength @ do not use r3 !!
	push { r3 }

		add r3, \Rstring, \Rlength @ (one past) the end of the string
	PrintThisStringMrGorbachev\@:
		cmp r3, \Rstring @ while we havent gotten to the beginning, print
		beq FinishedPrintStringInReverse\@
			push { r0 } @ danger: Rstring or Rlength may be r0
			ldrb r0, [r3, -1]!
			bl PrintChar @ clobber fest nightmare
			pop { r0 }
			b PrintThisStringMrGorbachev\@

	FinishedPrintStringInReverse\@:
	pop { r3 }

.endm

.macro Macro_PrintSomeCharNTimes Rchar, Rhowmanytimes @ next time we will parameterize register clobbers as well
														@ dont use r2
	push { r2 }
		mov r2, \Rhowmanytimes
	PrintMoreChars\@:
		cbz r2, DoneWithPrintSomeChar\@
			push { r0 }
			mov r0, \Rchar
			bl PrintChar
			pop { r0 }
			sub r2, 1
			b PrintMoreChars\@
DoneWithPrintSomeChar\@:
	pop { r2 } 	

.endm

.macro Macro_PrintString Rstring @ dont use r2-r3

	push { r2-r3 } 

	mov r2, 0
	PrintStringInNormalOrder\@:
		ldrb r3, [\Rstring, r2]
		cbz r3, FinishedPrintString\@
			push { r0 } @ dont move this (yes, every register in this trash code is booby trapped)
			mov r0, r3 @ the problem here is that Rstring is effectively r0 (in this code)!!
			bl PrintChar
			pop { r0 }
			add r2, 1 @ next character
		b PrintStringInNormalOrder\@
	FinishedPrintString\@:
	pop { r2-r3 }
.endm

.macro Macro_ParseStringAsDecimalNumber Rstring, Rindex, Rnumber, Rscratch
	@ string, index (gets incremented up to first non-digit), variable to keep the number, scratch register 1
	mov \Rnumber, 0 @ initialize number = 0
ParseStringAsDecimalNumberLoop\@:
	ldrb \Rscratch, [\Rstring, \Rindex] @ scratch1 = string[index]
	cmp \Rscratch, '0' @ check if string[index] is actually a decimal number
	blt DoneParseStringAsDecimalNumber\@
	cmp \Rscratch, '9'
	bgt DoneParseStringAsDecimalNumber\@
	sub \Rscratch, '0' @ turn it from ascii to the actual number
	add \Rscratch, \Rscratch, \Rnumber, lsl 1
	add \Rnumber, \Rscratch, \Rnumber, lsl 3 @ number = number*10 + asciitoint(string[index])
	add \Rindex, 1
	b ParseStringAsDecimalNumberLoop\@
DoneParseStringAsDecimalNumber\@:
.endm

.macro Macro_ParseStringAsOctalNumber Rstring, Rindex, Rnumber, Rscratch
	@ string, index (gets incremented up to first non-digit), variable to keep the number
mov \Rnumber, 0 @ initialize number = 0
ParseStringAsOctalNumberLoop\@:
	ldrb \Rscratch, [\Rstring, \Rindex]
	cmp \Rscratch, '0'
	blt DoneParseStringAsOctalNumber\@
	cmp \Rscratch, '7'
	bgt DoneParseStringAsOctalNumber\@
	sub \Rscratch, '0' @ turn it from ascii to the actual number
	add \Rnumber, \Rscratch, \Rnumber, lsl 3 @ number = number*8 + asciitoint(string[index])
	add \Rindex, 1
	b ParseStringAsOctalNumberLoop\@
DoneParseStringAsOctalNumber\@:
.endm

.macro Macro_ParseStringAsHexNumber Rstring, Rindex, Rnumber, Rscratch
	@ string, index (gets incremented up to first non-digit), variable to keep the number
mov \Rnumber, 0 @ initialize number = 0
ParseStringAsHexNumberLoop\@:
	ldrb \Rscratch, [\Rstring, \Rindex]
	cmp \Rscratch, '0'
	blt DoneParseStringAsHexNumber\@
	cmp \Rscratch, 'f'
	bgt DoneParseStringAsHexNumber\@
	cmp \Rscratch, 'a'
	itt ge @ small cap hex letter
	subge \Rscratch, ('a' - 10)
	bge NowUpdateHexNumberSoFar
	cmp \Rscratch, '9'
	it le @ regular digit '0' to '9'
	suble \Rscratch, '0' @ turn it from ascii to the actual number
	ble NowUpdateHexNumberSoFar
	cmp \Rscratch, 'A'
	blt DoneParseStringAsHexNumber\@
	cmp \Rscratch, 'F'
	bgt DoneParseStringAsHexNumber\@
	sub \Rscratch, ('A' - 10) @ now we conclude that it is a a large caps hex letter 
NowUpdateHexNumberSoFar:
	add \Rnumber, \Rscratch, \Rnumber, lsl 4 @ number = number*16 + asciitoint(string[index])
	add \Rindex, 1
	b ParseStringAsHexNumberLoop\@
DoneParseStringAsHexNumber\@:
.endm

printf_baremetal: 
@ int printf_baremetal (
@	int (*outputfunc)(const char*), const char *formatstr, const char *argstr )
@ outputfunc used for testing is puts

/***************************************************************************
@ list of variables used
.equ outputfunc, 0 @ pointer to function that does printing
.equ printedchars, 4 @ number of characters actually printed so formatstr
.equ specifier, 8 @ code indicating which specifier has been selected
.equ width, 12 @ minimum number of characters to be printed in a field
.equ lengthspec, 16 @ bytes in number 
					@ (hh: 1 byte, h: 2 bytes, default: 4 bytes, l: 8 bytes, ll: 16 bytes)
.equ flags1, 20 @ some flags here
.equ flagzero, 20 @ whether '0' flag is set
.equ flagsspace, 21 @ whether ' ' flag is set
.equ flagpound, 22 @ whether '#' flag is set
.equ flagplus, 23 @ whether '+' flag is set

.equ flags2, 24 @ another grouping of flags for convenience
.equ flagsdash, 24 @ whether '-' flag is set
.equ exhaustedargs, 25 
	@ flag indicating whether we have gotten to the end of the argument string
.equ addressmode, 26 @ flag indicating whether we are obtaining an address as argument
.equ negative, 27 
	@ positive or negative register/constant offset in the argument specification

.equ buffer, 28 @ pointer to the buffer where chracters are stored before being printed
.equ i, 32 @ current reading index along format string
.equ j, 36 @ current reading index along argument string
.equ buffercount, 40 @ how many characters are in the buffer currently
.equ outputstring, 44 @ pointer to buffer where formatted characters are printed out before field width adjustment, etc
.equ outputstringlength, 48 @ number of characters stored so far in the outputstring
.equ formatstr 52 @ pointer to the format string
.equ argstr 56 @ pointer to the argument string

.equ state 64 @ what reading state are we in currently
.equ radix, 68 @ what radix of number are we reading
.equ args, 72 @ pointer to buffer where values fetched from argument string are kept, and that's used as a storage for formatting register (that is, non memory) values
.equ arg, 76 @ number of argument that we are fetching from a given argument string field
.equ argstate, 80 @ state of the argument reading machine
.equ printf_stackframesize, 84
***************************************************************************************/

@ define some variables to be cached on the stack (positions relative to printf's (base) stack pointer)
.equ j, 0
.equ argstr, 4
.equ buffercount, 8
.equ outputfunc, 12
.equ printedchars, 16
.equ printf_stackframesize, 20

.equ BUFFERSIZE, 1024 
	@ actual size of buffer that holds chars before they go out to outputfunc
.equ MAXNUMBYTESIZE, BUFFERSIZE
	@ maximum number of bytes a number (in memory) can have and still be print-formatted by
	@ our printf (given in the "lengthspec" field of the format specifier)
.equ OUTPUTSTRINGSIZE, 4*MAXNUMBYTESIZE @ big enough to hold ceil(MAXNUMBERSIZE*8/3) octal digits
	@ this buffer holds the formatted print number's ascii codes before it is printed

// a catalog of format string reading states:
.equ readformatstr, 0
.equ readflags, 1
.equ readwidth, 2
.equ readlengthspec, 3
.equ readformatspecifier, 4

@ we take a "farthest in future" caching approach, because there are many variables
@ "print" Register Profile. Note: r0-r3, r12 are always free registers (for scratch)
regvar_flags2 .req r4 @ -, exhaustedargs, addressmode, negative flags
regvar_buffer .req r5
regvar_i .req r6 @ most used
regvar_formatstr .req r7 @ most used
regvar_state .req r8 @ most used
regvar_buffercount .req r9
regvar_outputfunc .req r10
regvar_printedchars .req r11

@ "format specifier" Register Profile
//regvar_flags2 .req r4 @ -, exhaustedargs, addressmode, negative flags
regvar_flags1 .req r5 @ 0, space, #, +
//regvar_i .req r6
//regvar_formatstr .req r7
//regvar_state .req r8
regvar_lengthspec .req r9
regvar_width .req r10
freereg .req r11

push { r0-r12, lr } @ we keep track of sp. lr is user pc. user original lr is not available, clobbered during branch and link.
// initialize
	sub sp, printf_stackframesize @ make way for all those stack variables 
	str r2, [sp, argstr] // store argument string on the stack (not in "print" profile)
	mov r3, 0
	str r3, [sp, j] @ index to the argument string
	mov regvar_i, 0  // str r3, [sp, i] @ index to the format string
	mov regvar_outputfunc, r0 @ remember, we start in register profile "print"
	mov regvar_formatstr, r1
	ldr regvar_buffer, =Buffer @ buffer where printed character are kept until flushed
	mov regvar_buffercount, 0 @ number of characters currently loaded to output buffer
	mov regvar_printedchars, 0 @ number of characters actually sent to outputfunc so far
	mov regvar_state, readformatstr
		@ initial state is readformatstr == 0; begin reading format string

LoopThroughFormatString:
	ldrb r0, [regvar_formatstr, regvar_i] 
	//cbz r0, FinishedReadingFormatString @ while formatstr[i] != 0 // nul terminator of format string
	tbb [pc, regvar_state] @ switch (state) // be very careful with the order
BranchByState:
.byte (ReadFormatString-BranchByState)/2
.byte (ReadFlags-BranchByState)/2
.byte (ReadWidth-BranchByState)/2
.byte (ReadLengthSpec-BranchByState)/2
.byte (ReadFormatSpecifier-BranchByState)/2
.byte 0 @ alignment

	ReadFormatString:
		ldr r1, =ReadFormatStringBranchTable
		tbb [r1, r0] @ switch(formatstr[i])
	BeginReadingFormatSpecifier:
		mov regvar_state, readflags @ state = readflags @@@@ change register profile @@@@
		add regvar_i, 1 @ i++
		bl SwitchToFormatSpecifierProfile @@@@
		b LoopThroughFormatString
	PrintNormalCharacter:
		bl PrintChar @ else PrintChar(formatstr[i]) @ parameter in r1
		add regvar_i, 1 @ i++
		b LoopThroughFormatString
	FinishedPrintfTrampoline:
		b FinishedReadingFormatString @ we ran into a \0

	ReadFlags: @ '0', ' ', '#' , '+', '-'
		ldr r1, =FlagsBranchTable
		tbb [r1, r0] @ switch(formatstr[i]) 
			@ although it takes a bit of space at the data section, this cleans up the code
	HandleDashFlag: @ left justify field within field width
		ubfx r1, regvar_flags2, 0, 1 @ dash flag here
		cbnz r1, FlagAlreadySet @ error (strictly speaking, this would generate a compiler warning)
		add regvar_flags2, 1 @ flags.dash = 1
		add regvar_i, 1 @ i++ 
		b LoopThroughFormatString
	HandlePlusFlag: @ forces numerical result to present a sign
		ubfx r1, regvar_flags1, 24, 1 @ plus flag here
		cbnz r1, FlagAlreadySet @ error (strictly speaking, this would generate a compiler warning)
		add regvar_flags1, (1<<24) @ flags.plus = 1
		add regvar_i, 1 @ i++
		b LoopThroughFormatString
	HandleSpaceFlag: @ a blank space is placed instead of a (+) sign for a number
		ubfx r1, regvar_flags1, 8, 1 @ space flag here
		cbnz r1, FlagAlreadySet @ error (strictly speaking, this would generate a compiler warning)
		add regvar_flags1, (1<<8) @ flags.space = 1
		add regvar_i, 1 @ i++
		b LoopThroughFormatString
	HandlePoundFlag: @ with o, x, X the result is preceded by 0, 0x, 0X if it is not zero
		ubfx r1, regvar_flags1, 16, 1 @ pound flag here
		cbnz r1, FlagAlreadySet @ error (strictly speaking, this would generate a compiler warning)
		add regvar_flags1, (1<<16) @ flags.space = 1
		add regvar_i, 1 @ i++
		b LoopThroughFormatString
	HandleZeroFlag: @ left pads number with zeroes instead of space when width is specified
		ubfx r1, regvar_flags1, 0, 1 @ zero flag here
		cbnz r1, FlagAlreadySet @ error (strictly speaking, this would generate a compiler warning)
		add regvar_flags1, 1 @ flags.zero = 1
		add regvar_i, 1 @ i++
		b LoopThroughFormatString
	NoFlags:
		mov regvar_state, readwidth @ state = readwidth (no more flags to read)
		cmp regvar_flags1, 0x00010001 @ if + and space flags are both set 
		beq PlusAndSpaceFlagsBothSet @ error
		b LoopThroughFormatString

	PlusAndSpaceFlagsBothSet:
		ldr r0, =PlusAndSpaceFlagsBothSetMsg
		b FatalErrorUnwind

	FlagAlreadySet:
		ldr r0, =FlagAlreadySetMsg
		b FatalErrorUnwind

	ReadWidth: @ width previously initialized to 0
		ldr r1, =WidthBranchTable
		tbb [r1, r0] @ switch(formatstr[i])
	HandleWidthArg: @ '*' in format string for the width field
		mov r0, 4
		bl ObtainValueFromNextArg 
			@ fetch the next (4 byte) arg in argstr; it will be the width
		ldr regvar_width, [r0] @ ObtainValueFromNextArg returns a pointer to the value
		add regvar_i, 1 @ i++ // consume the * character
		mov regvar_state, readlengthspec @ go on to the length field now
		b LoopThroughFormatString
	HandleWidthSpec:
		sub r0, 30 @ transforms the ascii code into the number ('0'===30)
		add r0, r0, regvar_width, lsl 2
		add regvar_width, r0, regvar_width, lsl 3 @ width = 10*width + r0
		add regvar_i, 1 @ i++
		b LoopThroughFormatString
	NoWidth:
		mov regvar_state, readlengthspec 
			@ finished obtaining width (zero width: no minimum field width)
		b LoopThroughFormatString

	ReadLengthSpec: @ lengthspec previously initialized to 4
		ldr r1, =LengthSpecBranchTable
		tbb [r1, r0] @ switch(formatstr[i])
	LengthSpecH:
		lsr regvar_lengthspec, 1 @ h: 2 bytes. hh: 1 byte. hhh: invalid
		cmp regvar_lengthspec, 0
		beq InvalidLengthModifier
		add regvar_i, 1 @ i++
		b LoopThroughFormatString
	LengthSpecL:
		lsl regvar_lengthspec, 1 @ l: 8 bytes. ll: 16 bytes. lll: invalid
		cmp regvar_lengthspec, 32
		beq InvalidLengthModifier
		add regvar_i, 1 @ i++
		b LoopThroughFormatString
	LengthSpecNumber:
		cmp regvar_lengthspec, 8
		bne InvalidLengthModifier @@@@
			@ valid format: lXYZ, where XYZ is some decimal number, for XYZ bytes
		Macro_ParseStringAsDecimalNumber regvar_formatstr, regvar_i, regvar_lengthspec, r1
			@ string, index (gets incremented up to first non-digit), variable to keep the number, scratch register
		b LoopThroughFormatString
	NoLengthSpec:
		cmp regvar_lengthspec, 0
		ble InvalidLengthModifier @ negative amount of bytes in number
		cmp regvar_lengthspec, MAXNUMBYTESIZE @ too many bytes in number for our processing
		bgt LengthModifierTooLong @@@@
		mov regvar_state, readformatspecifier
		b LoopThroughFormatString


	ReadFormatSpecifier:
		ldr r1, =ReadFormatSpecifierBranchTable
		tbb [r1, r0] @ switch(formatstr[i])
	ReadPercent: @ just print a '%'. if there's extraneous information in the specifier,
		add regvar_i, 1 @ i++ to consume the specifier character
		cmp regvar_width, 0
		bne UselessInfoWithPercentSpecifier @ send error
		cmp regvar_lengthspec, 4 
		bne UselessInfoWithPercentSpecifier
		cmp regvar_flags1, 0
		bne UselessInfoWithPercentSpecifier
		ubfx r3, regvar_flags2, 0, 1 @ dash flags stored here
		cbnz r3, UselessInfoWithPercentSpecifier
		bl SwitchToPrintProfile @@@@
		mov r0, '%'
		bl PrintChar @ prints a single percent
		b LoopThroughFormatString

	IllegalFormatSpecifier:
		ldr r0, =IllegalFormatSpecifierMsg
		b FatalErrorUnwind

	UselessInfoWithPercentSpecifier:
		ldr r0, =UselessInfoWithPercentSpecifierMsg
		b FatalErrorUnwind

	FormatStringPrematurelyEnded:
		ldr r0, =FormatStringPrematurelyEndedMsg
		b FatalErrorUnwind

	
	ReadString:
		add regvar_i, 1 @ i++ to consume the specifier character
		cmp regvar_flags1, 0
		bne FlagsNotInUseWithSpecCandS @ if any of the '0', ' ', '+', '#' flags are set
		cmp regvar_lengthspec, 4
		bne InvalidLengthModifier
		mov r0, 4 @ pointer to string is 4 bytes
		bl ObtainValueFromNextArg @ obtain pointer to the string from arg str
		ldr r0, [r0] @ the pointer to the string is stored at the buffer pointed to by r0
		StrLenMacro r0, r2, r3 @ stores length of string r0 in r2 (r3 is scratch)
		mov r12, ' ' @ padding character
		sub r3, regvar_width, r2 @ r3 = width - length
		ubfx r1, regvar_flags2, 0, 1 @ dash flag is here
		//mov freereg, r0 @ keep string here
		cbnz r1, DashFlagIsSetForString @ if dash flag is unset, field is right justified within width
			bl SwitchToPrintProfile @@@@ we have to print the field now
				@ default (no dash flag) is to right justify the field within the (minimum) width
			Macro_PrintSomeCharNTimes r12, r3 @ r3 is width-len (blanks to print)
			Macro_PrintString r0 @ string is at r0
			b LoopThroughFormatString
		DashFlagIsSetForString:  @ field is left justified within width
			bl SwitchToPrintProfile
			Macro_PrintString r0 @ string is at r0
			Macro_PrintSomeCharNTimes r12, r3 @ r3 is width-len (blanks to print)
			b LoopThroughFormatString


	ReadCharacter: @ very similar to string; handling them together, in assembly language, though, would be a pain
		add regvar_i, 1 @ i++ to consume the specifier character
		cbnz regvar_flags1, FlagsNotInUseWithSpecCandS @ if any of the '0', ' ', '+', '#' flags are set
		cmp regvar_lengthspec, 4 @ the default lengthspec (no length modifiers)
		bne InvalidLengthModifier
		mov r0, 1 @ character is one byte
		bl ObtainValueFromNextArg @ obtain pointer to the string from arg str
		ldrb r0, [r0] @ load the character to be printed
		sub freereg, regvar_width, 1 @ freereg = width - 1
		mov r12, ' ' @ pad with spaces
		ubfx r1, regvar_flags2, 0, 1 @ dash flag is here
		cbnz r1, DashFlagIsSetForChar @ if dash flag is unset, field is right justified within width
			bl SwitchToPrintProfile @@@@ we have to print the field now
				@ default (no dash flag) is to right justify the field within the (minimum) width
			Macro_PrintSomeCharNTimes r12, freereg
				@ r12 is the ' ', freereg is width-1 (blanks to print)
			bl PrintChar @ print the character at r0
			b LoopThroughFormatString
		DashFlagIsSetForChar:  @ field is left justified within width
			bl SwitchToPrintProfile
			bl PrintChar
			Macro_PrintSomeCharNTimes r12, freereg 
				@ r12 is the ' ', freereg is width-1 (blanks to print)
			b LoopThroughFormatString

	FlagsNotInUseWithSpecCandS:
		ldr r0, =FlagsNotInUseWithSpecCandSMsg
		b FatalErrorUnwind
	


	ReadSpecifierN:
		add regvar_i, 1 @ i++ to consume the specifier character
		cbnz regvar_flags1, InvalidModifiersWithSpecifierN @ none of the flags should be set, etc.
		ubfx r3, regvar_flags2, 0, 1 @ dash flag stored here
		cbnz r3, InvalidModifiersWithSpecifierN @@@@
		cmp regvar_width, 0
		bne InvalidModifiersWithSpecifierN
		cmp regvar_lengthspec, 4
		bne InvalidModifiersWithSpecifierN
		mov r0, 4 @ we are obtaining a pointer to where we will place the number of characters outputted so far
		bl ObtainValueFromNextArg
		ldr r0, [r0] @ load the pointer here
		bl SwitchToPrintProfile @ we're going back to reading the format string
		add r1, regvar_printedchars, regvar_buffercount @ number of characters sent to the printer so far
		str r1, [r0]
		b LoopThroughFormatString

	InvalidModifiersWithSpecifierN:
		ldr r0, =InvalidModifiersWithSpecifierNMsg
		b FatalErrorUnwind
	

	ReadPointer: @ %0#10x is our standard for printing pointers
		mov regvar_flags1, 0x00010001 @ this is a valid Cortex-M3 constant of the form 00XY00XY
			@ sets the # and 0 flags
		mov regvar_width, 10
	@ fall through to ReadUnsignedHex
	ReadUnsignedHex:
		add regvar_i, 1
		mov r0, regvar_lengthspec
		bl ObtainValueFromNextArg @ returns pointer to memory block where the number is kept
		mov r3, 16 @ radix is kept here
		ldr regvar_state, =DigitsLookup 
		b SurelyAPositiveNumber
	ReadUnsignedHexCaps: @ differs from the previous only by the 'lookup table' used containing capitalized hex digits
		add regvar_i, 1
		mov r0, regvar_lengthspec
		bl ObtainValueFromNextArg @ returns pointer to memory block where the number is kept
		mov r3, 16 @ radix is kept here
		ldr regvar_state, =DigitsLookupCaps
		b SurelyAPositiveNumber
	ReadOctalNumber:
		add regvar_i, 1
		mov r0, regvar_lengthspec
		bl ObtainValueFromNextArg @ returns pointer to memory block where the number is kept
		ldr regvar_state, =DigitsLookup
		mov r3, 8 @ radix is kept here
		b SurelyAPositiveNumber
	ReadUnsignedDecimal:
		ldr regvar_state, =DigitsLookup 
	@ look up table of digits(not really necessary for decimal, helpful for hex)state can be safely clobbered now
		add regvar_i, 1
		mov r0, regvar_lengthspec
		bl ObtainValueFromNextArg @ returns pointer to memory block where the number is kept
		mov r3, 10 @ radix (used as the divisor to extract each successive digit of the number stored in the buffer)
		b SurelyAPositiveNumber

	ReadSignedDecimal:
		mov r3, 10 @ radix (used as the divisor to extract each successive digit of the number stored in the buffer)
		ldr regvar_state, =DigitsLookup 
	@ look up table of digits(not really necessary for decimal, helpful for hex)state can be safely clobbered now
		add regvar_i, 1
		mov r0, regvar_lengthspec
		bl ObtainValueFromNextArg @ returns pointer to memory block where the number is kept
		sub r2, regvar_lengthspec, 1
		ldrb r1, [r0, r2] @ load last byte of number to check for sign
		ubfx r12, r1, 7, 1 @ check the sign bit
		bfi regvar_flags2, r12, 24, 1 @ sets the negative flag equal to the sign bit of our number
		ldr r2, =Number @ buffer where the number will be kept for processing
		cmp r12, 0
		beq SurelyAPositiveNumber @ if zero it is a positive number
		mov r1, regvar_lengthspec
		Macro_MakeNegativeNumberPositive r0, r1, r2 @ r0->numberptr, r1->numbytes, r2->ptr to new buffer
	@ copies the 2's complement of the number stored in memory into an internal buffer (r2) for further processing
		@ the internal buffer (placed in r0) stores the number in ceil(numberbytes/4) words in little endian form
		b NowFindTheDigits
	SurelyAPositiveNumber:
		ldr r2, =Number @ buffer where the number will be kept for processing
		mov r1, regvar_lengthspec
		Macro_CopyNumberToBuffer r0, r1, r2 @ r0->numberptr, r1->numbytes, r2->ptr to new buffer
@ copies our number into internal buffer(placed in r0); ceil(numberbytes/4) words in little endian form
	NowFindTheDigits:
		lsr r1, regvar_lengthspec, 2
		subs r12, regvar_lengthspec, r1, lsl 2
		it ne
		addne r1, 1 @ r1 = ceil(lengthspec/4) (size of number buffer in words)
	
		mov r12, 0 @ initialize outputstringlength to zero
		
		ldr freereg, =OutputString @ pointer to buffer where digits will be stored (in reverse order)
	ActuallyFindingDigits:
		Macro_IsNumberZero r0, r1, r2 @ while the number is non zero, divide it obtain remainder (works for any radix!)
			@ r0->numptr, r1->size(words), r2->output (zero if number is zero, nonzero otherwise)
		cbz r2, DoneDecodingNumber @ we already obtained all the digits (in reverse order)
		Macro_DivVectorByInt16 r0, r1, r3, r2 @ r0->number, r1->numsize(words), r3->divisor, r2->remainder(output)
			@ this changes the number into the quotient of the division. numsize is also adjusted.
		ldrb regvar_lengthspec, [regvar_state, r2] @ temp = LookUpTable[remainder] (clobber ok, i promise)
		strb regvar_lengthspec, [freereg, r12] @ outputstring[outputstringlength] = temp
		add r12, 1 @ outputstringlength++
		b ActuallyFindingDigits
	DoneDecodingNumber: @ now print it
		cmp r12, 0 @ if outputstringlength == 0 then make sure we will actually print the '0'
		bne LookAtPoundFlag @ if not equal to zero, we examine if we should add a '0' or '0x' or '0X' prefix
			mov r2, '0' @ r2 = '0'
			strb r2, [freereg] @ outputstring[0] = '0'
			add r12, 1 @ outputstringlength = 1
			b NowLookAtSign
		LookAtPoundFlag:
			ubfx r2, regvar_flags1, 24, 1 @ if flags.pound == true, print the prefix if o, x, X specifiers
			cbz r2, NowLookAtSign
			cmp r3, 10
			beq NowLookAtSign @ if decimal, no prefixes will be added
			cmp r3, 8 @ if radix == 8, then print '0'
			itttt eq
			moveq r2, '0'
			strbeq r2, [freereg, r12] @ outputstring[outputstringlength] = '0' // octal prefix
			addeq r12, 1 @ outputstringlength++
			beq NowLookAtSign @ now we are only left with the x and X cases
			ldrb r2, [regvar_state, 17] @ r2 = LookUpTable(Caps|NoCaps) [17] @ has x or X depending on table
			strb r2, [freereg, r12] @ outputstring[outputstringlength] = x or X
			add r12, 1 @ outputstringlength++
			mov r2, '0'
			strb r2, [freereg, r12] @ outputstring[outputstringlength] = '0'
			add r12, 1 @ outputstringlength++
	NowLookAtSign:
		and r2, regvar_flags2, (1<<24) @ test the negative sign bit for this number
		cbz r2, NumberIsNotNegative
		mov r2, '-'
		strb r2, [freereg, r12] @ outputstring[outputstringlength] = '-'
		add r12, 1 @ outputstringlength++
		b PrepareToPrint
	NumberIsNotNegative:
		ands r2, regvar_flags1, (1<<24) @ if flags.plus == true, then print a '+'
		ittt ne @ flag set
		movne r2, '+'
		strbne r2, [freereg, r12] @ outputstring[outputstringlength] = '+'
		addne r12, 1 @ outputstringlength++
		b PrepareToPrint
		ands r2, regvar_flags1, (1<<8) @ if flags.space == true, then print a 'space'
		ittt ne @ flag set
		movne r2, ' '
		strbne r2, [freereg, r12] @ outputstring[outputstringlength] = ' '
		addne r12, 1 @ outputstringlength++
	PrepareToPrint:
		sub r1, regvar_width, r12 @ r1 = width - outputstringlength // number of padding characters
		and r2, regvar_flags1, 1 @ check zero flag, which determines field padding
		ite eq @ if zero flag is unset
		moveq r3, ' ' @ pad with spaces to minimum field width 
		movne r3, '0' @ otherwise, if the flag is set, pad with zeroes to minimum field width
		and r2, regvar_flags2, 1 @ check the dash flag
		bl SwitchToPrintProfile @@@@
		cbz r2, DashFlagUnsetForNumber @ with dash flag: left justify field within width
		Macro_PrintStringInReverse freereg, r12 @ freereg->string, r12->length
		Macro_PrintSomeCharNTimes r3, r1 @ print padding character (width-outputstringlength)times
		b LoopThroughFormatString
	DashFlagUnsetForNumber: @ default: right justification of field within field width
		Macro_PrintSomeCharNTimes r3, r1 @ print padding character (width-outputstringlength)times
		Macro_PrintStringInReverse freereg, r12 @ freereg->string, r12->length
		b LoopThroughFormatString

FinishedReadingFormatString:
	cmp regvar_state, 0
	bne FormatStringPrematurelyEnded 
		@ if state != readformatstr then error // readformatstr==0
	cmp regvar_buffercount, 0
		@ if buffercount > 0 must flush the remaining characters to outputfunc
	ble FinishedPrintf
	mov r0, regvar_buffer
	mov r1, 0
	strb r1, [regvar_buffer, regvar_buffercount] @ buffer[buffercount] = \0
	blx regvar_outputfunc @ call outputfunc(buffer)
FinishedPrintf: @ unwind printf's stack and return number of printedchars (exit success)
add sp, printf_stackframesize
pop { r0-r12, lr }
add r0, regvar_printedchars, regvar_buffercount @ return r0 = printedchars + buffercount
mov pc, lr

InvalidLengthModifier:
		ldr r0, =InvalidLengthModifierMsg
		b FatalErrorUnwind


LengthModifierTooLong:
	ldr r0, =InvalidLengthModifierMsg
	b FatalErrorUnwind
LengthModifierTooLongMsg: .asciz "Length modifier can be no longer than 1024 bytes\n"

IllegalFormatSpecifierMsg: 
		.asciz "Error: invalid format specifier\n"
	.align
UselessInfoWithPercentSpecifierMsg: 
		.asciz "Error: format string ended in the middle of a format specifier\n"
	.align
FormatStringPrematurelyEndedMsg: 
		.asciz "Error: format string ended in the middle of a format specifier\n"
	.align
FlagsNotInUseWithSpecCandSMsg:
		.asciz "Error: the '+', ' ', '0', '#' flags not in use with c and s specifiers\n"
	.align
InvalidLengthModifierMsg: .asciz "Error: invalid length modifier in format string"
.align
InvalidLengthModifierWithStringandCharMsg:
		.asciz "Error: length modifiers are not used with char and string specifiers\n"
	.align
FlagAlreadySetMsg: .asciz "Error: repeated flags in format specifier\n"
	.align
InvalidModifiersWithSpecifierNMsg: 
	.asciz "Error: format specifier n doesn't take any additional parameters\n"
	.align
PlusAndSpaceFlagsBothSetMsg: .asciz "Error: Plus and Space flags both set\n"

ObtainValueFromNextArg: @ r0 -> lengthspec bytes (size of number, if argument is meant to be a number)
@ note: we used a different 'state machine' for reading argument string
// not necessary .equ matchleftbracket, 0
.equ matcharg, 1
.equ matchsign, 2
.equ matchshift, 3
.equ matchrightbracket, 4
.equ matchend, 5

@ argument string reader register profile:
//regvar_flags2 .req r4 @ -, exhaustedargs, addressmode,(squeeze 'offset_sign' in bit 20), negative flags
regvar_argstr .req r5 @ argument string
regvar_j .req r6 @ index along the argument string
regvar_args .req r7
regvar_arg .req r8
regvar_argstate .req r9	
.equ obtainarg_stackframesize, 9*4 @ 9 registers saved here
push {  r1-r3 , regvar_argstr, regvar_j, regvar_args, regvar_arg, regvar_argstate, lr }
	ldr regvar_j, [sp, (obtainarg_stackframesize + j) ]
	ldr regvar_argstr, [sp, (obtainarg_stackframesize + argstr) ]
	ldr regvar_args, =ArgValue @ memory where we store the arguments read (up to 3 of them)
	mov regvar_arg, 0 @ start by reading the first argument, arg0 (register, constant, etc)
	str regvar_arg, [regvar_args]
	str regvar_arg, [regvar_args, 4]
	str regvar_arg, [regvar_args, 8] @ set the args to zero by default
	bfi regvar_flags2, regvar_arg, 16, 1 @ addressmode = false (just the default setting)
	bfi regvar_flags2, regvar_arg, 20, 1 @ offsetsign = 0 (positive. it'a default setting)
	ubfx r1, regvar_flags2, 8, 1 @ examine 'exhaustedargs' flag
	cmp r1, 0
	bne MissingArguments @ if exhaustedargs == true, error
	mov regvar_argstate, matcharg @ start matching arguments
	
ReadTheArgumentString:
	ldr r1, =ReadArgumentStringBranchTable @@@@
	ldrb r2, [regvar_argstr, regvar_j] 
	tbh [r1, r2, lsl 1] @ switch(argstr[j])

	HandleLeftBracket: @ '[' in matcharg->ok. otherwise, error: misplaced left bracket in argstring
		cmp regvar_argstate, matcharg
		bne MisplacedLeftBracket
		cmp regvar_arg, 0
		bne MisplacedLeftBracket @ left bracket only when matching the first arg
		add regvar_flags2, (1<<16) @ addressmode = true
		mov regvar_argstate, matcharg @ now we will match the first argument
		add regvar_j, 1 @ j++ (next character)
		b ReadTheArgumentString

	HandleRightBracket: @ ']' in matchsign, matchshift, matchrightbracket->ok. otherwise, error
		tbb [pc, regvar_argstate] @ switch(argstate)
	JumpToHandleBracket:
		.byte 0 @ .byte (MisplacedRightBracket-JumpToHandleBracket)/2
		.byte (MisplacedRightBracket-JumpToHandleBracket)/2
		.byte (CloseBrackets-JumpToHandleBracket)/2
		.byte (CloseBrackets-JumpToHandleBracket)/2
		.byte (CloseBrackets-JumpToHandleBracket)/2
		.byte (MisplacedRightBracket-JumpToHandleBracket)/2
	CloseBrackets:
		ubfx r1, regvar_flags2, 16, 1 @ if addressmode == false, then error
		cbz r1, MisplacedRightBracket
		mov regvar_argstate, matchend @ now we will match the end of the argument ('\0' or ',')
		add regvar_j, 1 @ j++ (next character)
		b ReadTheArgumentString

	MisplacedRightBracket: @ called from within ObtainValueFromNextArg (extra stack unwinding)
		add sp, obtainarg_stackframesize @ unwind the stack here
		ldr r0, =MisplacedRightBracketMsg
		b FatalErrorUnwind
	

	HandleWhitespace: @ in all cases, we just skip it, incrementing the reading index j
		add regvar_j, 1
		b ReadTheArgumentString

	HandlePlus: @ '+': in matchsign, we set the sign to + and go to matcharg. it's already set (default)
		cmp regvar_argstate, matchsign
		bne MisplacedSign
		add regvar_j, 1
		mov regvar_argstate, matcharg
		b ReadTheArgumentString

	HandleMinus: @ '-': in matchsign, we set the sign to - and go to matcharg.
		cmp regvar_argstate, matchsign
		bne MisplacedSign
		add regvar_j, 1
		add regvar_flags2, (1<<20) @ offsetsign = negative
		mov regvar_argstate, matcharg
		b ReadTheArgumentString

	HandleR: @ 'r': start of register specification. otherwise invalid
		cmp regvar_argstate, matcharg @@@@
		bne SyntaxErrorInArgumentString @ sort of a catch all for argument string errors
		add regvar_j, 1 @ j++
		Macro_ParseStringAsDecimalNumber regvar_argstr, regvar_j, r1, r2 @ number in r1. r2: scratch.
		cmp r1, 0 @ if register number is smaller than 0, error
		blt InvalidRegister
		cmp r1, 15 @ bigger than 15, error
		bgt InvalidRegister
		cmp r1, 14 @ link register invalid (inaccessible in practice)
		beq LinkRegisterInvalid
		cmp r1, 13 @ if register is sp, value should be (current) sp + all the stack unwinding to caller
		bne NotSP
		add r2, sp, (obtainarg_stackframesize + printf_stackframesize + 14*4)
			@ 14 registers were saved in printf
		str r2, [regvar_args, regvar_arg] @ args[arg] = caller's value of sp
		b NextStateObtainValueFromNextArg @ next time we'll design a friendlier state machine
	NotSP: @ takes into account printf's push { r0-r12, lr }
		cmp r1, 15 @ if register is pc, value should be (current) sp + all the stack unwinding to "push lr"
		bne RegularRegister
		ldr r2, [sp, (obtainarg_stackframesize + printf_stackframesize + 13*4) ] 
			@ 13 registers were saved in printf, and above that lies LR (caller's PC)
		str r2, [regvar_args, regvar_arg] @ args[arg] = caller's value of sp
		b NextStateObtainValueFromNextArg
	RegularRegister: @ takes into account printf's push { r0-r12, lr }
		add r2, sp, (obtainarg_stackframesize + printf_stackframesize )
		ldr r2, [r2, r1, lsl 2 ] @ pick out our selected register from the stack
		str r2, [regvar_args, regvar_arg] @ args[arg] = caller's value of sp
		@ fall through to NextStateObtainValueFromNextArg

	NextStateObtainValueFromNextArg:
		add regvar_arg, 1 @ next arg
		cmp regvar_arg, 1 @ if arg==1, then it's time to match sign 
		it eq
		moveq regvar_argstate, matchsign
		cmp regvar_arg, 2 @ if arg==1, then it's time to match shift 
		it eq
		moveq regvar_argstate, matchshift
		cmp regvar_arg, 3 @ if arg==1, then it's time to match right bracket 
		it eq
		moveq regvar_argstate, matchrightbracket
		b ReadTheArgumentString

	HandleS: @ 's': has to be the s in sp. if it's not, error
		cmp regvar_argstate, matcharg
		bne SyntaxErrorInArgumentString
		add regvar_j, 1
		ldrb r1, [regvar_argstr, regvar_j]
		cmp r1, 'p' @ check that the next character is 'p' for sp
		bne SyntaxErrorInArgumentString
		add regvar_j, 1
		add r2, sp, (obtainarg_stackframesize + printf_stackframesize + 14*4)
			@ 14 registers were saved in printf
		str r2, [regvar_args, regvar_arg] @ args[arg] = caller's value of sp
		b NextStateObtainValueFromNextArg @ handle the next state transition

	HandleP: @ 'p': has to be the p in pc. if it's not, error
		cmp regvar_argstate, matcharg
		bne SyntaxErrorInArgumentString
		add regvar_j, 1
		ldrb r1, [regvar_argstr, regvar_j]
		cmp r1, 'c' @ check that the next character is 'c' for pc
		bne SyntaxErrorInArgumentString
		add regvar_j, 1
		ldr r2, [sp, (obtainarg_stackframesize + printf_stackframesize + 13*4) ] 
			@ 13 registers were saved in printf, and above that lies LR (caller's PC)
		str r2, [regvar_args, regvar_arg] @ args[arg] = caller's value of sp
		b NextStateObtainValueFromNextArg @ handle the next state transition

	HandleL: @ either 'l' in lr (invalid), or 'l' in lsl
		add regvar_j, 1
		ldrb r1, [regvar_argstr, regvar_j]
		cmp r1, 'r' @ r in lr
		beq LinkRegisterInvalid @ caller's lr is inaccessible
		cmp regvar_argstate, matchshift @ we are expecting the shift argument
		bne SyntaxErrorInArgumentString 
		cmp r1, 's' @ s in lsl 
		bne SyntaxErrorInArgumentString
		add regvar_j, 1
		ldrb r1, [regvar_argstr, regvar_j]
		cmp r1, 'l' @ final l in lsl
		bne SyntaxErrorInArgumentString
		add regvar_j, 1
		mov regvar_argstate, matcharg @ match the final argument now 
		b NextStateObtainValueFromNextArg

	Handle123456789: @ decimal constant detected
		cmp regvar_argstate, matcharg @ must be an argument
		bne SyntaxErrorInArgumentString
		Macro_ParseStringAsDecimalNumber regvar_argstr, regvar_j, r1, r2 @ result in r1. r2: scratch
		str r1, [regvar_args, regvar_arg] @ args[arg] = constant read from string
		b NextStateObtainValueFromNextArg @ handle next state transition

	Handle0: @ octal or hex constant detected
		cmp regvar_argstate, matcharg @ must be an argument
		bne SyntaxErrorInArgumentString
		add regvar_j, 1
		ldrb r1, [regvar_argstr, regvar_j] @ if argstr[j] == 'x' or 'X' we have a hex constant. otherwise: octal
		cmp r1, 'x'
		beq TreatHexConstant
		cmp r1, 'X'
		beq TreatHexConstant
		sub regvar_j, 1
		Macro_ParseStringAsOctalNumber regvar_argstr, regvar_j, r1, r2 @ result in r1. r2: scratch
		str r1, [regvar_args, regvar_arg] @ args[arg] = constant read from string
		b NextStateObtainValueFromNextArg @ handle next state transition
	TreatHexConstant:
		add regvar_j, 1
		Macro_ParseStringAsHexNumber regvar_argstr, regvar_j, r1, r2 @ result in r1. r2: scratch
		str r1, [regvar_args, regvar_arg] @ args[arg] = constant read from string
		b NextStateObtainValueFromNextArg @ handle next state transition

	HandleNulTerminator:
		add regvar_flags2, (1<<8) @ finishedargs = true @ no more args available to process
		@ fall through to handle comma
	HandleComma: @ ',' in matchsign, matchshift, matchrightbracket->ok. otherwise, error
		tbb [pc, regvar_argstate] @ switch(argstate)
	JumpToHandleCommaNul:
		.byte 0 @ .byte (PrematurelyEndedArgumentString - JumpToHandleCommaNul)/2
		.byte (PrematurelyEndedArgumentString-JumpToHandleCommaNul)/2
		.byte (AreBracketsClosed-JumpToHandleCommaNul)/2
		.byte (AreBracketsClosed-JumpToHandleCommaNul)/2
		.byte (AreBracketsClosed-JumpToHandleCommaNul)/2
		.byte (PrematurelyEndedArgumentString-JumpToHandleCommaNul)/2
	AreBracketsClosed:
		add regvar_j, 1
		ubfx r1, regvar_flags2, 16, 1 @ if addressmode == false, then finish up
		cbz r1, FinishedReadingArgument
		cmp regvar_argstate, matchend @ if addressmode == true, then we must be in matchend (brackets were closed)
		bne MissingClosingBracket
		@ fall through to FinishedReadingArgument

FinishedReadingArgument:
	
	ldmia regvar_args, {r1, r2, r3} @ load the args for processing
	lsl r2, r2, r3 @ apply the shift
	ubfx r3, regvar_flags2, 20, 1 @ fetch the offset sign bit
	cmp r3, 0
	ite eq
	addeq r1, r1, r2 @ apply positive offset
	subne r1, r1, r2 @ apply negative offset
	ubfx r3, regvar_flags2, 16, 1 @ fetch the address mode bit
	cbnz r3, FinishObtainValueFromNextArg @ we want to return the address we calculated
	cmp r0, 1 @ if numbytes==1, store byte:
	itt eq
	sxtbeq r1, r1
	streq r1, [regvar_args] @ store value calculated
	cmp r0, 2 @ if numbytes==2, store halfword:
	itt eq
	sxtheq r1, r1
	streq r1, [regvar_args] @ store value calculated
	cmp r0, 3 @ if numbytes==3, store lower 3 bytes: (dude who is gonna use this feature)
	itt eq
	lsleq r1, 8
	asreq r1, 8
	str r1, [regvar_args] @ store value calculated
	mov regvar_args, r1 @ return pointer to value
FinishObtainValueFromNextArg:
	mov r0, r1 @ return pointer to argument value that we fetched (must be in r0 according to convention)
	str regvar_j, [sp, (obtainarg_stackframesize + j) ] @ only one we have to actually save
pop {  r1-r3 , regvar_argstr, regvar_j, regvar_args, regvar_arg, regvar_argstate, pc }


@  !! ERROR CONDITIONS !! 

PrematurelyEndedArgumentString: @ called from within ObtainValueFromNextArg 
	add sp, obtainarg_stackframesize @ unwind the stack here
	ldr r0, =PrematurelyEndedArgumentStringMsg
	b FatalErrorUnwind

MissingArguments: @ called from within ObtainValueFromNextArg (extra stack unwinding)
	add sp, obtainarg_stackframesize @ unwind the stack here
	ldr r0, =MissingArgumentsMsg
	b FatalErrorUnwind

HandleOtherCharacter: @ called from within ObtainValueFromNextArg (extra stack unwinding)
	add sp, obtainarg_stackframesize @ unwind the stack here
	ldr r0, =HandleOtherCharacterMsg
	b FatalErrorUnwind


LinkRegisterInvalid: @ called from within ObtainValueFromNextArg (extra stack unwinding)
	add sp, obtainarg_stackframesize @ unwind the stack here
	ldr r0, =LinkRegisterInvalidMsg
	b FatalErrorUnwind


InvalidRegister: @ called from within ObtainValueFromNextArg (extra stack unwinding)
	add sp, obtainarg_stackframesize @ unwind the stack here
	ldr r0, =InvalidRegisterMsg
	b FatalErrorUnwind


MisplacedLeftBracket: @ called from within ObtainValueFromNextArg (extra stack unwinding)
	add sp, obtainarg_stackframesize @ unwind the stack here
	ldr r0, =MisplacedLeftBracketMsg
	b FatalErrorUnwind


MisplacedSign: @ called from within ObtainValueFromNextArg (extra stack unwinding)
	add sp, obtainarg_stackframesize @ unwind the stack here
	ldr r0, =MisplacedPlusSignMsg
	b FatalErrorUnwind

MissingClosingBracket: @ called from within ObtainValueFromNextArg (extra stack unwinding)
	add sp, obtainarg_stackframesize @ unwind the stack here
	ldr r0, =MissingClosingBracketMsg
	b FatalErrorUnwind


SyntaxErrorInArgumentString: @ called from within ObtainValueFromNextArg 
								@ (sort of a catch all for argument string errors
	add sp, obtainarg_stackframesize @ unwind the stack here
	ldr r0, =SyntaxErrorInArgumentStringMsg
	b FatalErrorUnwind

SyntaxErrorInArgumentStringMsg: .asciz "Error: syntax error in argument string\n"
.align
MissingArgumentsMsg: .asciz "Error: missing necessary arguments in the argument string\n"
.align
MisplacedRightBracketMsg: .asciz "Error: misplaced right bracket in the argument string\n"
.align
MisplacedPlusSignMsg: .asciz "Error: misplaced plus sign in the argument string\n"
.align
PrematurelyEndedArgumentStringMsg: 
	.asciz "Error: argument string ended in the middle of a format specifier\n"
.align
HandleOtherCharacterMsg: 
	.asciz "Error: stray character in argument string\n" @ typical assembler (crap compiler) error
.align
LinkRegisterInvalidMsg: 
	.asciz "Error: Link Register is inaccessible to printf, clobbered by branch and link\n"
.align
InvalidRegisterMsg: .asciz "Error:Invalid Register in the argument string\n"
.align
MisplacedLeftBracketMsg: .asciz "Error: misplaced left bracket in the argument string\n"
.align
MisplacedSignMsg: .asciz "Error: misplaced sign in the argument string\n"
.align
MissingClosingBracketMsg: .asciz "Error: missing closing bracket in argument string\n"
.align

FatalErrorUnwind: @ unwind stack from main routine (other routines must unwind their stack)
	add sp, printf_stackframesize @ undo printf's stack frame
	pop { r1 } @ can't clobber r0 because that is where the fatal error msg is
	pop { r1-r12, lr } @ restore all the other registers
	str r0, [sp] @ pointer to error message at sp
	mov r0, -1 @ return -1 for error
mov pc, lr @ returns to printf's caller: printf unwound by fatal ("compilation" type) error

@ HELPERS

SwitchToFormatSpecifierProfile: 
@ no clobber allowed: heavenly punishment for not leaving register allocation as an afterthought
@@@@ must be in 'print' register profile !!! (prematurely evil optimization ???)
	
	str regvar_buffercount, [sp , buffercount] @ avoid clobber
	str regvar_outputfunc, [sp, outputfunc]
	str regvar_printedchars, [sp, printedchars]
	mov regvar_flags1, 0 @ clear 0, space, #, + flags
	bic regvar_flags2, 1 @ clear the dash flag
	mov regvar_width, 0 @ default: no minimum field width
	mov regvar_lengthspec, 4 @ default length of number: 4 bytes
	mov regvar_state, readflags @ start parsing elements of the format specifier
mov pc, lr

SwitchToPrintProfile:
@ goes from format specifier to print profile
	str regvar_buffercount, [sp , buffercount] @ clobber ok...
	str regvar_outputfunc, [sp, outputfunc]
	str regvar_printedchars, [sp, printedchars]
	mov regvar_state, readformatstr @ go back to reading the format string
mov pc, lr

PrintChar: @ internal to printf. r0 => character to be printed
@ register profile must be: "print" mode
push { r0-r3, r12, lr } @ precaution: save everybody
	cmp regvar_buffercount, BUFFERSIZE @ if buffercount == buffersize
	bne StillSpaceInBuffer
	mov r0, regvar_buffer
	blx regvar_outputfunc @ call outputfunc(buffer) (MAY clobber scratch: r0-r3, r12)
	mov regvar_buffercount, 0 @ buffercount = 0
	add regvar_printedchars, regvar_printedchars, BUFFERSIZE
StillSpaceInBuffer:
	pop { r0 } @ restore the chracter to be printed 
	strb r0, [regvar_buffer, regvar_buffercount]  @ buffer[buffercount] = character to print
	add regvar_buffercount, 1 @ buffercount++
pop { r1-r3, r12, pc }

.data
.align
.equ bufsize_format, 1024 @ store user inputted format string: should be enough for testing purposes
.equ bufsize_argument, 1024 @ store user inputted argument string: should be enough for testing purposes

FormatString: @ for the user application tester
.rept bufsize_format
	.byte 0
.endr

ArgumentString: @ for the user application tester
.rept bufsize_argument
	.byte 0
.endr

OutputString: // keeps ascii characters while processing before printout
.rept OUTPUTSTRINGSIZE 
	.byte 0
.endr

Number: // keeps internal representation of number for manipulation
.rept MAXNUMBYTESIZE // ceiling of maximum bytelength/4
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

DigitsLookup:
.byte '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'x'

DigitsLookupCaps:
.byte '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', 'X'

ReadFormatStringBranchTable: @ yes, this is unnecessary, but it reduces instruction path length
@ for the typical printchar to a paltry 12 instructions; probably impossible to reduce this
@ without risking buffer overflow (or: use a 1 or 2 instruction, inline, IO write routine
@ instead of libc's puts. then a buffer is unnecessary for performance: you can dispatch 
@ characters immediately and the peripheral handles the rest without blocking the CPU)
	.byte (FinishedPrintfTrampoline-BeginReadingFormatSpecifier)/2 @ nul terminator of the format string
	.rept '%' - 1
		.byte (PrintNormalCharacter-BeginReadingFormatSpecifier)/2
	.endr
	.byte (BeginReadingFormatSpecifier-BeginReadingFormatSpecifier)/2
	.rept 255 - '%'
		.byte (PrintNormalCharacter-BeginReadingFormatSpecifier)/2
	.endr

FlagsBranchTable: @ streamlines the code. obsviously not essential
	.byte (FormatStringPrematurelyEnded-HandleDashFlag)/2 @ \0 terminator
	.rept ' ' - 1 @ fill up to space
		.byte (NoFlags-HandleDashFlag)/2
	.endr
	.byte (HandleSpaceFlag-HandleDashFlag)/2
	.rept '#' - ' ' - 1 @ fill between space and pound
		.byte (NoFlags-HandleDashFlag)/2
	.endr
	.byte (HandlePoundFlag-HandleDashFlag)/2
	.rept '+'-'#'-1 @ fill between plus and pound
		.byte (NoFlags-HandleDashFlag)/2
	.endr
	.byte (HandlePlusFlag-HandleDashFlag)/2
	.rept '-' - '+'-1 @ fill between dash and plus
		.byte (NoFlags-HandleDashFlag)/2
	.endr
	.byte 0 @ .byte (HandleDashFlag-HandleDashFlag)/2
	.rept '0'-'-'-1 @ fill between zero and dash
		.byte (NoFlags-HandleDashFlag)/2
	.endr
	.byte (HandleZeroFlag-HandleDashFlag)/2
	.rept 255 - '0' @ fill rest of table
		.byte (NoFlags-HandleDashFlag)/2
	.endr

WidthBranchTable: @ streamlines the code. obsviously not essential
	.byte (FormatStringPrematurelyEnded-HandleWidthArg)/2 @ \0 terminator
	.rept '*' - 1 @ fill up to '*'
		.byte (NoWidth-HandleWidthArg)/2
	.endr
	.byte (HandleWidthArg-HandleWidthArg)/2
	.rept '0'-'*'-1 @ fill between asterisk and 0
		.byte (NoWidth-HandleWidthArg)/2
	.endr
	.rept 10 
		.byte (HandleWidthSpec-HandleWidthArg)/2 
	.endr
	.rept 255 - '9' @ other characters lead to next state
		.byte (NoWidth-HandleWidthArg)/2
	.endr

LengthSpecBranchTable: @ streamlines the code. obsviously not essential
	.byte (FormatStringPrematurelyEnded-LengthSpecH)/2 @ \0 terminator
	.rept '0' - 1
		.byte (NoLengthSpec-LengthSpecH)/2
	.endr
	.rept 10
		.byte (LengthSpecNumber-LengthSpecH)/2 @ the decimal digits
	.endr
	.rept 'h' - '9' - 1
		.byte (NoLengthSpec-LengthSpecH)/2
	.endr
	.byte (LengthSpecH-LengthSpecH)/2
	.rept 'l'-'h'-1 
		.byte (NoLengthSpec-LengthSpecH)/2
	.endr
	.byte (LengthSpecL-LengthSpecH)/2
	.rept 255 - 'l' @ other characters lead to next state
		.byte (NoLengthSpec-LengthSpecH)/2
	.endr

ReadFormatSpecifierBranchTable:
	.byte (FormatStringPrematurelyEnded-ReadPercent)/2 @ \0 terminator
	.rept '%' - 1 @ fill the table up to '%'
		.byte (IllegalFormatSpecifier-ReadPercent)/2
	.endr
	.byte 0 @ '%' is right after the table branch
	.rept 'X' - '%' - 1
		.byte (IllegalFormatSpecifier-ReadPercent)/2
	.endr
	.byte (ReadUnsignedHexCaps-ReadPercent)/2
	.rept 'c' - 'X' - 1
		.byte (IllegalFormatSpecifier-ReadPercent)/2
	.endr
	.byte (ReadCharacter-ReadPercent)/2
	.byte (ReadSignedDecimal-ReadPercent)/2
	.rept 'i' - 'd' - 1
		.byte (IllegalFormatSpecifier-ReadPercent)/2
	.endr
	.byte (ReadSignedDecimal-ReadPercent)/2 @ %i is also a signed decimal integer
	.rept 'n' - 'i' - 1
		.byte (IllegalFormatSpecifier-ReadPercent)/2
	.endr
	.byte (ReadSpecifierN-ReadPercent)/2
	.byte (ReadOctalNumber-ReadPercent)/2
	.byte (ReadPointer-ReadPercent)/2
	.rept 's' - 'p' - 1
		.byte (IllegalFormatSpecifier-ReadPercent)/2
	.endr
	.byte (ReadString-ReadPercent)/2
	.byte (IllegalFormatSpecifier-ReadPercent)/2
	.byte (ReadUnsignedDecimal-ReadPercent)/2 @ %u
	.rept 'x' - 'u' - 1
		.byte (IllegalFormatSpecifier-ReadPercent)/2
	.endr
	.byte (ReadUnsignedHex-ReadPercent)/2
	.rept 255 - 'x'
		.byte (IllegalFormatSpecifier-ReadPercent)/2
	.endr

ReadArgumentStringBranchTable: @ to do: create a $#$#@&% macro to make these tables
	.hword (HandleNulTerminator-HandleLeftBracket)/2 @ \0 terminator
	.rept '\t' - 1 @ whitespace
		.hword (HandleOtherCharacter-HandleLeftBracket)/2
	.endr
	.hword (HandleNulTerminator-HandleLeftBracket)/2 @ \t
	.hword (HandleWhitespace-HandleLeftBracket)/2 @ \n
	.rept '\r' - '\n' - 1
		.hword (HandleOtherCharacter-HandleLeftBracket)/2
	.endr
	.hword (HandleWhitespace-HandleLeftBracket)/2 @ \r
	.rept ' ' - '\r' - 1
		.hword (HandleOtherCharacter-HandleLeftBracket)/2
	.endr
	.hword (HandleWhitespace-HandleLeftBracket)/2 @ space
	.rept '+' - ' ' - 1
		.hword (HandleOtherCharacter-HandleLeftBracket)/2
	.endr
	.hword (HandlePlus-HandleLeftBracket)/2 @ +
	.hword (HandleComma-HandleLeftBracket)/2 @ ,
	.hword (HandleMinus-HandleLeftBracket)/2 @ -
	.rept  '0' - '-' - 1
		.hword (HandleOtherCharacter-HandleLeftBracket)/2
	.endr
	.hword (Handle0-HandleLeftBracket)/2 @ the zero digit
	.hword (Handle123456789-HandleLeftBracket)/2 @ digits
	.hword (Handle123456789-HandleLeftBracket)/2 @ digits
	.hword (Handle123456789-HandleLeftBracket)/2 @ digits
	.hword (Handle123456789-HandleLeftBracket)/2 @ digits
	.hword (Handle123456789-HandleLeftBracket)/2 @ digits
	.hword (Handle123456789-HandleLeftBracket)/2 @ digits
	.hword (Handle123456789-HandleLeftBracket)/2 @ digits
	.hword (Handle123456789-HandleLeftBracket)/2 @ digits
	.hword (Handle123456789-HandleLeftBracket)/2 @ digits
	.rept '[' - '9' - 1 
		.hword (HandleOtherCharacter-HandleLeftBracket)/2
	.endr
	.hword (HandleLeftBracket-HandleLeftBracket)/2 @ [
	.hword (HandleOtherCharacter-HandleLeftBracket)/2 @ some invalid char
	.hword (HandleRightBracket-HandleLeftBracket)/2 @ ]
	.rept 'l' - ']' - 1
		.hword (HandleOtherCharacter-HandleLeftBracket)/2
	.endr
	.hword (HandleL-HandleLeftBracket)/2 @ l
	.rept 'p' - 'l' - 1 @ whitespace
		.hword (HandleOtherCharacter-HandleLeftBracket)/2
	.endr
	.hword (HandleP-HandleLeftBracket)/2 @ p
	.hword (HandleOtherCharacter-HandleLeftBracket)/2 @ q (invalid)
	.hword (HandleR-HandleLeftBracket)/2 @ r
	.hword (HandleS-HandleLeftBracket)/2 @ s
	.rept 255 - 's' @ the rest
		.hword (HandleOtherCharacter-HandleLeftBracket)/2
	.endr
