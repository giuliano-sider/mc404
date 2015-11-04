.align

.macro StrLenMacro Rstring, Rlength, Rscratch @ pointer to string (input), length (output), scratch register
	mov \Rlength, 0
StrLenMacroLoop\@:
	ldrb \Rscratch, [\Rstring, \Rlength]
	cbz \Rscratch, DoneStrLenMacro\@
	add \Rlength, 1
	b StrLenMacroLoop\@
DoneStrLenMacro\@:
.endm

printf_baremetal: 
@ int printf_baremetal( int (*outputfunc)(const char*) , const char *formatstr, const char *argstr)
@ outputfunc used for testing is puts

@ define the variables as sp offsets:
.equ outputfunc, 0 @ pointer to function that does printing
.equ printedchars, 4 @ number of characters actually printed so formatstr
.equ specifier, 8 @ code indicating which specifier has been selected
.equ width, 12 @ minimum number of characters to be printed in a field
.equ lengthspec, 16 @ bytes in number (hh: 1 byte, h: 2 bytes, default: 4 bytes, l: 8 bytes, ll: 16 bytes)
.equ flags1, 20 @ some flags here
.equ flagzero, 20 @ is zero flag set
.equ flagsspace, 21 @ is space flag set
.equ flagpound, 22 @ is 'pound' flag set
.equ flagplus, 23 @ is plus flag set
.equ flags2, 24 @ another grouping of flags for convenience
.equ flagsdash, 24 @ is dash flag set
.equ finishedargs, 25 @ flag indicating whether we have gotten to the end of the argument string
.equ addressmode, 26 @ flag indicating whether we are obtaining an address as argument
.equ offset, 27 @ positive or negative register/constant offset in the argument specification


.equ buffer, 32 @ pointer to the buffer where chracters are stored before being printed
//.equ buffercount, 36 @ how many characters are in the buffer currently
.equ outputstring, 40 @ pointer to buffer where formatted characters are printed out before field width adjustment, etc
.equ outputstringlength, 44 @ number of characters stored so far in the outputstring
.equ formatstr 48 @ pointer to the format string
.equ argstr 52 @ pointer to the argument string
//.equ i 56 @ index along format string
//.equ j 60 @ index along argument string
//.equ state 64 @ what reading state are we in currently
.equ radix, 68 @ what radix of number are we reading
.equ args, 72 @ pointer to buffer where values fetched from argument string are kept, and that's used as a storage for formatting register (that is, non memory) values
.equ arg, 76 @ number of argument that we are fetching from a given argument string field
.equ argstate, 80 @ point along which we are reading the argument string
.equ stackframesize, 84

.equ false, 0
.equ true, 1

.equ buffersize, 1024 @ actual size of buffer that holds chars before they go out to outputfunc
// a catalog of states:
.equ readformatstr, 0
.equ readflags, 1
.equ readwidth, 2
.equ readlengthspec, 3
.equ readformatspecifier, 4
.equ readformatarg, 5
.equ matchleftbracket, 0 @ note: we used a different 'state machine' for reading argument string
.equ readarg, 1
.equ matchsign, 2
.equ matchshift, 3
.equ matchrightbracket, 4

regvar_i .req r6 @ most used
regvar_j .req r7 @ most used
regvar_formatstr .req r4 @ most used
regvar_argstr .req r5 @ most used
regvar_state .req r8 @ most used
regvar_buffercount .req r9 @ reduces print to 7 instructions only (unless buffer must be flushed)
freereg1 .req r10
freereg2 .req r11

push { r0-r12, lr } @ we keep track of sp. lr is user pc. user original lr is not available, clobbered during branch and link.
// initialize
sub sp, stackframesize @ make way for all those variables (later we can optimize by putting some in registers, but this alleviates some of the pain of coding a complicated (many if's) function)
	str r0, [sp, outputfunc]
	mov regvar_formatstr, r1  // str r1, [sp, formatstr]
	mov regvar_argstr, r2 // str r2, [sp, argstr]
	mov regvar_buffercount, 0 @ number of characters currently loaded to output buffer
	mov regvar_i, 0  // str r3, [sp, i] @ index to the format string
	mov regvar_j, 0 // str r3, [sp, j] @ index to the argument string
	mov regvar_state, readformatstr // str r3, [sp, state] @ initial state is readformatstr == 0; begin reading format string
	bl ResetState @ resets the format string reader to its 'ground state' (no specifiers, flags set, etc)
	mov r3, 0
	str r3, [sp, printedchars] @ number of characters actually sent to outputfunc so far
	
LoopThroughFormatString:
	ldr freereg1, [regvar_formatstr, regvar_i] 
	cbz FinishedReadingFormatString @ while formatstr[i] != 0 // nul terminator of format string
	tbb [pc, regvar_state] @ switch (state) // be very careful with the order
BranchByState:
.byte (ReadFormatString-BranchByState)/2
.byte (ReadFlags-BranchByState)/2
.byte (ReadWidth-BranchByState)/2
.byte (ReadLengthSpec-BranchByState)/2
.byte (ReadFormatSpecifier-BranchByState)/2
.byte (ReadFormatArg-BranchByState)/2

	ReadFormatString:
		// already loaded! ldr freereg1, [regvar_formatstr, regvar_i] @ freereg1 = formatstr[i]
		cmp freereg1, '%' @ if formatstr[i] == '%' then begin reading a format specifier
		ite eq
		moveq regvar_state, readflags @ state = readflags
		blne PrintChar @ else PrintChar(formatstr[i]) @ parameter in r1
		add regvar_i, 1 @ i++
	ReadFlags:
		ldr r1, =FlagsBranchTable
		tbb [r1, freereg1] @ switch(formatstr[i]) although it takes a bit of space at the data section, this cleans up the code
		HandleDashFlag: @ left justify field within field width
			ldrb r1, [sp, flagsdash]
			cbnz r1, FlagAlreadySet @ error (strictly speaking, this would generate a compiler warning)
			strb r1, [sp, flagsdash] @ flags.dash = 1
			add regvar_i, 1 @ i++ 
			b LoopThroughFormatString
		HandlePlusFlag: @ left justify field within field width
			ldrb r1, [sp, flagsplus]
			cbnz r1, FlagAlreadySet @ error (strictly speaking, this would generate a compiler warning)
			strb r1, [sp, flagsplus] @ flags.plus = 1
			add regvar_i, 1 @ i++
			b LoopThroughFormatString
		HandleSpaceFlag: @ left justify field within field width
			ldrb r1, [sp, flagsspace]
			cbnz r1, FlagAlreadySet @ error (strictly speaking, this would generate a compiler warning)
			strb r1, [sp, flagsspace] @ flags.space = 1
			add regvar_i, 1 @ i++
			b LoopThroughFormatString
		HandlePoundFlag: @ left justify field within field width
			ldrb r1, [sp, flagspound]
			cbnz r1, FlagAlreadySet @ error (strictly speaking, this would generate a compiler warning)
			strb r1, [sp, flagspound] @ flags.pound = 1
			add regvar_i, 1 @ i++
			b LoopThroughFormatString
		HandleZeroFlag: @ left justify field within field width
			ldrb r1, [sp, flagszero]
			cbnz r1, FlagAlreadySet @ error (strictly speaking, this would generate a compiler warning)
			strb r1, [sp, flagszero] @ flags.zero = 1
			add regvar_i, 1 @ i++
			b LoopThroughFormatString
		NoFlags:
			mov regvar_state, readwidth @ state = readwidth (no more flags to read)
			b LoopThroughFormatString

	ReadWidth:
		cmp freereg1, '*' @ if formatstr[i] == '*' then read width from argument string (preceding formatted argument)
		bne ReadWidthNumber @ else read width number (or there is no number)
		mov r0, 4 @ obtain 4 byte width value from argument string
		bl ObtainValueFromNextArg @ returns an array (r0) with argument value stored in it. we know how many bytes of this array to access (4 in this case)
		ldr r1, [r0] @ load argument value that was read
		str r1, [sp, width] @ width = (:lower32:) *( ObtainValueFromNextArg(4) )
		add regvar_i, 1 @ i++
		b LoopThroughFormatString
	ReadWidthNumber
		mov r0, 0 @ initialize width to zero for the next loop
	LoopReadWidthNumber:
		cmp freereg1, '0' @ if formatstr[i] < '0' then stop reading the width of the field
		blt FinishWidthNumber
		cmp freereg1, '9' @ if formatstr[i] > '9' then stop reading the width of the field
		bgt FinishedWidthNumber
		sub freereg1, '0' @ subtract '0' to decode number in string as a decimal integer
		add freereg1, freereg1, r0, lsl 1
		add freereg1, freereg1, r0, lsl 3 @ width = width * 10 + (formatstr[i]-'0')
		add regvar_i, 1 @ i++
		ldr freereg1, [formatstr, regvar_i] @ load formatstr[i]
		b LoopReadWidthNumber @ while formatstr[i] is still a decimal number, 0-9
	FinishWidthNumber:
		str r0, [sp, width]
		mov regvar_state, readlengthspec
		b LoopThroughFormatString

	ReadLengthSpec:
		cmp freereg1, 'h' @ if formatstr[i] == 'h' // short integer length specifier
		bne CheckLengthSpecL
		add r0, regvar_i, 1
		ldr r0, [regvar_formatstr, r0] @ check for 'hh' specifier at formatstr[i+1] (lookahead)
		cbz r0, FormatStringPrematurelyEnded @ error
		cmp r0, 'h' @ if formatstr[i+1] == 'h' then we have specifier 'hh', a short short integer (byte)
		beq LenghtSpecHH
		mov r2, 2
		str r2, [sp, lengthspec] @ length spec 2 detected ('h')
		add regvar_i, 1 @ i++
		b FinishedLengthSpec
	LengthSpecHH:
		mov r2, 1
		str r2, [sp, lengthspec] @ length spec 1 detected ('hh')
		add regvar_i, 2 @ i+=2, we just consumed 2 characters here
		b FinishedLengthSpec
	CheckLengthSpecL:
		cmp freereg1, 'l' @ if formatstr[i] == 'l' // long integer length specifier
		bne NoLengthSpec
		add r0, regvar_i, 1
		ldr r0, [regvar_formatstr, r0] @ check for 'hh' specifier at formatstr[i+1] (lookahead)
		cbz r0, FormatStringPrematurelyEnded @ error
		cmp r0, 'l' @ if formatstr[i+1] == 'l' then we have specifier 'l', a long integer (byte)
		beq LenghtSpecLL
		mov r2, 8
		str r2, [sp, lengthspec] @ length spec 8 detected ('l')
		add regvar_i, 1 @ i++
		b FinishedLengthSpec
	LengthSpecLL:
		mov r2, 16
		str r2, [sp, lengthspec] @ length spec 16 detected ('ll')
		add regvar_i, 2 @ i+=2, we just consumed 2 characters here
		b FinishedLengthSpec
	FinishedLengthSpec:
		mov regvar_state, readformatspecifier @ state = readformatspecifier
		b LoopThroughFormatString @ length spec stays as the default: 4 bytes

	ReadFormatSpecifier:
		ldr r0, =ReadFormatSpecifierBranchTable
		tbb [r0, freereg1] @ another branch table indexed by ascii. cleaner code comes at the price of 256 bytes
	ReadPercent:
		bl PrintChar @ freereg1 is already loaded with the '%' character
		bl ResetState @ return the format string reader to its normal state. we could previously check if useless information was passed to % specifier (compiler, for example, generates a warning)
		add regvar_i, 1 @ i++
		b LoopThroughFormatString
	ReadString: @ checks done for string are actually the same as for character
	ReadCharacter:
		str freereg1, [sp, specifier] @ specifier = formatstr[i]
		ldr r0, [sp, lengthspec]
		cmp r0, 4
		bne LengthModNotValid @ error
		ldr r0, [sp, flags1] @ check if any of the dash, zero, plus, space flags are set
		cbnz FlagsNotInUseWithSpecC @ error
		b FinishedReadingFormatSpecifier
	ReadSignedDecimal:
	ReadUnsignedDecimal:
		str freereg1, [sp, specifier] @ specifier = formatstr[i]
		b FinishedReadingFormatSpecifier
	ReadSpecifierN:
		str freereg1, [sp, specifier] @ specifier = formatstr[i]
		ldr r0, [sp, lengthspec]
		cmp r0, 4 @ just some optional checks (aka "compiler" warnings, albeit we halt with an error message)
		beq FormatSpecNDoesntTakeAdditionalParams
		ldr r0, [sp, flags1]
		cbnz r0, FormatSpecNDoesntTakeAdditionalParams
		b FinishedReadingFormatSpecifier
	ReadOctalNumber:
		str freereg1, [sp, specifier]
		mov r0, 8
		str r0, [sp, radix]
		b FinishedReadingFormatSpecifier
	ReadPointer: @ %0#8x is our standard for printing pointers
		mov r0, 1
		strb r0, [sp, flagszero]
		strb r0, [sp, flagspound]
		mov r0, 'x'
		str r0, [sp, specifier]
		mov r0, 8
		str r0, [sp, width]
		mov r0, 16
		str r0, [sp, radix]
		b FinishedReadingFormatSpecifier
	ReadUnsignedHex:
	ReadUnsignedHexCaps:
		str freereg1, [sp, specifier] @ specifier = formatstr[i]
		mov r0, 16
		str r0, [sp, radix]
	FinishedReadingFormatSpecifier:
		add regvar_i, 1 @ consume the format specifier character
		mov regvar_state, readformatarg @ now read characters from the arg string and print
		b LoopThroughFormatString	

	ReadFormatArg:
		ldr r0, [sp, lengthspec]  @ call ObtainValueFromNextArg ( lengthspec ) to obtain a vector, in little endian
		bl ObtainValueFromNextArg @ form, of lengthspec bytes, corresponding to field to be formatted
@ r0 is 'value', a pointer to a vector of lengthspec bytes containing (little endian) the value which will be formatted
		ldr r3, [sp, specifier]
		cmp r3, 'n' @ if specifier == 'n' handle the case where we store, at the address given (as 'value'), the number of characters outputted so far
		bne ProcessChar

		ldr r2, [sp, printedchars]
		add r2, r2, regvar_buffercount
		str r2, [r0] @ *(:lower32bits: value) = printedchars + buffercount
		b FinishedFormatting
	ProcessChar:
		cmp r3, 'c' @ if specifier == 'c' turn it into a string for processing (for left justification, field width)
		bne CheckSSpecifier
		ldr r2, [r0] @ value[0] // first byte: the char that we will process/print as a string 
		str r2, [r0, 4] @ safely keep it here 
		mov r2, 0
		str r2, [r0, 5] @ nul byte terminator for the string 
		add r0, 4 @ now 'value' is a pointer to the one character string we want to process and print
		b ProcessString
	CheckSSpecifier:
		cmp r3, 's' @ if specifier == 's' process the string (take into account field justification, width)
		bne ProcessNumber @ the other specifiers are all for numbers
	ProcessString: @ r0->string, r1->strlength, r2->s(index) r3->width-len 
		StrLenMacro r0, r1, r2 @ pointer to string in r0, length of string comes out in r1, scratch reg: r2
		ldrb r2, [sp, flagsdash] if flags.dash == true
		ldr r3, [sp, width]
		sub r3, r3, r1 @ for s = 0 to width - len - 1 (remember that default field width is 0, for which this loop wont run)
		mov r2, 0 @ index s = 0
		cbnz r2, DashFlagSet
		mov freereg1, ' ' @ we print by putting desired char in freereg1 and calling PrintChar
		PrintLeftPadding:
		cmp r2, r3 @ while s < width - len, print a blank
		beq NowPrintTheString
			push { r0-r3 } @ alas we really ran out of registers at this rate 
			bl PrintChar @ we print width - len blanks on the left to achieve right justification of the field (the default)
			pop { r0-r3 }
			add r2, 1
			b PrintLeftPadding
		NowPrintTheString:
		mov r2, 0 @ loop index, again
		PrintStringHere:
		cmp r2, r1 @ while s < len, print the string
		beq FinishedFormatting @ done with this string
			ldr freereg1, [r0, r2] @ PrintChar(string[s])
			push { r0-r3 } @ alas we really ran out of registers at this rate 
			bl PrintChar @ PrintChar, an internal routine, prints the char at freereg1 for our convenience
			pop { r0-r3 }
			add r2, 1
			b PrintStringHere
	DashFlagSet: @ left justify the field within the field width (switches the order of blanks & field, really)
		cmp r2, r1 @ while s < len, print the string
		beq PrintPaddingOnTheRight @ done with this string
			ldr freereg1, [r0, r2] @ PrintChar(string[s])
			push { r0-r3 } @ alas we really ran out of registers at this rate 
			bl PrintChar
			pop { r0-r3 }
			add r2, 1
			b DashFlagSet
		PrintPaddingOnTheRight:
		mov freereg1, ' ' @ we print by putting desired char in freereg1 and calling PrintChar
		mov r2, 0 @ loop counter s = 0
		DoPrintPaddingOnTheRight: @ assembly language is a source of gratuitous pain
		cmp r2, r3 @ while s < width - len, print a blank
		beq NowPrintTheString
			push { r0-r3 } @ alas we really ran out of registers at this rate 
			bl PrintChar @ we print width - len blanks on the left to achieve right justification of the field (the default)
			pop { r0-r3 }
			add r2, 1
			b FinishedFormatting @ yes, we are finished with this string
	ProcessNumber: @ all other cases (not %, s, c, n) are numbers to be formatted 













		mov r2, 0 @ sign = positive
		ldr freereg2, [sp, lengthspec]
		tst freereg2, -4 @ determine how many words of memory are occupied by number in array at r0
		itee eq @ calculate ceil(lengthspec/4) so that we know how many words are in this number that r0 points to
		lsreq freereg2, 2
		lsrne freereg2, 2
		addne freereg2, 1
		cmp r3, 'd' @ if specifier == 'd' check sign. subsequent code works with unsigned numbers
		bne MostAssuredlyAPositiveNumber
		ldr r3, [sp, lengthspec] @ the number is stored in r0 as a vector of lengthspec bytes
		sub r3, 1 		
		ldrb r2, [r0, r3] @ check the most significant bit (sign) of our number
		tst r2, 128 @ zero iff msb of value[lengthspec-1] is clear
		it eq
		moveq r2, 1 @ sign = negative
		bleq TwosComplement
	MostAssuredlyAPositiveNumber:








	FinishedFormatting:
		bl ResetState @ set the format string reading state machine back to normal

FinishedReadingFormatString:
	cbnz regvar_state, FormatStringPrematurelyEnded @ if state != readformatstr // readformatstr==0
	cmp regvar_buffercount, 0
	ble FinishedPrintf @ if buffercount > 0 must flush the remaining characters to outputfunc
	ldr r0, =Buffer
	mov r1, 0
	str r1, [r0, regvar_buffercount] @ buffer[buffercount]
	ldr r1, [sp, outputfunc]
	blx r1 @ call outputfunc(buffer) // BIT 0 ?????????
FinishedPrintf:
add sp, stackframesize
pop { r0-r12, lr }
ldr r0, [sp, printedchars] @ printf returns number of characters printed
add r0, regvar_buffercount @ r0 = printedchars = printedchars + buffercount
mov pc, lr


@  !! ERROR CONDITIONS !! 

IllegalFormatSpecifier:
	add sp, stackframesize
	pop { r0-r12, lr }
	ldr r0, =IllegalFormatSpecifierMsg
	str r0, [sp] @ pointer to error message at sp
	mov r0, -1 @ return -1 for error
mov pc, lr
IllegalFormatSpecifierMsg: .asciz "Error: format string ended in the middle of a format specifier\n"

FlagsNotInUseWithSpecC:
add sp, stackframesize
	pop { r0-r12, lr }
	ldr r0, =FlagsNotInUseWithSpecC
	str r0, [sp] @ pointer to error message at sp
	mov r0, -1 @ return -1 for error
mov pc, lr
FlagsNotInUseWithSpecC: .asciz "Error: the '+', ' ', '0', '#' flags not in use with c and s specifiers\n"

FlagAlreadySet:
	add sp, stackframesize
	pop { r0-r12, lr }
	ldr r0, =FlagAlreadySetMsg
	str r0, [sp] @ pointer to error message at sp
	mov r0, -1 @ return -1 for error
mov pc, lr
FlagAlreadySetMsg: .asciz "Error: repeated flags in format specifier\n"

FormatStringPrematurelyEnded:
	add sp, stackframesize
	pop { r0-r12, lr }
	ldr r0, =FormatStringPrematurelyEndedMsg
	str r0, [sp] @ pointer to error message at sp
	mov r0, -1 @ return -1 for error
mov pc, lr
FormatStringPrematurelyEndedMsg: .asciz "Error: format string ended in the middle of a format specifier\n"


@ HELPERS

ResetState: @ resets the string reader to its 'normal state'
	mov r3, 0 @ a bunch of them are initialized to zero
	str r3, [sp, flags1]
	str r3, [sp, flags2] @ all the flags are initially unset
	str r3, [sp, specifier] @ ascii value of specifier
	str r3, [sp, width] @ no information on format specifiers read so far
	mov r3, 4
	str r3, [sp, lengthspec] @ how many bytes will specified number have (default: 4 bytes)
	mov regvar_state, readformatstr @ go back to reading the format string
mov pc, lr

PrintChar: @ internal to printf. freereg1 => character to be printed, clobbers r0, r1.
push { lr }
	cmp regvar_buffercount, buffersize @ if buffercount == buffersize
	bne StillSpaceInBuffer
	ldr r0, =Buffer @ must be flushed out, it's full
	ldr r1, [sp, outputfunc]
	blx r1 @ call outputfunc(buffer) WHAT ABOUT BIT[0] !!!!!!!!!!!!!!!! @@@@
	mov regvar_buffercount, 0 @ buffercount=0
	ldr r1, [sp, printedchars]
	add r1, buffersize
	str r1, [sp, printedchars] @ printedchars = printedchars + buffersize
StillSpaceInBuffer:
	ldr r0, =Buffer
	str freereg1, [r0, regvar_buffercount] @ buffer[buffercount] = character to be printed
	add regvar_buffercount, 1 @ buffercount++
pop { pc }

.data
OutputString: // keeps ascii characters while processing before printout
.rept 64
	.byte 0
.endr

Arg_Or_Values: // keeps values of arguments fetched from the argument string, and value calculated if using register values as the argument (that is, not a memory value)
.rept 16
	.byte 0
.endr

Buffer: // buffer that stores the string to be passed to outputfunc
.rept buffersize+1
	.byte 0
.endr

DigitsLookup:
.byte '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'A', 'B', 'C', 'D', 'E', 'F'

FlagsBranchTable: @ streamlines the code. obsviously not essential
.rept ' ' @ fill up to space
	.byte (NoFlags-HandleDashFlag)/2
.endr
.byte (HandleSpaceFlag-HandleDashFlags)/2
.rept '#'-' '-1 @ fill between space and pound
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
.byte 0 @ handle dash flag
.rept '0'-'-'-1 @ fill between zero and dash
	.byte (NoFlags-HandleDashFlag)/2
.endr
.byte (HandleZeroFlag-HandleDashFlag)/2
.rept 255 - '0' @ fill rest of table
	.byte (NoFlags-HandleDashFlag)/2
.endr

ReadFormatSpecifierBranchTable:
	
.rept '%' @ fill the table up to '%'
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
.byte (ReadUnsignedDecimal-ReadPercent)/2
.rept 'x' - 'u' - 1
	.byte (IllegalFormatSpecifier-ReadPercent)/2
.endr
.byte (ReadUnsignedHex-ReadPercent)/2
.rept 255 - 'x'
	.byte (IllegalFormatSpecifier-ReadPercent)/2
.endr




