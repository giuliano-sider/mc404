@ data section for the printf executable

.align
.data

.macro FillSpaceBetweenChars charfrom, charto, value @ 2 chars, charto>charfrom, 1 number
@ used for filling out spaces between notable characters in an ascii indexed branch table
	.rept (\charto - \charfrom) - 1
		.byte \value
	.endr
.endm


FormatStrAsciiTable:  @ branch table used to branch inside printf 
@ (based on ascii character read from the format string)
.byte 0 @ the routine for handling \0 is right after the table branch: no offset
FillSpaceBetweenChars '\0', ' ', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.byte (BranchToHandleSpace-PrintfBranchOnAsciiCharacter)/2 @ ' '
FillSpaceBetweenChars ' ', '#', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.byte (BranchToHandlePound-PrintfBranchOnAsciiCharacter)/2 @ '#'
FillSpaceBetweenChars '#', '%', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.byte (BranchToHandlePercent-PrintfBranchOnAsciiCharacter)/2 @ '%'
FillSpaceBetweenChars '%', '*', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.byte (BranchToHandleStar-PrintfBranchOnAsciiCharacter)/2 @ '*'
.byte (BranchToHandlePlus-PrintfBranchOnAsciiCharacter)/2 @ '+'
.byte (BranchToHandleDash-PrintfBranchOnAsciiCharacter)/2 @ '-'
FillSpaceBetweenChars '-', '0', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.byte (BranchToHandleZero-PrintfBranchOnAsciiCharacter)/2 @ '0'
.rept 9 @ handle the digits [1-9]
	.byte (BranchToHandleDigits-PrintfBranchOnAsciiCharacter)/2 @ '[1-9]'
.endr
FillSpaceBetweenChars '9', 'X', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.byte (HandleBigX-PrintfBranchOnAsciiCharacter)/2 @ 'X' (in caps)
FillSpaceBetweenChars 'X', 'c', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.byte (HandleC-PrintfBranchOnAsciiCharacter)/2 @ 'c'
.byte (HandleD-PrintfBranchOnAsciiCharacter)/2 @ 'd'
FillSpaceBetweenChars 'd', 'h', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.byte (BranchToHandleH-PrintfBranchOnAsciiCharacter)/2 @ 'h'
.byte (HandleD-PrintfBranchOnAsciiCharacter)/2 @ 'i' @ same as 'd'
FillSpaceBetweenChars 'i', 'l', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.byte (BranchToHandleL-PrintfBranchOnAsciiCharacter)/2 @ 'l'
FillSpaceBetweenChars 'l', 'n', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.byte (HandleN-PrintfBranchOnAsciiCharacter)/2 @ 'n'
FillSpaceBetweenChars 'n', 'o', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.byte (HandleO-PrintfBranchOnAsciiCharacter)/2 @ 'o'
.byte (HandleP-PrintfBranchOnAsciiCharacter)/2 @ 'p'
FillSpaceBetweenChars 'p', 's', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.byte (HandleS-PrintfBranchOnAsciiCharacter)/2 @ 's'
FillSpaceBetweenChars 's', 'u', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.byte (HandleX-PrintfBranchOnAsciiCharacter)/2 @ 'x'
FillSpaceBetweenChars 'x', 256, (HandleOther-PrintfBranchOnAsciiCharacter)/2
@ 256==end of table

ArgAsciiTable: @ branch table used to branch inside ObtainValueFromNextArg 
@ (based on ascii character read from the argument string)

.byte (ArgHandleNullOrComma-OBFNABranchOnCharacter)/2 @ '\0'
FillSpaceBetweenChars '\0', '\t', (ErrorCharArg-OBFNABranchOnCharacter)/2
.byte (HandleWSP-OBFNABranchOnCharacter)/2 @ '\t'
@FillSpaceBetweenChars '\t', '\n', (ErrorCharArg-OBFNABranchOnCharacter)/2
.byte (HandleWSP-OBFNABranchOnCharacter)/2 @ '\n'
FillSpaceBetweenChars '\n', '\r', (ErrorCharArg-OBFNABranchOnCharacter)/2
.byte (HandleWSP-OBFNABranchOnCharacter)/2 @ '\r'
FillSpaceBetweenChars '\r', ' ', (ErrorCharArg-OBFNABranchOnCharacter)/2
.byte (HandleWSP-OBFNABranchOnCharacter)/2 @ ' '
FillSpaceBetweenChars ' ', '+', (ErrorCharArg-OBFNABranchOnCharacter)/2
.byte (ArgHandlePlus-OBFNABranchOnCharacter)/2 @ '+'
.byte (HandleNullOrComma-OBFNABranchOnCharacter)/2 @ ','
.byte (ArgHandleMinus-OBFNABranchOnCharacter)/2 @ '-'
FillSpaceBetweenChars '-', '0', (ErrorCharArg-OBFNABranchOnCharacter)/2
.byte (ArgHandleNaught-OBFNABranchOnCharacter)/2 @ '0'
.rept 9
	.byte (ArgHandleDigits-OBFNABranchOnCharacter)/2 @ '[1-9]'
.endr
FillSpaceBetweenChars '9', '[', (ErrorCharArg-OBFNABranchOnCharacter)/2
.byte (ArgHandleLeftBracket-OBFNABranchOnCharacter)/2 @ '['
FillSpaceBetweenChars '[', ']', (ErrorCharArg-OBFNABranchOnCharacter)/2
.byte (ArgHandleRightBracket-OBFNABranchOnCharacter)/2 @ ']'
FillSpaceBetweenChars ']', 'l', (ErrorCharArg-OBFNABranchOnCharacter)/2
.byte (ArgHandleL-OBFNABranchOnCharacter)/2 @ 'l'
FillSpaceBetweenChars 'l', 'p', (ErrorCharArg-OBFNABranchOnCharacter)/2
.byte (ArgHandleP-OBFNABranchOnCharacter)/2 @ 'p'
FillSpaceBetweenChars 'p', 'r', (ErrorCharArg-OBFNABranchOnCharacter)/2
.byte (ArgHandleR-OBFNABranchOnCharacter)/2 @ 'r'
.byte (ArgHandleS-OBFNABranchOnCharacter)/2 @ 's'
FillSpaceBetweenChars 's', 256, (ErrorCharArg-OBFNABranchOnCharacter)/2
@ end of table

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
