
printf_baremetal: @ r0: outputfunc, r1: formatstr, r2: argumentstr


push { r0-r12, lr } @ we keep track of sp. lr is pc. original lr is not available, clobbered during branch and link.

regvar_char .req r0
regvar_formatstr .req r10 
regvar_argumentstr .req r11
regvar_j .req r12
regvar_i .req r4
regvar_asciitable .req r5
regvar_flags .req r6
regvar_width .req r7
regvar_length .req r8
regvar_state .req r9

.equ readformatstr, 0
.equ readflags, 1
.equ readwidth, 2
.equ readlength, 3
.equ readformatspecifier, 4

@ user flags for printf
.equ spaceflag, 0 @ bit zero of regvar_flags
.equ poundflag, 1 @ bit 1 of regvar_flags
.equ plusflag, 2 @ bit 2 of regvar_flags
.equ dashflag, 3 @ bit 3 of regvar_flags
.equ zeroflag, 4 @ bit 4 of regvar_flags
@ auxiliary format flags
.equ print0prefixflag, 8
.equ printXprefixflag, 9
.equ printspaceprefixflag, 10
.equ printplusprefixflag, 11
.equ printminusprefixflag, 12

.equ printf_varstackframesize, 0 @ (in words) if we keep variables on the stack, we'll have to move this
	
	ldr32 r14, TheUserStack @ we'll keep the user's registers in a friendly table, indexed by regnum.
	stmia r14, { r0-r12 }
	add r0, sp, 14*4 @ user's stack pointer (we saved 14 registers)
	str r0, [r14, 13*4] @ r13 === sp 
	mov r0, r14
	ldr r14, [sp, 13*4] @ restore lr
	str r14, [r0, 15*4] @ lr is user's pc. we dont have access to user's lr.
	ldr r0, [sp] @ restore r0 (outputfunc is there)

	ldr32 r3, PrintCharStaticVars @ these variables we set aside as static variables at this location.
	ldmia r3, {r4, r5, r6, r7} @ buffer, buffercount, printedchars, outputfunc
	ldr32 r4, Buffer @ buffer that stores the string to be passed to outputfunc
	mov r5, 0 @ buffercount initialized to zero: no characters printed out (buffered) yet.
	mov r6, 0 @ printedchars initialized to zero: no character actually passed out to outputfunc yet.
	mov r7, r0 @ outputfunc kept here: int outputfunc( const char *printme )
	stmia r3, {r4, r5, r6, r7} @ buffer, buffercount, printedchars, outputfunc

	mov regvar_formatstr, r1
	mov regvar_argumentstr, r2 @ get them out of the way: parameter passing zone
	mov regvar_i, 0 @ index for reading the format string
	mov regvar_j, 0 @ index for reading the argument string
	ldr32 regvar_asciitable, FormatStrAsciiTable @@@@ that might have to go below depending on register allocation.
	mov regvar_state, readformatstr

ReadFormatString:

ldrb regvar_char, [regvar_formatstr, regvar_i] @ char = formatstr[i]
ldrb r1, [regvar_asciitable, regvar_char] @ load four byte aligned offset/4 from the branch table
ldr32 r2, PrintfBranchOnAsciiCharacter+1 @ make sure all of our branch locations are four byte (2**2) aligned. THUMB bit set.
add r2, r2, r1, lsl 2 @ branch to: 4*tablebyteoffset + baseaddress + 1 for the THUMB bit
bx r2 @ all sorts of inane rules regarding PC. ARM can do better than this.
// tbh [regvar_asciitable, regvar_char, lsl 1] @ branch by ascii character to the right handlers
.align
PrintfBranchOnAsciiCharacter:

BranchToHandlePlus:
	tbh [pc, regvar_state, lsl 1] @ (+)
	HandlePlus:
	.hword (IncrementI_AndPrintChar-HandlePlus)/2
	.hword (PlusFlag-HandlePlus)/2
	.hword (ErrorChar-HandlePlus)/2
	.hword (ErrorChar-HandlePlus)/2
	.hword (ErrorChar-HandlePlus)/2

	PlusFlag: @ (+, readflags)
		// optional error/warning check: is flag already set?
		orr regvar_flags, (1<<plusflag) @ flags.plus <- true
		add regvar_i, 1
		b ReadFormatString

.align
BranchToHandleDash:
	tbh [pc, regvar_state, lsl 1] @ (-)
	HandleDash:
	.hword (IncrementI_AndPrintChar-HandleDash)/2
	.hword (DashFlag-HandleDash)/2
	.hword (ErrorChar-HandleDash)/2
	.hword (ErrorChar-HandleDash)/2
	.hword (ErrorChar-HandleDash)/2	

	DashFlag: @ (-, readflags)
		// optional error/warning check: is flag already set?
		orr regvar_flags, (1<<dashflag) @ flags.dash <- true
		add regvar_i, 1
		b ReadFormatString	
.align
BranchToHandleSpace:
	tbh [pc, regvar_state, lsl 1] @ (' ')
	HandleSpace:
	.hword (IncrementI_AndPrintChar-HandleSpace)/2
	.hword (SpaceFlag-HandleSpace)/2
	.hword (ErrorChar-HandleSpace)/2
	.hword (ErrorChar-HandleSpace)/2
	.hword (ErrorChar-HandleSpace)/2
	

	SpaceFlag: @ (' ', readflags)
		// optional error/warning check: is flag already set?
		orr regvar_flags, (1<<spaceflag) @ flags.space <- true
		add regvar_i, 1
		b ReadFormatString
.align
BranchToHandlePound:
	tbh [pc, regvar_state, lsl 1] @ ('#')
	HandlePound:
	.hword (IncrementI_AndPrintChar-HandlePound)/2
	.hword (PoundFlag-HandlePound)/2
	.hword (ErrorChar-HandlePound)/2
	.hword (ErrorChar-HandlePound)/2
	.hword (ErrorChar-HandlePound)/2
		

	PoundFlag: @ ('#', readflags)
		// optional error/warning check: is flag already set?
		orr regvar_flags, (1<<poundflag) @ flags.pound <- true
		add regvar_i, 1
		b ReadFormatString

.align
BranchToHandleZero:
	tbh [pc, regvar_state, lsl 1] @ (0)
	HandleNaught:
	.hword (IncrementI_AndPrintChar-HandleNaught)/2
	.hword (NaughtFlag-HandleNaught)/2
	.hword (ReadWidthNum-HandleNaught)/2
	.hword (ReadLengthNum-HandleNaught)/2
	.hword (ErrorChar-HandleNaught)/2	

	NaughtFlag: @ (0, readflags)
		// optional error/warning check: is flag already set?
		orr regvar_flags, (1<<zeroflag) @ flags.naught <- true
		add regvar_i, 1
		b ReadFormatString

.align
BranchToHandleStar:
	tbh [pc, regvar_state, lsl 1] @ (*)
	HandleStar:
	.hword (IncrementI_AndPrintChar-HandleStar)/2
	.hword (WidthArg-HandleStar)/2
	.hword (WidthArg-HandleStar)/2
	.hword (LengthArg-HandleStar)/2
	.hword (ErrorChar-HandleStar)/2

	WidthArg: @ (*, readflags/readwidth)
		mov r0, regvar_argumentstr @ pointer to the argument string
		mov r1, regvar_j @ index to the argument string
		mov r2, 4 @ length (in bytes) of the number to be obtained (an integer that specifies the minimium field width)
		bl ObtainValueFromNextArg @ string -> r0, index -> r1, length -> r2 ... ptr_to_arg -> r0, newindex -> r1
		cmp r0, 0 @ if ObtainValueFromNextArg returned a null pointer
		beq ErrorObtainingArgument @ ObtainValueFromNextArg left an error message at sp. unwind printf and leave msg at sp, return -1
		mov regvar_j, r1
		ldr regvar_width, [r0] @ r0, returned by OVFNA, is a pointer to the argument containing the width,
		cmp regvar_width, 0
		blt NegativeFieldWidthError @ thought you would crash my app with a negative width, fool?
		add regvar_i, 1 @ consume the * character
		mov regvar_state, readlength @ done obtaining the width
		b ReadFormatString

	LengthArg: @ (*, readlength)
		cmp regvar_length, 8 @ this must come after a 'l' character in the length specifier (i.e. "l*")
		bne ErrorChar
		mov r0, regvar_argumentstr @ pointer to the argument string
		mov r1, regvar_j @ index to the argument string
		mov r2, 4 @ length (in bytes) of the number to be obtained (an integer that specifies the length)
		bl ObtainValueFromNextArg @ string -> r0, index -> r1, length -> r2 ... ptr_to_arg -> r0, newindex -> r1
		cmp r0, 0 @ if ObtainValueFromNextArg returned a null pointer
		beq ErrorObtainingArgument @ ObtainValueFromNextArg left an error message at sp. unwind printf and leave msg at sp, return -1
		mov regvar_j, r1
		ldr regvar_length, [r0] @ r0, returned by OVFNA, is a pointer to the argument containing the width,
		cmp regvar_length, 0
		ble NegativeFieldLengthError @ thought you would crash my app with a negative Length, fool?
		cmp regvar_length, MAXNUMBYTESIZE
		bhi InvalidByteSizeError @ if bounds are higher (non positive or bigger) than the MAXNUMBYTESIZE, error
		add regvar_i, 1 @ consume the * character
		mov regvar_state, readformatspecifier @ done obtaining the length.
		b ReadFormatString

.align
BranchToHandleL:
	tbh [pc, regvar_state, lsl 1] @ (l)
	HandleL:
	.hword (IncrementI_AndPrintChar-HandleL)/2
	.hword (SetLengthL-HandleL)/2
	.hword (SetLengthL-HandleL)/2
	.hword (SetLengthL-HandleL)/2
	.hword (ErrorChar-HandleL)/2

	SetLengthL: @ (l, readflags/readwidth/readlength)
		add regvar_i, 1
		mov regvar_state, readlength @ in case we're not there already
		cmp regvar_length, 4 @ if this is the first L, double the default length of 4 bytes
		itt eq
		lsleq regvar_length, 1
		beq ReadFormatString
		cmp regvar_length, 8 @ if this is the second L, double again to 16 bytes and move to readformatspecifier 
		ittt eq
		lsleq regvar_length, 1
		moveq regvar_state, readformatspecifier
		beq ReadFormatString
		bl InvalidLLengthModifierError @ if we got here, then we have an invalid L (after an H, for instance)
.align
BranchToHandleH:
	tbh [pc, regvar_state, lsl 1] @ (h, readflags/readwidth/readlength)
	HandleH:
	.hword (IncrementI_AndPrintChar-HandleH)/2
	.hword (SetLengthH-HandleH)/2
	.hword (SetLengthH-HandleH)/2
	.hword (SetLengthH-HandleH)/2
	.hword (ErrorChar-HandleH)/2

	SetLengthH:
		add regvar_i, 1
		mov regvar_state, readlength @ in case we're not there already
		cmp regvar_length, 4 @ if this is the first H, halve the default length of 4 bytes
		itt eq
		lsreq regvar_length, 1
		beq ReadFormatString
		cmp regvar_length, 2 @ if this is the second H, halve again to 1 byte and move to readformatspecifier 
		ittt eq
		lsreq regvar_length, 1
		moveq regvar_state, readformatspecifier
		beq ReadFormatString
		bl InvalidHLengthModifierError @ if we got here, then we have an invalid H (after an L, for instance)
.align
BranchToHandleDigits:
	tbh [pc, regvar_state, lsl 1] @ ([1-9])
	HandleDigits:
	.hword (IncrementI_AndPrintChar-HandleDigits)/2
	.hword (ReadWidthNum-HandleDigits)/2
	.hword (ReadWidthNum-HandleDigits)/2
	.hword (ReadLengthNum-HandleDigits)/2
	.hword (ErrorChar-HandleDigits)/2	


	ReadWidthNum: @ (0, readwidth) @ read the minimum field width as a decimal number
		mov r0, regvar_formatstr
		mov r1, regvar_i 
		bl ParseStringAsDecimalNumber @ string -> r0, index-> r1 ... r0 -> number read, r1 -> index of first non (decimal) digit 
		mov regvar_width, r0 
		mov regvar_i, r1
		mov regvar_state, readlength
		b ReadFormatString

	ReadLengthNum: @ (0, readwidth) @ read the minimum field width as a decimal number
		mov r0, regvar_formatstr
		mov r1, regvar_i 
		bl ParseStringAsDecimalNumber @ string -> r0, index-> r1 ... r0 -> number read, r1 -> index of first non (decimal) digit 
		mov regvar_length, r0
		cmp regvar_length, MAXNUMBYTESIZE
		bhi InvalidByteSizeError @ if bounds are higher (non positive or bigger) than the MAXNUMBYTESIZE, error
		mov regvar_i, r1
		mov regvar_state, readformatspecifier
		b ReadFormatString

@ now the actual specifiers:

regvar_radix .req r2
regvar_digitlookup .req r3
.align
	HandleC: @ (c)
		cmp regvar_state, readformatstr
		beq IncrementI_AndPrintChar @ if in normal reading state, just print it
		add regvar_i, 1
		mov regvar_state, readformatstr
		// optional error/warning check for spurious length (we only work with 1 byte) and ineffectual ' ', #, +, 0 flags
		mov r0, regvar_argumentstr @ pointer to the argument string
		mov r1, regvar_j @ index to the argument string
		mov r2, 1 @ length in bytes of the char value to obtain
@ length (in bytes) of the number to be obtained (matters if we want to grab 1-3 bytes from a register.
@ otherwise, doesn't matter because this function returns a pointer to the value anyway (register values are stored in a special buffer) )
		bl ObtainValueFromNextArg @ string -> r0, index -> r1, length -> r2 ... ptr_to_arg -> r0, newindex -> r1
		cmp r0, 0 @ if ObtainValueFromNextArg returned a null pointer
		beq ErrorObtainingArgument 
	@ if ObtainValueFromNextArg returns null, it leaves an error message at sp. unwind printf and leave msg at sp, return -1
		mov regvar_j, r1
		sub regvar_width, 1 @ this many extra ' ' will have to be printed to make the minimum field width.
		ldrb r0, [r0] @ ObtainValueFromNextArg always returns a pointer to the desired value.
		tst regvar_flags, (1<<dashflag) @ if the dash flag is set, we left justify the field, within the min field width.
		beq RightJustifyCharPrintout 
			bl PrintChar @ first print the character (left justify), then the spaces.
			mov r0, ' ' @ padding.
			mov r1, regvar_width @ amount of padding as calculated above.
			bl PrintSomeCharNTimes
			b ReadFormatString
		RightJustifyCharPrintout: @ this is the default (no dash flag)
			push { r0 }
				mov r0, ' '
				mov r1, regvar_width
				bl PrintSomeCharNTimes @ first print the padding, then the character (right justify)
			pop { r0 }
			bl PrintChar
			b ReadFormatString
.align		
	HandleS: @ (s)

		cmp regvar_state, readformatstr
		beq IncrementI_AndPrintChar @ if in normal reading state, just print it
		add regvar_i, 1
		mov regvar_state, readformatstr
// optional error/warning check for spurious length (we only work with 4 byte pointers to strings) and ineffectual ' ', #, +, 0 flags
		mov r0, regvar_argumentstr @ pointer to the argument string
		mov r1, regvar_j @ index to the argument string
		mov r2, 4 @ length in bytes of the pointer to string value to obtain
@ length (in bytes) of the number to be obtained (matters if we want to grab 1-3 bytes from a register.
@ otherwise, doesn't matter because this function returns a pointer to the value anyway (register values are stored in a special buffer) )
		bl ObtainValueFromNextArg @ string -> r0, index -> r1, length -> r2 ... ptr_to_arg -> r0, newindex -> r1
		cmp r0, 0 @ if ObtainValueFromNextArg returned a null pointer
		beq ErrorObtainingArgument @ ObtainValueFromNextArg left an error message at sp. unwind printf and leave msg at sp, return -1
		mov regvar_j, r1
		ldr r0, [r0] @ the pointer to the string is stored here (value obtained from arg string is a pointer to a string)
		bl StringLength @ string -> r0 ... r0->string, r1 -> string length.
	//CharacterSpecBranchesInHere: @ must have length of 1 loaded in r1, and a null byte terminated string loaded in valueptr===r0.
		sub regvar_width, r1 @ width - StringLength(string) characters have to be printed to make the minimum field width. if non-positive, then no characters are printed
		tst regvar_flags, (1<<dashflag) @ if the dash flag is set, we left justify the field (within the field width)
		beq RightJustifyString
			//mov r0, regvar_valueptr @ print the string first, then the padding => left justification
			bl PrintString @ string -> r0 ... r0-> string (echo)
			mov r0, ' ' @ pad with spaces to the minimum field width.
			mov r1, regvar_width
			bl PrintSomeCharNTimes @ character to print -> r0, how many times -> r1. if non positive, no characters printed.
			b ReadFormatString
		RightJustifyString:
			push { r0 }
			mov r0, ' ' @ pad with spaces to the minimum field width.
			mov r1, regvar_width
			bl PrintSomeCharNTimes @ character to print -> r0, how many times -> r1. if non positive, no characters printed.
			pop { r0 }
			//mov r0, regvar_valueptr @ print the padding first => right justification. then the string
			bl PrintString @ string -> r0 ... r0-> string (echo)
			b ReadFormatString
.align
	HandleN: @ (n)
		cmp regvar_state, readformatstr
		beq IncrementI_AndPrintChar @ if in normal reading state, just print it
		
		mov r0, regvar_argumentstr @ pointer to the argument string
		mov r1, regvar_j @ index to the argument string
		mov r2, 4 @ length in bytes of the pointer to storage we will obtain
@ length (in bytes) of the number to be obtained (matters if we want to grab 1-3 bytes from a register.otherwise, 
@ doesn't matter because this function returns a pointer to the value anyway (register values are stored in a special buffer))
		bl ObtainValueFromNextArg @ string -> r0, index -> r1, length -> r2 ... ptr_to_arg -> r0, newindex -> r1
		cmp r0, 0 @ if ObtainValueFromNextArg returned a null pointer
		beq ErrorObtainingArgument @ ObtainValueFromNextArg left an error message at sp. unwind printf and leave msg at sp, return -1
		mov regvar_j, r1

		ldr32 r1, PrintCharStaticVars
		ldr r2, [r1, 4] @ buffercount
		ldr r3, [r1, 8] @ printedchars 
		add r1, r2, r3 @ buffercount + printedchars is total number of characters outputted so far.
		str r1, [r0] @ we store the number of characters printed so far at the address read from the argument string

		add regvar_i, 1
		mov regvar_state, readformatstr 
		b ReadFormatString
.align
	HandleO: @ (o) unsigned octal
		cmp regvar_state, readformatstr
		beq IncrementI_AndPrintChar @ if in normal reading state, just print it

		ldr32 regvar_digitlookup, DigitsLookup
		//mov regvar_signbit, 0 @ this just encodes non signed decimal for the next routine's convenience (so it doesnt check sign)
		mov regvar_radix, 8

		b HandleNumberFormatting
.align
	HandleP: @ (p) our standard format for printing pointers is %0#10x
		cmp regvar_state, readformatstr
		beq IncrementI_AndPrintChar @ if in normal reading state, just print it

		mov regvar_flags, (1<<zeroflag + 1<<poundflag) @ set the zero and pound flags (show 0x and left pad number with zeroes)
		mov regvar_width, 10 @ width of ten (8 hex digits and the 0x)
		mov regvar_length, 4 @ four byte value to be printed

		b HandleX
.align
	HandleU: @ (u)
		cmp regvar_state, readformatstr
		beq IncrementI_AndPrintChar @ if in normal reading state, just print it

		ldr32 regvar_digitlookup, DigitsLookup
		//mov regvar_signbit, 0 @ this just encodes non signed decimal for the next routine's convenience (so it doesnt check sign)
		mov regvar_radix, 10

		b HandleNumberFormatting
.align
	HandleX: @ (c)
		cmp regvar_state, readformatstr
		beq IncrementI_AndPrintChar @ if in normal reading state, just print it

		ldr32 regvar_digitlookup, DigitsLookup
		//mov regvar_signbit, 0 @ this just encodes non signed decimal for the next routine's convenience (so it doesnt check sign)
		mov regvar_radix, 16

		b HandleNumberFormatting
.align
	HandleBigX: @ (c)
		cmp regvar_state, readformatstr
		beq IncrementI_AndPrintChar @ if in normal reading state, just print it

		ldr32 regvar_digitlookup, DigitsLookupCaps
		//mov regvar_signbit, 0 @ this just encodes non signed decimal for the next routine's convenience (so it doesnt check sign)
		mov regvar_radix, 16

		b HandleNumberFormatting
.align
	HandleOther: @ (any other character not on the list)
		cmp regvar_state, readformatstr
		beq IncrementI_AndPrintChar @ if in normal reading state, just print it	
		bl ErrorChar @ we've detected an invalid character in the format specifier


.align
BranchToHandleNullByte:
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
		@ mov regvar_returnval === r0, regvar_printedchars === r0
		pop { r0-r12, lr }
		ldr32 r0, PrintCharStaticVars
		ldr r0, [r0, 8] @ printedchars stored here.
	mov pc, lr

	PrematurelyFinishedFormatString: @ (\0, not readformatstr)
		ldr32 r0, PrematurelyFinishedFormatStringMsg
		bl UnwindPrintfOnError @@@@ unwind printf's stack, load error message at sp, return -1
.align
BranchToHandlePercent:
	tbb [pc, regvar_state] @ (%)
	HandlePercent:
	.byte (BeginReadingFormatSpecifier-HandlePercent)/2
	.byte (TreatPercentSpecifier-HandlePercent)/2
	.byte (TreatPercentSpecifier-HandlePercent)/2
	.byte (TreatPercentSpecifier-HandlePercent)/2
	.byte (TreatPercentSpecifier-HandlePercent)/2
	.byte 0

	BeginReadingFormatSpecifier: @ (%, readformatstr)
		mov regvar_flags, 0 @ default: all flags clear (' ', '#', '+', '-', '0'), including auxiliary flags.
		mov regvar_width, 0 @ default: no minimum field width
		mov regvar_length, 4 @ default: 4 byte numbers (when dealing with numbers, this is relevant)
		add regvar_i, 1 @ consume the '%'
		mov regvar_state, readflags @ begin looking at (optional) flags
		b ReadFormatString 
		@ break
	TreatPercentSpecifier: @ (%, not readformatstr) 
		// optional error/warning check for spurious format modifiers (have no effect)
		mov regvar_state, readformatstr @ go back to reading and printing characters.
		@ Fall through!
	IncrementI_AndPrintChar: @ every time a character (not %) is read in readformatstr 
		add regvar_i, 1 
	// 	@ fall through
	// PrintCharacter:
		bl PrintChar @ print the character loaded in r0 (formerly formatstr[i])
		b ReadFormatString 
		@ break



.align
	HandleD: @ (d, i)
		cmp regvar_state, readformatstr
		beq IncrementI_AndPrintChar @ if in normal reading state, just print it
	HandleSignedDecimalInteger:
		ldr32 regvar_digitlookup, DigitsLookup
		orr regvar_flags, 0x80000000 
			@ this just encodes 'signed decimal' flag set for the next routine's convenience (so it needs to check sign)
		mov regvar_radix, 10
	HandleNumberFormatting:
	@ unsigned octal, hex, etc., all branch in here
	@ must have lookup table, sign bit, and radix loaded. note no clobber policy.
		mov r0, regvar_argumentstr @ pointer to the argument string
		mov r1, regvar_j @ index to the argument string
		push { r2 } @ register allocation is not meant for humans
		mov r2, regvar_length @ length in bytes of the number value to obtain
@ length (in bytes) of the number to be obtained (matters if we want to grab 1-3 bytes from a register. otherwise,
@ doesn't matter because this function returns a pointer to the value anyway (register values are stored in a special buffer))
		bl ObtainValueFromNextArg @ string -> r0, index -> r1, length -> r2 ... ptr_to_arg -> r0, newindex -> r1
		pop { r2 } @ remember, we kept the radix here
		cmp r0, 0 @ if ObtainValueFromNextArg returned a null pointer
		beq ErrorObtainingArgument @ ObtainValueFromNextArg left an error message at sp. unwind printf and leave msg at sp, return -1
		mov regvar_j, r1
		 // mov regvar_valueptr, r0 @ for safekeeping. note: we have a pointer to a length bytes long number here
		mov r1, regvar_length @ length in bytes of the number
		tst regvar_flags, 0x80000000 @ it was set to 1 initially for signed decimal integers, so that we can branch to determine it
			@ everyone else is set to zero by default (mov regvar_flags, 0 @ previously when we leave readformatstr)
		beq PositiveNumberBranchesHere
			sub r1, regvar_length, 1 
			ldrb r1, [r0, r1] @ load valueptr[length-1] @ byte indexed
			tst r1, 0x80 
				@ test the sign bit (bit 7) of the (potentially huge, not necessarily word aligned) number
			bne NegativeNumber 
				@ if sign bit is clear, copy the number from memory to our internal buffer for (destructive) processing 
		PositiveNumberBranchesHere: 
			bic regvar_flags, 0x80000000 @ clear sign bit, positive number 
			mov r1, regvar_length @ length in bytes of the number
			bl CopyNumberToBuffer @ pointer to number -> r0, number byte length -> r1 ... 
									@ returns: r0 -> internal buffer ptr, r1 -> buffer word size
			b ObtainDigitsForNumber @ now determine the 
		NegativeNumber: @ otherwise, if sign bit is set: copy 2's complement of the number to our internal buffer
			//sign bit already set
			mov r1, regvar_length @ length in bytes of the number
			bl Copy2sComplement @ pointer to number -> r0, number byte length -> r1 ... 
									@ returns: r0 -> internal buffer ptr, r1 -> buffer word size
	ObtainDigitsForNumber:
		//mov regvar_number, r0 @ safekeeping
		//mov regvar_numwordsize, r1 @ safekeeping
		//mov r2, regvar_radix @ radix (Note no clobber policy)
		//ldr r3, regvar_digitlookup @ contains digit indexed table of ascii characters corresponding to digits.
		bl ObtainDigitsFromNumber @ pointer to number -> r0, word size of number -> r1, radix -> r2, digitlookuptable -> r3... 
									@ returns r0 -> ptr to string with digits (in reverse order), r1 -> size of string
		
	push { r11, r12 } @ life is too short to program in assembly. at least have a machine program the register allocation
	regvar_stringlength .req r1
	regvar_totalstringlength .req r12
		mov r11, '0'
		mov regvar_totalstringlength, regvar_stringlength
		cmp regvar_stringlength, 0 @ special case in which the number to be printed is actually zero.
		itttt eq
		strbeq regvar_stringlength, [r0, 1] @ null byte to terminate the string 
		strbeq r11, [r0] @ actually store an ascii zero in outputstring to be printed.
		moveq regvar_totalstringlength, 1
		moveq regvar_stringlength, 1
		beq NowConsiderSignFormatting @ doesnt need to be in the IT block.
@ now: do we print a 0, 0x prefix? do we print a sign (or a space in its place?) ? 
@ do we left or right justify within field width? if right justify, do we left pad with zeroes? 
@ if not, do we pad with spaces ?
		tst regvar_flags, (1<<poundflag) @ is the # flag set?
		beq NowConsiderSignFormatting @ if not, go on to the next step

		cmp regvar_radix, 10 @ is it decimal ? then go on to the next step
		beq NowConsiderSignFormatting
		cmp regvar_radix, 8 @ is it octal? then with # set, non zero value, we will print a 0 prefix.
		ittt eq
		orreq regvar_flags, (1<<print0prefixflag) @ set the auxiliary 'print 0 prefix' flag
		addeq regvar_totalstringlength, 1 @ take into account one more character to be printed 
		beq NowConsiderSignFormatting
		orr regvar_flags, (1<<print0prefixflag + 1<<printXprefixflag)
		@ if we made it here, we are hex with # set, non zero value, so we set 'print a '0' and 'X' prefix' flag
		add regvar_totalstringlength, 2 @ take into account two more characters to be printed 

	NowConsiderSignFormatting:
		tst regvar_flags, 0x80000000 @ test sign bit of the number 
		ittt ne @ if sign bit is set, then we will prefix number with -
		orrne regvar_flags, (1<<printminusprefixflag) @ auxiliary 'print -' flag
		addne regvar_totalstringlength, 1 @ take into account one more character to be printed
		bne NowConsiderThePadding
		tst regvar_flags, (1<<plusflag) @ test + flag
		ittt ne @ if + flag is set, prefix number with a +
		orrne regvar_flags, (1<<printplusprefixflag) @ auxiliary 'print + flag
		addne regvar_totalstringlength, 1 @ take into account one more character to be printed
		bne NowConsiderThePadding
		tst regvar_flags, (1<<spaceflag) @ test ' ' flag
		itt ne @ if ' ' flag is set, prefix number with a ' '
		orrne regvar_flags, (1<<printspaceprefixflag) @ auxiliary "print ' ' "flag
		addne regvar_totalstringlength, 1 @ take into account one more character to be printed

	NowConsiderThePadding:
		tst regvar_flags, (1<<dashflag) @ test the dash flag 
		beq RightJustifyNumber @ if the dash flag is clear, we right justify (default)
		
		PrintFormattedNumberPrefixes regvar_flags, regvar_digitlookup
		@ prints 0 or 0x prefixes if corresponding flags are set. prints ' ', +, or - if corresponding flags are set.

		//mov r0, regvar_string
		//mov r1, regvar_stringlength
		bl PrintStringInReverse @ string -> r0, length -> r1 ... echoes r0, r1
		@ now we dont need the string or its length anymore.
		mov r0, ' ' @ since we left justify, the padding is done with spaces
		sub r1, regvar_width, regvar_totalstringlength @ must pad with spaces to reach the minimum field width
		bl PrintSomeCharNTimes @ print width - totalstringlength spaces to reach the minimum field width

		b FinishFormattingNumber
	RightJustifyNumber:

		tst regvar_flags, (1<<zeroflag) @ test the zero flag 
		bne PadNumberFieldWithZeroes @ zero flag is set

		push { r0, r1 }
			mov r0, ' ' @ since zero flag is clear, the padding is done with spaces
			sub r1, regvar_width, regvar_totalstringlength @ must pad with spaces to reach the minimum field width
			bl PrintSomeCharNTimes @ print width - totalstringlength spaces to reach the minimum field width		
		pop { r0, r1 }

			PrintFormattedNumberPrefixes regvar_flags, regvar_digitlookup
			@ prints 0 or 0x prefixes if corresponding flags are set. prints ' ', +, or - if corresponding flags are set.

			//mov r0, regvar_string
			//mov r1, regvar_stringlength
			bl PrintStringInReverse @ string -> r0, length -> r1 ... echoes r0, r1

			b FinishFormattingNumber
		PadNumberFieldWithZeroes:
			PrintFormattedNumberPrefixes regvar_flags, regvar_digitlookup
			@ prints 0 or 0x prefixes if corresponding flags are set. prints ' ', +, or - if corresponding flags are set.
		push { r0, r1 }
			mov r0, '0' @ since zero flag is set and dash flag is not, the padding is done with left zeroes
			sub r1, regvar_width, regvar_totalstringlength @ must pad with spaces to reach the minimum field width
			bl PrintSomeCharNTimes @ print width - totalstringlength spaces to reach the minimum field width
		pop { r0, r1 }
			//mov r0, regvar_string
			//mov r1, regvar_stringlength
			bl PrintStringInReverse @ string -> r0, length -> r1 ... echoes r0, r1

	FinishFormattingNumber:
	pop { r11, r12 } @ life is 
		mov regvar_state, readformatstr @ continue to read characters from the string.
		add regvar_i, 1 @ consumes the format specifier character
		b ReadFormatString


	ErrorChar: @ invalid character during format specifier read
		ldr32 r1, OffendingChar
		strb regvar_char, [r1] @ this character will be inserted in a sui generis error message
		ldr32 r0, Number @ store the index here (ObtainDigitsFromNumber requires that its argument reside in memory)
		str regvar_i, [r0]
		mov r1, 1
		mov r2, 10 @ print index in decimal form
		ldr32 r3, DigitsLookup
		bl ObtainDigitsFromNumber
@ takes pointer to number -> r0, word size of number -> r1, radix -> r2, digitlookuptable -> r3.
@ returns the stringified number in r0 (in reverse order) and the size of the string in r1
		ldr32 r2, OffendingCharPosition
		add r0, r0, r1 @ store the end of the string here for printing.
	PrintTheErrorChar:
		ldrb r3, [r0, -1]! @ load the most significant digit to be printed
		strb r3, [r2], 1   @ store it in the error message.
		subs r1, 1
		bne PrintTheErrorChar
	
		ldr32 r0, ErrorCharMsg
		bl UnwindPrintfOnError @ unwind printf's stack, put the error message at sp, return -1

	


@ removed the literal pool here too, in case gnu asm is screwing something up mysteriously (ahh the proverbial 'features')
	NegativeFieldWidthError: @ ObtainValueFromNextArg left an error message at sp. unwind printf and leave msg at sp, return -1
		ldr32 r0, NegativeFieldWidthErrorMsg
		bl UnwindPrintfOnError @ unwind printf's stack, put the error message at sp, return -1

	NegativeFieldLengthError: @ ObtainValueFromNextArg left an error message at sp. unwind printf and leave msg at sp, return -1
		ldr32 r0, NegativeFieldLengthErrorMsg
		bl UnwindPrintfOnError @ unwind printf's stack, put the error message at sp, return -1

	ErrorObtainingArgument: @ ObtainValueFromNextArg left an error message at sp. unwind printf and leave msg at r1, return -1
		mov r0, r1
		bl UnwindPrintfOnError @ unwind printf's stack, put the error message at sp, return -1

	InvalidHLengthModifierError:
		ldr32 r0, InvalidHLengthModifierErrorMsg
		bl UnwindPrintfOnError @ unwind printf's stack, put the error message at sp, return -1
	InvalidLLengthModifierError:
		ldr32 r0, InvalidLLengthModifierErrorMsg
		bl UnwindPrintfOnError @ unwind printf's stack, put the error message at sp, return -1
	InvalidByteSizeError:
		ldr32 r0, InvalidByteSizeErrorMsg
		bl UnwindPrintfOnError @ unwind printf's stack, put the error message at sp, return -1

UnwindPrintfOnError: 
@ unwinds printf's stack and places on the stack the error message passed in at r0. return -1 (error)
	add sp, 8
	pop { r2-r12, lr } @ restore user registers
	mov r1, r0 @ error message stored in r1
	mov r0, -1
mov pc, lr 




@ !! Error Messages !!

	InvalidHLengthModifierErrorMsg: 
		.asciz "Error: invalid length modifier (spurious 'h'). Format: l<decimal number> | ll | l | h | hh\n"
	.align
	InvalidLLengthModifierErrorMsg: 
		.asciz "Error: invalid length modifier (spurious 'l'). Format: l<decimal number> | ll | l | h | hh\n"
	.align
	InvalidByteSizeErrorMsg: 
		.asciz "Error: invalid length modifier. Note: length modifier must be no larger than 1024 bytes\n"
	.align
	PrematurelyFinishedFormatStringMsg:
		.asciz "Error: format string terminated in the middle of a format specifier\n"
	.align
	NegativeFieldWidthErrorMsg:
		.asciz "Error: width specifier cannot be negative\n"
	.align

	NegativeFieldLengthErrorMsg:
		.asciz "Error: width specifier cannot be non positive\n"
	.align
/*
	IllegalFormatSpecifierMsg: 
		.asciz "Error: invalid format specifier\n"
	.align
	LengthModifierTooLongMsg: 
		.asciz "Length modifier can be no longer than 1024 bytes\n"
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
	*/

