@ data section for the printf executable

.align
.data

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
.rept OUTPUTSTRINGSIZE + 1 @ could keep the \0 terminator so we can flush this beast as a string
	.byte 0
.endr

Number: // keeps internal representation of number (unsigned) for manipulation
.rept MAXNUMBYTESIZE // ceiling of maximum bytelength/4
	.byte 0
.endr

PrintCharStaticVars: @ for functions that do printing (static store)
	@ stores regvar_buffer, regvar_buffercount, regvar_printedchars, regvar_outputfunc
.word 0, 0, 0, 0
		
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