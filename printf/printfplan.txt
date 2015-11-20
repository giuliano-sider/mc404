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

			readformatstr	readflags	readwidth    readlength    readspecifier 		TABLE_ENTRY (trampoline)

		\0	FinishPrintf	Error0														HandleNullByte
space ' '	IncrPrintChar   SpaceFlag   ErrorChar                                   	HandleSpace
		#	IncrPrintChar   PoundFlag   ErrorChar                                   	HandlePound
		%	BRFSpecifier    TPSpecifier                                             	HandlePercent
		*	IncrPrintChar               WidthArg     ErrorChar                      	HandleStar
		+   IncrPrintChar   PlusFlag    ErrorChar                                   	HandlePlus
		-	IncrPrintChar   DashFlag    ErrorChar                                   	HandleDash
		0	IncrPrintChar   NaughtFlag  RdWidthNum   RdLenNum      ErrorChar        	HandleNaught
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
		h   IncrPrintChar                            SetLengthH    ErrorChar        	HandleLH
		i   IncrPrintChar                                          SignedDecimalSpecifier
		l   IncrPrintChar                            SetLengthL    ErrorChar        	HandleLH
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











	Ano(u)ther catalog(o) of states: (whynot) ((for the argument string))
		.equ matchleftbracket, 0
		.equ matcharg, 1
		.equ matchsign, 2
		.equ matchshift, 3
		.equ matchrightbracket, 4
		.equ matchend, 5

	Special characters:
		\0 -> 
		(ok, a text editor wasn't made for this: excel chart)
	Table:
		noteworthy characters \ state

			matchleftbracket	matcharg	 matchsign    matchshift    matchrightbracket		matchend			TABLE

	   \0   Error0              Error0       IsBracketClosed IsBracketClosed IsBracketClosed  IsBracketClosed       ---
		[	OpenBracket 		ErrorCharArg ErrorCharArg ErrorCharArg  ErrorCharArg        ErrorCharArg            ---
		]	ErrorCharArg        ErrorCharArg CloseBracket CloseBracket  CloseBracket        ErrorCharArg            ArgHandleRightBracket
		,	Error0              Error0       IsBracketClosed IsBracketClosed IsBracketClosed  IsBracketClosed       ---
		+   ErrorCharArg        ErrorCharArg SetPlusSign  ErrorCharArg  ErrorCharArg        ErrorCharArg            --- 
		-   ErrorCharArg        ErrorCharArg SetMinusSign ErrorCharArg  ErrorCharArg        ErrorCharArg            ---
		l   ArgLReg             ArgLReg      ErrorCharArg SetLeftShift  ErrorCharArg        ErrorCharArg            ArgHandleL 
		s   ArgSReg             ArgSReg      ErrorCharArg ErrorCharArg  ErrorCharArg        ErrorCharArg            ---
		r   ArgReg              ArgReg       ErrorCharArg ErrorCharArg  ErrorCharArg        ErrorCharArg            ---
		p   ArgPReg             ArgPReg      ErrorCharArg ErrorCharArg  ErrorCharArg        ErrorCharArg            ---
		0   HexOrOctalArg       HexOrOctalArg ErrorCharArg ErrorCharArg ErrorCharArg        ErrorCharArg            ---
		1   DecimalArg          DecimalArg   ErrorCharArg ErrorCharArg  ErrorCharArg        ErrorCharArg            ---
		2
		3
		4
		5
		6
		7
		8
		9   DecimalArg          DecimalArg   ErrorCharArg ErrorCharArg  ErrorCharArg        ErrorCharArg            ---
(whitespace) AbsorbWSP																						        AbsorbWSP
	OTHER  ErrorCharArg 																					        ErrorCharArg
		

		FiniArgs: 
			goes to matchend, really, a state where only whitespace may be consumed until reaching a comma or \0.
		IsBracketClosed: 
			Checks if bracket was closed (in case it was ever opened!) Then finishes up the function.
		CloseBracket:
			Closes bracket and goes to FiniArgs
		
		L: link register, logical shift left
		S: sp
		P: pc 
		0: start of octal or hex constant (rest of the constant 'asynchronously absorbed')
		1-9: start of decimal constant
		R: start of register

Abbrevs
	Error0: PrematurelyFinishedArgumentString
	ErrorCharArg: 
		loads formatstr[i] in the middle of an error message, unwinds printf stack, loads message in sp, return -1.


	PrematurelyFinishedArgumentStringMsg:
		.asciz "Error: argument string terminated in the middle of an argument specifier\n"
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



