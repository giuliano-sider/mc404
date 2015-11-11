
@ collection of macros/aux functions for the printf project 

.macro PrintFormattedNumberPrefixes Rregvar_flags Rregvar_digitlookup
@ prints 0 or 0x prefixes if corresponding flags are set. prints ' ', +, or - if corresponding flags are set.
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
	ldrne r0, [\Rregvar_digitlookup, 17] @ last position in hex digit lookup table is x or X according to convenience
	blne PrintChar
.endm













ParseStringAsDecimalNumber: @ no clobber
	@ string -> r0, index-> r1 ... r0 -> number read, r1 -> index of first non (decimal) digit

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


ObtainDigitsFromNumber @ pointer to number -> r0, word size of number -> r1, radix -> r2, digitlookuptable -> r3... 
	@ returns r0 -> ptr to string with digits (in reverse order), r1 -> size of string
@ note: r3 points to digit indexed table of ascii characters corresponding to digits
push { r0-r3,  , r12, lr } @ strict no clobber policy within printf.


CopyNumberToBuffer: @ pointer to number -> r0, number byte length -> r1 ... 
					@ returns: r0 -> internal buffer ptr, r1 -> buffer word size
push { r0-r3,  , r12, lr } @ strict no clobber policy within printf.


Copy2sComplement: @ pointer to number -> r0, number byte length -> r1 ... 
						@ returns: r0 -> internal buffer ptr, r1 -> buffer word size
push { r0-r3,  , r12, lr } @ strict no clobber policy within printf.


IsNumberZero: @ number -> r0, number word size -> r1 ... 
							@ r0 and r1 -> echo. r2 -> zero if number is zero, nonzero otherwise
							 @ what did I say about the no clobber policy in printf ?
push { r0-r3,  , r12, lr } @ 

PrintStringInReverse @ string -> r0, length -> r1 ... echoes r0, r1


PrintString @ string -> r0 ... r0-> string (echo)



ObtainValueFromNextArg: 
	@ argstring -> r0, index -> r1, length -> r2 ... ptr_to_arg -> r0, newindex -> r1



































PrintSomeCharNTimes: @ note: PrintChar shields from clobber. r1 is (possibly) modified
	@ character to print -> r0, how many times -> r1. if non positive, no characters printed.
cmp r1, 0
it le @ while number of characters to print is positive, print them
movle pc, lr 
	bl PrintChar @ PrintChar(r0 === char)
	sub r2, 1
	b PrintSomeCharNTimes @ equivalent to tail recursive call PrintSomeCharNTimes(char, ntimes-1)


PrintBuffer: @ flushes the entire buffer to outputfunc. returns printedchars -> r0
push { r1-r3, regvar_staticvars, regvar_buffer, regvar_buffercount, regvar_printedchars, regvar_outputfunc, r12, lr }
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
pop { r1-r3, regvar_staticvars, regvar_buffer, regvar_buffercount, regvar_printedchars, regvar_outputfunc, r12, pc }


PrintChar: @ character to print -> r0. full protection from clobbers by outputfunc.
push { r0-r3, regvar_staticvars, regvar_buffer, regvar_buffercount, regvar_printedchars, regvar_outputfunc, r12, lr }
ldr regvar_staticvars, =PrintCharStaticVars
ldmia regvar_staticvars, { regvar_buffer, regvar_buffercount, regvar_printedchars, regvar_outputfunc } 	

	cmp regvar_buffercount, BUFFERSIZE
	ittt ne @ if buffer is not full, safely print a character to the buffer and increment buffercount 
	strbne r0, [regvar_buffer, regvar_buffercount]
	addne regvar_buffercount, 1
	bne FinishedPrintChar
	mov r0, regvar_buffer @ otherwise we have to flush the buffer: call outputfunc(buffer) 
	blx regvar_outputfunc
	add regvar_printedchars, regvar_printedchars, regvar_buffercount @ update # of chars actually printed 
	mov regvar_buffercount, 0 @ buffer reset to zero

FinishedPrintChar:
stmia regvar_staticvars, { regvar_buffer, regvar_buffercount, regvar_printedchars, regvar_outputfunc }
pop { r0-r3, regvar_staticvars, regvar_buffer, regvar_buffercount, regvar_printedchars, regvar_outputfunc, r12, pc }
	