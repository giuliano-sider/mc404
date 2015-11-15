
@ collection of macros/aux functions for the printf project 


.macro PrintFormattedNumberPrefixes Rregvar_flags Rregvar_digitlookup
@ prints 0 or 0x prefixes if corresponding flags are set. prints ' ', +, or - if corresponding flags are set.
push { r0 }
	tst \Rregvar_flags, (1<<10) @ do we print a ' ' prefix?
	itt ne @ print a ' ' prefix flag is set 
	movne r0, ' '
	blne PrintChar

	tst \Rregvar_flags, (1<<11) @ do we print a + prefix?
	itt ne @ print a + prefix flag is set 
	movne r0, '+'
	blne PrintChar

	tst \Rregvar_flags, (1<<12) @ do we print a - prefix?
	itt ne @ print a - prefix flag is set 
	movne r0, '-'
	blne PrintChar

	tst \Rregvar_flags, (1<<8) @ do we print a 0 prefix?
	itt ne @ print a 0 prefix flag is set 
	movne r0, '0'
	blne PrintChar

	tst \Rregvar_flags, (1<<9) @ do we print a x|X prefix?
	itt ne @ print a x|X prefix flag is set 
	ldrbne r0, [\Rregvar_digitlookup, 16] @ last position in hex digit lookup table is x or X according to convenience
	blne PrintChar
pop { r0 }
.endm

/*.macro UnsignedCeil Rdest, Rsrc, imm_power @ Rdest = ceil(Rsrc/2^imm_power). Note: Rdest must be different from Rsrc
	
	lsr \Rdest, \Rsrc, \imm_power
	cmp \Rsrc, \Rdest, lsl \imm_power @ zero iff the imm_power lsb's of Rsrc are naught.
	it ne
	addne \Rdest, 1
	
.endm*/
.macro UnsignedCeil Rdest, Rsrc, imm_power @ Rdest = ceil(Rsrc/2^imm_power). Note: Rdest must be different from Rsrc
	
	.equ the_power_of_two, 1
	.rept \imm_power
		.equ the_power_of_two, 2*the_power_of_two
	.endr
	.equ the_power_of_two, the_power_of_two-1 @ compute (2^imm_power - 1)

	add \Rdest, \Rsrc, the_power_of_two
	lsrs \Rdest, \imm_power @ sets flags

.endm



LoadRegisterValue: @ Blessed be the non clobberers, for theirs is the kingdom of silicon
@ in : r0 -> number of register whose value must be loaded.
@ out: r0- > loads the contents of user's register.
push { r1, lr }
	cmp r0, 16
	itt hs
	addhs sp, 8 @ unwind this function's stack (assembly => not a healthy way to program)
	bhs InvalidRegisterSpecified @ register must be in the range 0-15
	cmp r0, 14
	itt eq
	addeq sp, 8 @ unwind this function's stack (assembly => not a healthy way to program)
	beq TriedToUseLinkRegister @ user's link register inaccessible
	ldr r1, =TheUserStack
	ldr r0, [r1, r0, lsl 2] @ fetch the register from where printf saved it in TheUserStack static struct
pop { r1, pc }

StringLength: @ string -> r0 ... r0->string, r1 -> string length.
push { r2, lr }
mov r1, 0 @ initial length
DoStringLengthLoop:
	ldrb r2, [r0, r1]
	cbz r2, FinishedStringLength
	add r1, 1
	b DoStringLengthLoop
FinishedStringLength: 
pop { r2, pc }

ParseStringAsDecimalNumber: @ no clobber
	@ in: string -> r0, index-> r1 
	@ out: r0 -> number read, r1 -> index of first non (decimal) digit

push { r2, r3, r4, lr } @ henceforth, clobbering registers shall be punishable in the 8th circle of heck
	mov r2, 0 @ number initialized to zero
	mov r4, 10 @ the radix to be used in multiply accumulate
ParseAnotherDecimalDigit:
	ldrb r3, [r0, r1] @ char = string[i]
	sub r3, '0' @ turn it into an actual decimal digit
	cmp r3, 10 @ if char > '9' || char < '0', then return number
	ittt cc @ higher|same === carry set. lower === carry clear
	mlacc r2, r2, r4, r3 @ number = number * 10 + (char - '0')
	addcc r1, 1 @ index++
	bcc ParseAnotherDecimalDigit @ if it wasn't a digit to begin with, fall through to exit.
ParseStringAsDecimalNumberFinished:
	mov r0, r2 @ return number
	@ r1 has new reading index for the string
pop { r2, r3, r4, pc }

ParseStringAsOctalNumber: @ no clobber
	@ in: string -> r0, index-> r1 
	@ out: r0 -> number read, r1 -> index of first non (decimal) digit

push { r2, r3, lr } @ henceforth, clobbering registers shall be punishable in the 8th circle of heck
	mov r2, 0 @ number initialized to zero
ParseAnotherOctalDigit:
	ldrb r3, [r0, r1] @ char = string[i]
	sub r3, '0' @ turn it into an actual digit
	cmp r3, 8 @ if char >= '8' || char < '0', then return number
	ittt cc @ higher|same === carry set. lower === carry clear
	addcc r2, r3, r2, lsl 3 @ number = number * 8 + (char - '0')
	addcc r1, 1 @ index++
	bcc ParseAnotherOctalDigit @ if it wasn't a digit to begin with, fall through to exit.
ParseStringAsOctalNumberFinished:
	mov r0, r2 @ return number
	@ r1 has new reading index for the string
pop { r2, r3, pc }

ParseStringAsHexNumber: @ no clobber
	@ in: string -> r0, index-> r1 
	@ out: r0 -> number read, r1 -> index of first non (decimal) digit

push { r2, r3, lr } @ henceforth, clobbering registers shall be punishable in the 8th circle of heck
	mov r2, 0 @ number initialized to zero
ParseAnotherHexDigit:
	ldrb r3, [r0, r1] @ char = string[i]
	sub r3, '0' @ turn it into an actual digit
	cmp r3, 10 @ if char > '9' || char < '0', then check if it's in [ABCDEFabcdef]
	bcc HexCharToNumber @ higher|same === carry set. lower === carry clear
	sub r3, 'A' - '0' @ maps A->0, B->1 ... F->5
	cmp r3, 6 @ if higher/same as 6, could still be in [abcdef]
	itt lo
	addlo r3, 10
	blo HexCharToNumber 
	sub r3, 'a' - 'A' @ maps a->0, ... f->5
	cmp r3, 6 @ if higher/same as 6, it's not a hex digit
	bhs ParseStringAsHexNumberFinished
	add r3, 10 @ turn 'a', 'b', ... into a proper value.
HexCharToNumber: @ what we have in r3 is the actual numerical value of the digit
	add r2, r3, r2, lsl 4 @ number = number * 16 + (digitread)
	add r1, 1 @ index++
	b ParseAnotherHexDigit @ if it wasn't a digit to begin with, fall through to exit.
ParseStringAsHexNumberFinished:
	mov r0, r2 @ return number
	@ r1 has new reading index for the string
pop { r2, r3, pc }


ObtainDigitsFromNumber: @ pointer to number -> r0, word size of number -> r1, radix -> r2, digitlookuptable -> r3... 
	@ returns r0 -> ptr to string with digits (in reverse order), r1 -> size of string
@ note: r3 points to digit indexed table of ascii characters corresponding to digits
push { r4-r7 , lr } @ strict no clobber policy within printf.
@ obtain the digits of number of size words by successively dividing by radix. The ascii digit to be written to the output string
@ buffer is determined by the lookup table, indexed by the digits themselves.
regvar_outputstring .req r4
regvar_outputstringlength .req r5
regvar_ODFN_radix .req r6
regvar_ODFN_aux .req r7 @ no doc on how these .req work, so better safe than sorry
	ldr regvar_outputstring, =OutputString @ this is the buffer where the number is kept as a string of ascii characters
	mov regvar_outputstringlength, 0 @ outputstringlength = 0
	mov regvar_ODFN_radix, r2
	@mov regvar_lookuptable, r3 
ExtractDigitsFromNumber:
	bl IsNumberZero @ number pointer -> r0, num size (words) -> r1
	cmp r2, 0 @ it echoes r0 and r1, returns zero in r2 iff the number is zero
	beq ExtractedAllTheDigits 
	mov r2, regvar_ODFN_radix
	bl UDivVectorByInt16 @ divides the ((unsigned) potentially large but word aligned) number by an 16bit divisor.
@ quotient clobbers the old number.  size (in words) of the number is adjusted. 
@ in: r0 -> number pointer, r1 -> num size (in words), r2 -> divisor. 
@ out: r0 -> number pointer, r1 -> (updated) num size, r2 -> remainder
	ldrb regvar_ODFN_aux, [r3, r2] @ char = lookuptable[remainder]
	strb regvar_ODFN_aux, [regvar_outputstring, regvar_outputstringlength] @ outputstring[outputstringlength] = char 
	add regvar_outputstringlength, 1 @ outputstring is one character bigger now
	b ExtractDigitsFromNumber
ExtractedAllTheDigits:
	strb r2, [regvar_outputstring, regvar_outputstringlength] @ end string with null byte. see above: r2 leaves loop with zero.
@ note that the number zero leads to an empty string.
	mov r2, regvar_ODFN_radix @ since when is assembly language programming a good idea
	mov r1, regvar_outputstringlength @ we return the length of the string in r1,
	mov r0, regvar_outputstring @ and the string itself in r0.
pop { r4-r7 , pc }

UDivVectorByInt16:
@ descr: divides the ((unsigned) potentially large but word aligned and little endian) number by a 16bit divisor.
	@ quotient clobbers the old number. size (in words) of the number is adjusted.
@ in: r0 -> number pointer, r1 -> num size (in words), r2 -> divisor @ assumes divisor is nonzero.
@ out: r0 -> number pointer, r1 -> (updated) num size, r2 -> remainder
regvar_hwindex .req r3
regvar_remainder .req r4
regvar_hwaddr .req r5
regvar_isitleadingzero .req r6 @ facilitates our adjustment of the number size (in one pass)
regvar_dividend .req r7
regvar_quotient .req r8
push { r3-r8 , lr }
	lsl regvar_hwindex, r1, 1 @ num of halfwords of the number array (one past the end)  
	mov regvar_remainder, 0 @ remainder initialized to zero
	add regvar_hwaddr, r0, r1, lsl 2 @ load hwaddr = number[numsize] (one past the end)
	mov regvar_isitleadingzero, 0 @ leading zero flag initialized to true. false is -1.
DoTheDivision:
	cmp regvar_hwaddr, r0 @ while hwaddr > r0 === base address
	beq DivisionIsDone @ if got to the (little) end of the number, we're finished
		ldrh regvar_dividend, [regvar_hwaddr, -2]! @ short int dividend = number[--hwindex]
		add regvar_dividend, regvar_dividend, regvar_remainder, lsl 16 @ dividend = dividend + remainder * 2^16
		udiv regvar_quotient, regvar_dividend, r2 @ r2 is the divisor (our radix)
		mls regvar_remainder, regvar_quotient, r2, regvar_dividend @ remainder = dividend - quotient*divisor
		strh regvar_quotient, [regvar_hwaddr] @ *hwaddr = quotient 
			@ we clobber the number with the quotient of the division for our convenience
		teq regvar_isitleadingzero, regvar_quotient @ if both are zero, decrease halfword size of number
		ite eq @ if we have another (new) leading zero, decrement the num of halfwords of this number
		subeq regvar_hwindex, 1
		movne regvar_isitleadingzero, -1 @ else set the isitleadingzero flag to false (we detected a non zero)
		b DoTheDivision
DivisionIsDone:
	UnsignedCeil r1, regvar_hwindex, 1 @ ceil(hwindex/2^1), the new size of number in words
	cmp r1, 0
	it eq @ if num size is zero (number itself is zero), we actually want number to be 1 word long
	moveq r1, 1
	mov r2, regvar_remainder
pop { r3-r8 , pc }


IsNumberZero: @ number -> r0, number word size -> r1 ... 
							@ r0 and r1 -> echo. r2 -> zero if number is zero, nonzero otherwise
							 
	cmp r1, 1 @ if numsize!=1, then number is not zero
	bne ReturnNonZero
	ldr r2, [r0] @ load the first (and only) word of the number 
mov pc, lr @ returns zero in r2 iff number is zero @ cbnz r2, ReturnNonZero @ it's not zero 
ReturnNonZero:
	mov r2, 1 @ non zero value since the number is not zero
mov pc, lr


CopyNumberToBuffer: @ (user provided/ObtainValueFromNextArg provided) pointer to number -> r0, number byte length -> r1 ... 
					@ returns: r0 -> internal buffer ptr, r1 -> buffer word size
push {  r2-r4 , lr } @ strict no clobber policy within printf. 
	@ note: number must be positive (or potentially unsigned): no sign extension done for non word-aligned numbers that are read.
	ldr r4, =Number @ this is our internal buffer where we copy to.
	lsr r3, r1, 2 @ floor(numbytes/4)
	mov r2, 0
	str r2, [r4, r3, lsl 2] @ make sure there is a zero at
		@ (possibly one past) the end of the number in case it is not word aligned and there are extra bytes at the end.
	UnsignedCeil r3, r1, 2 @ r3 = Ceil(r1/2^2) number of words our number will have in the internal (private) buffer 
	//mov r2, r1 @ numsize bytes will be copied
CopyThoseBytesIntoNumber:
	cbz r1, CopiedToBuffer @ while there are bytes left to copy.
		sub r1, 1
		ldrb r2, [r0, r1] @ temp = number[--index]
		strb r2, [r4, r1] @ number[index] = temp
		b CopyThoseBytesIntoNumber
CopiedToBuffer:
	mov r0, r4 @ return pointer to number in internal buffer
	mov r1, r3 @ return size of number in words ( ceil(numbytes/4) )
pop { r2-r4 , pc }



Copy2sComplement: @ (user provided/ObtainValueFromNextArg provided) pointer to number -> r0, number byte length -> r1 ... 
						@ returns: r0 -> internal buffer ptr, r1 -> buffer word size
push {  r2-r4 , lr } @ strict no clobber policy within printf. 
@ note: number must be negative: no sign extension done for non word-aligned numbers that are read.
	ldr r4, =Number @ this is our internal buffer where we copy to.
	lsr r3, r1, 2 @ floor(numbytes/4)
	mov r2, 0
	str r2, [r4, r3, lsl 2] @ make sure there is a zero at the
		@ (possibly one past the) end of the number in case it is not word aligned and there are extra bytes at the end.
	UnsignedCeil r3, r1, 2 @ r3 = Ceil(r1/2^2) number of words our number will have in the internal (private) buffer 
	//mov r2, r1 @ numsize bytes will be copied
CopyComplThoseWordsIntoNumber:
	cbz r1, CopiedComplToBuffer @ while there are bytes left to copy.
		sub r1, 1
		ldrb r2, [r0, r1] @ temp = number[--index]
		mvn r2, r2 @ complement the bits
		strb r2, [r4, r1] @ number[index] = temp
		b CopyComplThoseWordsIntoNumber
CopiedComplToBuffer:
	mov r0, r4 @ return pointer to number in internal buffer
	mov r1, r3 @ return size of number in words ( ceil(numbytes/4) )
	mov r2, 0 @ we still need to add 1 to get a 2's complement
AddOne:
	ldr r3, [r0, r2, lsl 2]
	adds r3, 1 @ add one to the current word and change status flags.
	str r3, [r0, r2, lsl 2]
	add r2, 1 @ next word
	bcs AddOne @ while carry is set, add 1 to the succeeding word.
pop { r2-r4 , pc }


PrintStringInReverse: @ string -> r0, length -> r1 ... echoes r0, r1
push { r0-r2 , lr }
	mov r2, r0 @ string kept here
PrintStringInReverseLoop:
	cbz r1, FinishedPrintStringInReverse @ while index > 0 
		sub r1, 1
		ldrb r0, [r2, r1] @ print string[--index]
		bl PrintChar @ clobber protection provided
		b PrintStringInReverseLoop
FinishedPrintStringInReverse:
pop { r0-r2, pc }


PrintString: @ string -> r0 ... r0-> string (echo)
push { r0-r1, lr }
	mov r1, r0 @ keep the string here 
PrintStringLoop:
	ldrb r0, [r1]
	cbz r0, FinishedPrintString @ when we detect a null byte, bail
		bl PrintChar @ provides clobber protection
	b PrintStringLoop
FinishedPrintString:
pop { r0-r1, pc }


ObtainValueFromNextArg: 
	@ argstring -> r0, index -> r1, length -> r2 ... ptr_to_arg -> r0, newindex -> r1

	.equ matchleftbracket, 0
	.equ matcharg, 1
	.equ matchsign, 2
	.equ matchshift, 3
	.equ matchrightbracket, 4
	.equ matchend, 5

@push {  regvar_argchar, regvar_arg_asciitable, regvar_argstate , regvar_argflags, regvar_args, regvar_arg, 
	@	regvar_argscratch1, regvar_argscratch2, regvar_argscratch3, lr } 
push { r2-r8, lr }
regvar_argstr .req r0
regvar_argj .req r1
regvar_arglength .req r2
regvar_argchar .req r3
regvar_arg_asciitable .req r4
regvar_argstate .req r5
regvar_argflags .req r6
regvar_args .req r7
regvar_arg .req r8

regvar_argscratch1 .req r3 @ used at the end only
regvar_argscratch2 .req r4
regvar_argscratch3 .req r5

//.equ obtainvalue_stackframesize, 8

@ argflags: bit 0 (+ -), bit 1 (no [, [), bit 2 (no ], ]), 
	mov regvar_argstate, matchleftbracket @ initial state for reading the argument string.
	mov regvar_argflags, 0 @ no square brackets, default offset is positive
	mov regvar_arg, 0 @ read first argument 
	ldr regvar_args, =ArgValue @ store arguments here for subsequent calculation
	str regvar_arg, [regvar_args]
	str regvar_arg, [regvar_args, 4]
	str regvar_arg, [regvar_args, 8] @ initialize all 3 arguments to zero (default)
	ldr regvar_arg_asciitable, =ArgAsciiTable 

ReadArgumentString:

ldrb regvar_argchar, [regvar_argstr, regvar_argj] @ char = argumentstr[j]
tbh [regvar_arg_asciitable, regvar_argchar, lsl 1] @ branch by ascii character to the right handlers
OBFNABranchOnCharacter:
	
	ArgHandleLeftBracket: @ handle '[': if matchleftbracket, ok. otherwise error.
		cmp regvar_argstate, matchleftbracket
		bne ErrorCharArg @ catch all for invalid characters in argument string
	OpenBracket:
		orr regvar_argflags, (1<<1) @ flags.[ = true @ value to be obtained is a pointer
		add regvar_argj, 1 @ consume the '['
		mov regvar_argstate, matcharg @ now match the first argument
		b ReadArgumentString @ do loop

	ArgHandleRightBracket: @ handle ']': if matchsign, matchshift, or matchrightbracket ok. otherwise error.
@ matchleftbracket, 0; matcharg, 1; matchsign, 2; matchshift, 3; matchrightbracket, 4; matchend, 5.
		sub regvar_argstate, 2 @ subtract 2 and branch to error if higher or same than 3.
		cmp regvar_argstate, 3 @ now we can use a single branch (could have also used a branch table)
		bhs ErrorCharArg @ catch all for invalid characters in argument string
	CloseBracket:
		orr regvar_argflags, (1<<2) @ flags.] = true @ we've closed the square bracket and finished the arg spec except for possibly whitespace
		add regvar_argj, 1 @ consume the ']'
		mov regvar_argstate, matchend @ now find the end of this argument specification (\0, ",")
		b ReadArgumentString @ do loop

	ArgHandlePlus: @ handle +
		cmp regvar_argstate, matchsign @ if not this, then error
		bne ErrorCharArg @ invalid + placed in argument string.
	SetPositiveOffset:
		@ bic regvar_argflags, (1<<0) @ flags.+ = true @ offset is already positive by default
		add regvar_argj, 1 @ consume the '+'
		mov regvar_argstate, matcharg @ now match another argument.
		b ReadArgumentString @ do loop

	ArgHandleMinus: @ handle -
		cmp regvar_argstate, matchsign @ if not this, then error
		bne ErrorCharArg @ invalid - placed in argument string.
	SetNegativeOffset:
		orr regvar_argflags, (1<<0) @ flags.- = true @ offset is now considered negative
		add regvar_argj, 1 @ consume the '-'
		mov regvar_argstate, matcharg @ now match another argument.
		b ReadArgumentString @ do loop

	ArgHandleL: @ handle 'l'. could be 'lsl' or 'lr'
@ note the name decoration. separate assembly would solve this problem? are names internal to a module by default ("static") ? .global directive
		tbh [pc, regvar_argstate, lsl 1] @ (l) table branch cuts us some slack here
	ArgBranchOnStateForL:
		.hword (TriedToUseLinkRegister-ArgBranchOnStateForL)/2
		.hword (TriedToUseLinkRegister-ArgBranchOnStateForL)/2
		.hword (ErrorCharArg-ArgBranchOnStateForL)/2
		.hword (SetLeftShift-ArgBranchOnStateForL)/2
		.hword (ErrorCharArg-ArgBranchOnStateForL)/2
		.hword (ErrorCharArg-ArgBranchOnStateForL)/2

	SetLeftShift: @ must match 'lsl'
		add regvar_argj, 1 @ matched the 'l'
		ldrb regvar_argchar, [regvar_argstr, regvar_argj] @ read next character 
		cmp regvar_argchar, 's'
		bne ErrorCharArg
		add regvar_argj, 1 @ matched the 's'
		ldrb regvar_argchar, [regvar_argstr, regvar_argj] @ read next character 
		cmp regvar_argchar, 'l'
		bne ErrorCharArg
		add regvar_argj, 1 @ matched the 'l'. done matching.
		mov regvar_argstate, matcharg @ match another argument 
		b ReadArgumentString @ do loop

	ArgHandleS: @ could be stack pointer. if in matchleftbracket or matchargs, ok; otherwise, error.
		cmp regvar_argstate, matchsign
		bge ErrorCharArg @ must be matching an argument (register or constant). note that left bracket is optional.
		add regvar_argj, 1 @ matched the s 
		ldrb regvar_argchar, [regvar_argstr, regvar_argj] @ read next character 
		cmp regvar_argchar, 'p' @ must be p for sp 
		bne ErrorCharArg
		add regvar_argj, 1 @ ready to read the next character.
		push { r0 }
		mov r0, 13
		bl LoadRegisterValue @ loads the contents of user's register 13 (sp) in r0
		str r0, [regvar_args, regvar_arg] @ store register in its place in the argument vector
		pop { r0 }
		add regvar_arg, 1 @ read next argument
		add regvar_argstate, regvar_arg, matcharg @ current state is matcharg. 
			@ if arg==1, goes to matchsign. else if arg==2, goes to matchshift. else if arg==3, goes to matchrightbracket.
		b ReadArgumentString @ do loop

	ArgHandleP: @ could be program counter. if in matchleftbracket or matchargs, ok; otherwise, error.
		cmp regvar_argstate, matchsign
		bge ErrorCharArg @ must be matching an argument (register or constant). note that left bracket is optional.
		add regvar_argj, 1 @ matched the p
		ldrb regvar_argchar, [regvar_argstr, regvar_argj] @ read next character 
		cmp regvar_argchar, 'c' @ must be c for pc 
		bne ErrorCharArg
		add regvar_argj, 1 @ ready to read the next character.
		push { r0  }
		mov r0, 15
		bl LoadRegisterValue @ loads the contents of user's register 15 (pc) in r0
		str r0, [regvar_args, regvar_arg] @ store register in its place in the argument vector
		pop { r0 }
		add regvar_arg, 1 @ read next argument
		add regvar_argstate, regvar_arg, matcharg @ current state is matcharg. 
			@ if arg==1, goes to matchsign. else if arg==2, goes to matchshift. else if arg==3, goes to matchrightbracket.
		b ReadArgumentString @ do loop

	ArgHandleR: @ read a register in matchleftbracket or matcharg. otherwise: error
		cmp regvar_argstate, matchsign
		bge ErrorCharArg @ invalid 'r' in argument string 
		add regvar_argj, 1 @ consume the r
		push { r0 }
		bl ParseStringAsDecimalNumber @ string -> r0, index-> r1 ... r0 -> number read, r1 -> index of first non (decimal) digit
		@ new index (j) is in r1.
		bl LoadRegisterValue @ loads the contents of user's register in r0.
		str r0, [regvar_args, regvar_arg] @ store register in its place in the argument vector
		pop { r0 }
		add regvar_arg, 1 @ read next argument
		add regvar_argstate, regvar_arg, matcharg @ current state is matcharg. 
			@ if arg==1, goes to matchsign. else if arg==2, goes to matchshift. else if arg==3, goes to matchrightbracket.
		b ReadArgumentString @ do loop

	ArgHandleNaught: @ '0'. if matchleftbracket or matcharg, read octal/hex constant. if not, error.
		cmp regvar_argstate, matchsign
		bge ErrorCharArg @ invalid 'r' in argument string 
		add regvar_argj, 1 @ 0
		ldrb regvar_argchar, [regvar_argstr, regvar_argj] @ read next character 
		push { r0 }
		cmp regvar_argchar, 'x' @ if 'x' we must have a hex constant. if not, then octal.
		beq ItIsAHexConstant_ItIsSuchJoyToDecorateAssemblerLabels
		bl ParseStringAsOctalNumber @ remember, if digit string is empty (first char read is not a digit), answer comes out zero.
		b NowStoreTheConstant_OhWhatJoyItIsToRideAnOpenSled
	ItIsAHexConstant_ItIsSuchJoyToDecorateAssemblerLabels:
		add regvar_argj, 1 @ advance beyond the 'x'
		bl ParseStringAsHexNumber
	NowStoreTheConstant_OhWhatJoyItIsToRideAnOpenSled:
		str r0, [regvar_args, regvar_arg] @ store hex/octal constant in its place in the argument vector
		pop { r0 }
		add regvar_arg, 1 @ read next argument
		add regvar_argstate, regvar_arg, matcharg @ current state is matcharg. 
			@ if arg==1, goes to matchsign. else if arg==2, goes to matchshift. else if arg==3, goes to matchrightbracket.
		b ReadArgumentString @ do loop

	ArgHandleDigits: @ '[1-9]'. if matchleftbracket or matcharg, read decimal constant. if not, error.
		cmp regvar_argstate, matchsign
		bge ErrorCharArg @ invalid 'r' in argument string 
		push { r0 }
		bl ParseStringAsDecimalNumber
		str r0, [regvar_args, regvar_arg] @ store decimal constant in its place in the argument vector
		pop { r0 }
		add regvar_arg, 1 @ read next argument
		add regvar_argstate, regvar_arg, matcharg @ current state is matcharg. 
			@ if arg==1, goes to matchsign. else if arg==2, goes to matchshift. else if arg==3, goes to matchrightbracket.
		add regvar_argj, 1
		b ReadArgumentString @ do loop

	HandleWSP: @ [\n\t \r]
		add regvar_argj, 1 @ consume whitespace
		b ReadArgumentString @ do loop
		
	@HandleAnyOtherChar: @ branches directly
		@bl ErrorCharArg

	ArgHandleNullOrComma: @ \0 or "," detected ! end of argument
		cmp regvar_argstate, matcharg @ matchleftbracket and matcharg: error, we havent read any arguments yet
		ble PrematurelyFinishedArgumentString
	IsBracketClosed:
		tst regvar_argflags, (1<<1) @ test '[' flag
		beq FinishObtainValueFromNextArg @ if no square bracket, no check necessary
		tst regvar_argflags, (1<<2) @ test ']' flag
		beq DidNotCloseSquareBrackets
	FinishObtainValueFromNextArg:
		add regvar_argj, 1 @ consume the \0 or ,
		ldmia regvar_args, { regvar_argscratch1, regvar_argscratch2, regvar_argscratch3 } @ load the values obtained
		lsl regvar_argscratch2, regvar_argscratch2, regvar_argscratch1 @ execute the shift
		tst regvar_argflags, (1<<0) @ test the +/- offset flag 
		ite eq @ if flag is clear, positive offset; otherwise, negative offset
		addeq regvar_argscratch1, regvar_argscratch1, regvar_argscratch2
		subne regvar_argscratch1, regvar_argscratch1, regvar_argscratch2
		tst regvar_argflags, (1<<1) @ test '[' flag
		itt ne
		movne r0, regvar_argscratch1 @ return pointer to argument
		bne ReturnFromObtainValueFromNextArg @ if '[' is set, we are returning an address anyway, so we are done 
	@ otherwise, it's an actual register value and not a pointer. we will store it (length bytes, 1-4) in our special buffer
		cmp regvar_arglength, 1 @ one byte register value copied to the internal buffer
		it eq
		sxtbeq regvar_argscratch1, regvar_argscratch1
		cmp regvar_arglength, 2 @ 2 byte register value copied to the internal buffer
		it eq
		sxtheq regvar_argscratch1, regvar_argscratch1
		cmp regvar_arglength, 3 @ 3 byte register value copied to the internal buffer (who the heck will use this feature)
		ittt eq
		sxtheq regvar_argscratch1, regvar_argscratch1
		lsleq regvar_argscratch1, 8
		asreq regvar_argscratch1, 8 @ we sign extended a 3 byte register 
		str regvar_argscratch1, [regvar_args] @ now we store it in the internal buffer
		mov r0, regvar_args @ and return a pointer to the internal buffer. done
	ReturnFromObtainValueFromNextArg:	
		@ new index to the argument string is loaded in r1.
pop {  r2-r8 , pc }


ErrorCharArg: @ invalid character during argument specifier read
	ldr r0, =OffendingChar
	strb regvar_argchar, [r0] @ this character will be inserted in a sui generis error message
	ldr r0, =ErrorCharMsg
	bl UnwindObtainValueOnError @@@@ unwind ObtainValue's stack, load error message at r1, return 0 (error)

UnwindObtainValueOnError: @ ObtainValueFromNextArg must leave an error message (passed in at r0) at r1
	pop { r2-r8, lr }
	mov r1, r0 @ error message here
	mov r0, 0 @ returns null pointer on failure
mov pc, lr

@ !! error messages !!


TriedToUseLinkRegister: @ we warn the user that the user's link register is no accessible from printf.
	ldr r0, =TriedToUseLinkRegisterMsg
	bl UnwindObtainValueOnError @@@@ unwind ObtainValue's stack, load error message at r1 return 0 (error)
TriedToUseLinkRegisterMsg:
	.asciz "Error: the link register is not accessible from printf (clobbered during branch and link)\n"
.align

PrematurelyFinishedArgumentString: @ (\0 or ",", haven't matched any arguments yet)
	ldr r0, =PrematurelyFinishedArgumentStringMsg
	bl UnwindObtainValueOnError @@@@ unwind ObtainValue's stack, load error message at r1 return 0 (error)
PrematurelyFinishedArgumentStringMsg:
	.asciz "Error: argument string terminated in the middle of an argument specifier\n"
.align

DidNotCloseSquareBrackets: @ (\0 or ",", haven't matched any arguments yet)
	ldr r0, =DidNotCloseSquareBracketsMsg
	bl UnwindObtainValueOnError @@@@ unwind ObtainValue's stack, load error message at r1 return 0 (error)
DidNotCloseSquareBracketsMsg:
	.asciz "Error: unmatched square brackets in the argument string\n"
.align

InvalidRegisterSpecified: @ register must be in the range 0-15
	ldr r0, =InvalidRegisterSpecifiedMsg
	bl UnwindObtainValueOnError @@@@ unwind ObtainValue's stack, load error message at r1 return 0 (error)
InvalidRegisterSpecifiedMsg:
	.asciz "Error: register specified as argument must be in the range 0-15\n"
.align


PrintSomeCharNTimes: @ note: PrintChar shields from clobber. r1 is (possibly) modified
	@ character to print -> r0, how many times -> r1. if non positive, no characters printed.
cmp r1, 0
it le @ while number of characters to print is positive, print them
movle pc, lr 
	bl PrintChar @ PrintChar(r0 === char)
	sub r1, 1
	b PrintSomeCharNTimes @ equivalent to tail recursive call PrintSomeCharNTimes(char, ntimes-1)


PrintBuffer: @ flushes the entire buffer to outputfunc. returns printedchars -> r0
push { r1-r8, r12, lr }
regvar_staticvars .req r4
regvar_buffer .req r5
regvar_buffercount .req r6
regvar_printedchars .req r7
regvar_outputfunc .req r8

ldr regvar_staticvars, =PrintCharStaticVars
ldmia regvar_staticvars, { regvar_buffer, regvar_buffercount, regvar_printedchars, regvar_outputfunc }

	mov r0, regvar_buffer @ call outputfunc(buffer) 
	mov r1, 0
	strb r1, [regvar_buffer, regvar_buffercount] @ add a \0 to the string we will send to outputfunc
	blx regvar_outputfunc
	add regvar_printedchars, regvar_printedchars, regvar_buffercount @ update # of chars actually printed
	mov r0, regvar_printedchars @ returns total number of printed chars
	mov regvar_buffercount, 0 @ empty buffer

stmia regvar_staticvars, { regvar_buffer, regvar_buffercount, regvar_printedchars, regvar_outputfunc }
pop { r1-r8, r12, pc }


PrintChar: @ character to print -> r0. full protection from clobbers by outputfunc. returns character printed
push { r1-r8, r12, lr }
regvar_staticvars .req r4
regvar_buffer .req r5
regvar_buffercount .req r6
regvar_printedchars .req r7
regvar_outputfunc .req r8

ldr regvar_staticvars, =PrintCharStaticVars
ldmia regvar_staticvars, { regvar_buffer, regvar_buffercount, regvar_printedchars, regvar_outputfunc } 	

	cmp regvar_buffercount, BUFFERSIZE
	ittt ne @ if buffer is not full, safely print a character to the buffer and increment buffercount 
	strbne r0, [regvar_buffer, regvar_buffercount]
	addne regvar_buffercount, 1
	bne FinishedPrintChar
	push { r0 }
	mov r0, regvar_buffer @ otherwise we have to flush the buffer: call outputfunc(buffer) 
	blx regvar_outputfunc
	pop { r0 }
	add regvar_printedchars, regvar_printedchars, regvar_buffercount @ update # of chars actually printed
	strb r0, [regvar_buffer]
	mov regvar_buffercount, 1 @ buffer reset to zero and then print one char at the beginning of the buffer

FinishedPrintChar:
stmia regvar_staticvars, { regvar_buffer, regvar_buffercount, regvar_printedchars, regvar_outputfunc }
pop { r1-r8, r12, pc }
	


