Pseudo Code for the non bastardized version of the printf_baremetal state machine:


int printf_baremetal ( int (*outputfunc) (const char *) ,  const char *formatstr, const char *argstr )

	// branch on character. then branch on state (nice short little table)

	Catalog(ue) of states: ((for the format string))
		.equ readformatstr, 0
		.equ readflags, 1
		.equ readwidth, 2
		// readwidthnumber @ read the number 'asynchronously' instead (gobble it up when you detect a number in the field. simpler code that way. have a function 'ReadDecimalNumberFromString')
		.equ readlength, 3
		// readlengthnumber @ read the number 'asynchronously' instead (gobble it up when you detect a number in the field. simpler code that way. have a function 'ReadDecimalNumberFromString')
		.equ readspecifier, 4

	
		(ok, a text editor wasn't made for this: excel chart)
	Table:

		noteworthy characters \ state

			readformatstr	readflags	readwidth    readlength    readspecifier 		TABLE_ENTRY

		\0	FinishPrintf	Error0														HandleNullByte
		%	BRFSpecifier    TPSpecifier                                             	HandlePercent
		+   IncrPrintChar   PlusFlag    ErrorChar                                   	HandlePlus
		-	IncrPrintChar   DashFlag    ErrorChar                                   	HandleDash
space ' '	IncrPrintChar   SpaceFlag   ErrorChar                                   	HandleSpace
		#	IncrPrintChar   PoundFlag   ErrorChar                                   	HandlePound
		*	IncrPrintChar               WidthArg     ErrorChar                      	HandleStar
		l   IncrPrintChar                            SetLength     ErrorChar        	HandleLH
		h   IncrPrintChar                            SetLength     ErrorChar        	HandleLH
		0	IncrPrintChar   ZeroFlag    RdWidthNum   RdLenNum      ErrorChar        	HandleZero
		1	IncrPrintChar               RdWidthNum   RdLenNum      ErrorChar        	HandleDigit 
		2	IncrPrintChar               RdWidthNum   RdLenNum      ErrorChar    
		3	IncrPrintChar               RdWidthNum   RdLenNum      ErrorChar
		4	IncrPrintChar               RdWidthNum   RdLenNum      ErrorChar
		5	IncrPrintChar               RdWidthNum   RdLenNum      ErrorChar
		6	IncrPrintChar               RdWidthNum   RdLenNum      ErrorChar
		7	IncrPrintChar               RdWidthNum   RdLenNum      ErrorChar
		8	IncrPrintChar               RdWidthNum   RdLenNum      ErrorChar
		9	IncrPrintChar               RdWidthNum   RdLenNum      ErrorChar        	HandleDigit
		c   IncrPrintChar                                          CharSpecifier 
		d   IncrPrintChar                                          SignedDecimalSpecifier
		i   IncrPrintChar                                          SignedDecimalSpecifier
		n   IncrPrintChar                                          NSpecifier
		o   IncrPrintChar                                          OctalSpecifier
		p   IncrPrintChar                                          PointerSpecifier
		s   IncrPrintChar                                          StringSpecifier
		u   IncrPrintChar                                          UnsignedDecimalSpecifier
		x   IncrPrintChar                                          HexSpecifier
		X   IncrPrintChar                                          HexCapsSpecifier
	OTHER   IncrPrintChar                                          ErrorChar

Abbrevs
	Error0: PrematurelyFinishedFormatString
	ErrorChar: 
		loads formatstr[i] in the middle of an error message, unwinds printf stack, loads message in sp, return -1.
	IncrPrintChar: IncrementI_AndPrintChar
	BRFSpecifier: BeginReadingFormatSpecifier
	TPSpecifier: TreatPercentSpecifier


	Auxiliary functions for the format string reading machine:

	UnwindPrintfOnError: @ unwind printf's stack, load error message at sp, return -1 in r0
	PrintBuffer @ prints out whatever is in our print buffer
	UnwindPrintfSuccess @ unwinds printf's stack, returns printedchars in r0
	PrintChar 
		@ prints character available in r0 (consider macro implementation with parameterized input/output/clobber)


printf_baremetal: @ r0: outputfunc, r1: formatstr, r2: argumentstr

.equ BUFFERSIZE, 1024 
	@ actual size of buffer that holds chars before they go out to outputfunc
.equ MAXNUMBYTESIZE, BUFFERSIZE
	@ maximum number of bytes a number (in memory) can have and still be print-formatted by
	@ our printf (given in the "lengthspec" field of the format specifier)
.equ OUTPUTSTRINGSIZE, 4*MAXNUMBYTESIZE @ big enough to hold ceil(MAXNUMBERSIZE*8/3) octal digits
	@ this buffer holds the formatted print number's ascii codes before it is printed

push { r0-r12, lr } @ we keep track of sp. lr is pc. original lr is not available, clobbered during branch and link.
	
	mov regvar_i, 0 @ index for reading the format string
	mov regvar_j, 0 @ index for reading the argument string
	mov regvar_printedchars, 0 @ zero chars printed so far
	mov regvar_buffercount, 0 @ zero characters in the print buffer so far

ReadFormatString:
	ldrb regvar_char, [regvar_formatstr, regvar_i] @ char = formatstr[i]
	tbb [regvar_asciitable, regvar_char] @ branch by ascii character to the right handlers

	tbb [pc, regvar_state] @ (\0)
	HandleNullByte:
	.byte (FinishPrintf-HandleNullByte)/2
	.byte (PrematurelyFinishedFormatString-HandleNullByte)/2
	.byte (PrematurelyFinishedFormatString-HandleNullByte)/2
	.byte (PrematurelyFinishedFormatString-HandleNullByte)/2
	.byte (PrematurelyFinishedFormatString-HandleNullByte)/2
	.byte 0

	FinishPrintf: @ (\0, readformatstr)
		bl PrintBuffer @ prints out whatever is in our print buffer
		mov regvar_returnval, regvar_printedchars
		bl UnwindPrintfSuccess @@@@
	PrematurelyFinishedFormatString: @ (\0, not readformatstr)
		ldr regvar_errmsg, =PrematurelyFinishedFormatStringMsg
		bl UnwindPrintfOnError @ unwind printf's stack, load error message at sp, return -1


	tbb [pc, regvar_state] @ (%)
	HandlePercent:
	.byte (BeginReadingFormatSpecifier-HandlePercent)/2
	.byte (TreatPercentSpecifier-HandlePercent)/2
	.byte (TreatPercentSpecifier-HandlePercent)/2
	.byte (TreatPercentSpecifier-HandlePercent)/2
	.byte (TreatPercentSpecifier-HandlePercent)/2
	.byte 0

	BeginReadingFormatSpecifier: @ (%, readformatstr)
		mov regvar_flags, 0 @ default: all flags clear (' ', '#', '+', '-', '0')
		mov regvar_width, 0 @ default: no minimum field width
		mov regvar_length, 4 @ default: 4 byte numbers (when dealing with numbers, this is relevant)
		add regvar_i, 1 @ consume the '%'
		mov regvar_state, readflags @ begin looking at (optional) flags
		b ReadFormatString 
		@ break
	TreatPercentSpecifier: @ (%, not readformatstr) 
		// optional error/warning check for spurious format modifiers
		mov regvar_state, readformatstr @ go back to reading and printing characters.
		@ Fall through!
	IncrementI_AndPrintChar:
		add regvar_i, 1 
		@ fall through
	PrintCharacter:
		bl PrintChar(r0 === regvar_char === formatstr[i]) @ print the character loaded in r0
		b ReadFormatString 
		@ break




pop { r0-r12, pc }






@ !! Error Messages !!

	PrematurelyFinishedFormatStringMsg:
		.asciz "Error: format string terminated in the middle of a format specifier\n"
	.align
	LengthModifierTooLongMsg: 
		.asciz "Length modifier can be no longer than 1024 bytes\n"
	.align
	IllegalFormatSpecifierMsg: 
		.asciz "Error: invalid format specifier\n"
	.align
	UselessInfoWithPercentSpecifierMsg: 
		.asciz "Error: format string ended in the middle of a format specifier\n"
	.align
	FlagsNotInUseWithSpecCandSMsg:
		.asciz "Error: the '+', ' ', '0', '#' flags not in use with c and s specifiers\n"
	.align
	InvalidLengthModifierMsg: 
		.asciz "Error: invalid length modifier in format string"
	.align
	InvalidLengthModifierWithStringandCharMsg:
		.asciz "Error: length modifiers are not used with char and string specifiers\n"
	.align
	FlagAlreadySetMsg: 
		.asciz "Error: repeated flags in format specifier\n"
	.align
	InvalidModifiersWithSpecifierNMsg: 
		.asciz "Error: format specifier n doesn't take any additional parameters\n"
	.align
	PlusAndSpaceFlagsBothSetMsg: 
		.asciz "Error: Plus and Space flags both set\n"
	.align
	
	SyntaxErrorInArgumentStringMsg: 
		.asciz "Error: syntax error in argument string\n"
	.align
	MissingArgumentsMsg: 
		.asciz "Error: missing necessary arguments in the argument string\n"
	.align
	MisplacedRightBracketMsg: 
		.asciz "Error: misplaced right bracket in the argument string\n"
	.align
	MisplacedPlusSignMsg: 
		.asciz "Error: misplaced plus sign in the argument string\n"
	.align
	HandleOtherCharacterMsg: 
		.asciz "Error: stray character in argument string\n" @ typical assembler (crap compiler) error
	.align
	LinkRegisterInvalidMsg: 
		.asciz "Error: Link Register is inaccessible to printf, clobbered by branch and link\n"
	.align
	InvalidRegisterMsg: 
		.asciz "Error:Invalid Register in the argument string\n"
	.align
	MisplacedLeftBracketMsg: 
		.asciz "Error: misplaced left bracket in the argument string\n"
	.align
	MisplacedSignMsg: 
		.asciz "Error: misplaced sign in the argument string\n"
	.align
	MissingClosingBracketMsg: 
		.asciz "Error: missing closing bracket in argument string\n"
	.align








	Ano(u)ther catalog(o) of states: (whynot) ((for the argument string))
		matchleftbracket
		matcharg
		matchsign
		matchshift
		matchrightbracket
		matchend

	Special characters:
		\0 -> 
		(ok, a text editor wasn't made for this: excel chart)
	Table:
		noteworthy characters \ state

			matchleftbracket	matcharg	matchsign    matchshift    matchrightbracket	matchend

	   \0   Error0              Error0      FiniArgs     FiniArgs      IsBracketClosed      FiniArgs    
		[
		]	
		,
		+
		-
		l
		s
		r
		p
		0
		1
		2
		3
		4
		5
		6
		7
		8
		9
(whitespace)
	OTHER
		

Abbrevs
	Error0: PrematurelyFinishedArgumentString
	ErrorChar: 
		loads formatstr[i] in the middle of an error message, unwinds printf stack, loads message in sp, return -1.


	PrematurelyFinishedArgumentStringMsg:
		.asciz "Error: argument string terminated in the middle of a format specifier\n"
	.align




	switch (formatstr[i])

		case \0
			if state == readformatstr @ ok: we finished reading the string
				goto FinishPrintf
			else @ bad: finished in the middle of a specifier
				error "premature end to the format string"
			break

		case %
			if state == readformatstr
				InitializeDefaultSpecifiers:
					flags.+ = flags.' ' = flags.# = flags.0 = flags.- = false
					width = 0
					length = 4
				state = readflags
				i++

			else if state == readformatspecifier
				// optional: check errors for unnecessary specifiers associated with %
				Print ( '%' )
				state = readformatstr
				i++
			else
				error "stray % character in format"



