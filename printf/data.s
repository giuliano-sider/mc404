@ data section for the printf executable

@ branch tables can go on flash memory

.macro FillSpaceBetweenChars charfrom, charto, value @ 2 chars, charto>charfrom, 1 number
@ used for filling out spaces between notable characters in an ascii indexed branch table
	.rept (\charto - \charfrom) - 1
		.hword \value
	.endr
.endm @ could use this to fill the branch tables instead

// we use four byte aligned branch locations.
FormatStrAsciiTable:  @ branch table used to branch inside printf 
@ (based on ascii character read from the format string)
.byte (BranchToHandleNullByte-PrintfBranchOnAsciiCharacter)/4 @ '\0'
.rept ' ' - 1
	.byte (HandleOther-PrintfBranchOnAsciiCharacter)/4
.endr
@FillSpaceBetweenChars '\0', ' ', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.byte (BranchToHandleSpace-PrintfBranchOnAsciiCharacter)/4 @ ' '
@FillSpaceBetweenChars ' ', '#', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept '#' - ' ' - 1
	.byte (HandleOther-PrintfBranchOnAsciiCharacter)/4
.endr
.byte (BranchToHandlePound-PrintfBranchOnAsciiCharacter)/4 @ '#'
@FillSpaceBetweenChars '#', '%', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept '%' - '#' - 1
	.byte (HandleOther-PrintfBranchOnAsciiCharacter)/4
.endr
.byte (BranchToHandlePercent-PrintfBranchOnAsciiCharacter)/4 @ '%'
@FillSpaceBetweenChars '*', '%', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept '*' - '%' - 1
	.byte (HandleOther-PrintfBranchOnAsciiCharacter)/4
.endr
.byte (BranchToHandleStar-PrintfBranchOnAsciiCharacter)/4 @ '*'
.byte (BranchToHandlePlus-PrintfBranchOnAsciiCharacter)/4 @ '+'
.byte (HandleOther-PrintfBranchOnAsciiCharacter)/4
.byte (BranchToHandleDash-PrintfBranchOnAsciiCharacter)/4 @ '-'
@FillSpaceBetweenChars '-', '0', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept '0' - '-' - 1
	.byte (HandleOther-PrintfBranchOnAsciiCharacter)/4
.endr
.byte (BranchToHandleZero-PrintfBranchOnAsciiCharacter)/4 @ '0'
.rept 9 @ handle the digits [1-9]
	.byte (BranchToHandleDigits-PrintfBranchOnAsciiCharacter)/4 @ '[1-9]'
.endr
@FillSpaceBetweenChars '9', 'X', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept 'X' - '9' - 1
	.byte (HandleOther-PrintfBranchOnAsciiCharacter)/4
.endr
.byte (HandleBigX-PrintfBranchOnAsciiCharacter)/4 @ 'X' (in caps)
@FillSpaceBetweenChars 'X', 'c', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept 'c' - 'X' - 1
	.byte (HandleOther-PrintfBranchOnAsciiCharacter)/4
.endr
.byte (HandleC-PrintfBranchOnAsciiCharacter)/4 @ 'c'
.byte (HandleD-PrintfBranchOnAsciiCharacter)/4 @ 'd'
@FillSpaceBetweenChars 'd', 'h', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept 'h' - 'd' - 1 
	.byte (HandleOther-PrintfBranchOnAsciiCharacter)/4
.endr
.byte (BranchToHandleH-PrintfBranchOnAsciiCharacter)/4 @ 'h'
.byte (HandleD-PrintfBranchOnAsciiCharacter)/4 @ 'i' @ same as 'd'
@FillSpaceBetweenChars 'i', 'l', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept 'l' - 'i' -1
	.byte (HandleOther-PrintfBranchOnAsciiCharacter)/4
.endr
.byte (BranchToHandleL-PrintfBranchOnAsciiCharacter)/4 @ 'l'
@FillSpaceBetweenChars 'l', 'n', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept 'n'- 'l' - 1
	.byte (HandleOther-PrintfBranchOnAsciiCharacter)/4
.endr
.byte (HandleN-PrintfBranchOnAsciiCharacter)/4 @ 'n'
@FillSpaceBetweenChars 'n', 'o', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept 'o' - 'n' - 1
	.byte (HandleOther-PrintfBranchOnAsciiCharacter)/4
.endr
.byte (HandleO-PrintfBranchOnAsciiCharacter)/4 @ 'o'
.byte (HandleP-PrintfBranchOnAsciiCharacter)/4 @ 'p'
@FillSpaceBetweenChars 'p', 's', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept 's' - 'p' - 1
	.byte (HandleOther-PrintfBranchOnAsciiCharacter)/4
.endr
.byte (HandleS-PrintfBranchOnAsciiCharacter)/4 @ 's'
@FillSpaceBetweenChars 's', 'u', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept 'u' - 's' - 1
	.byte (HandleOther-PrintfBranchOnAsciiCharacter)/4
.endr
.byte (HandleU-PrintfBranchOnAsciiCharacter)/4 @ 'u'
.rept 'x' - 'u' - 1
	.byte (HandleOther-PrintfBranchOnAsciiCharacter)/4
.endr
.byte (HandleX-PrintfBranchOnAsciiCharacter)/4 @ 'x'
@FillSpaceBetweenChars 'x', 256, (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept 256 - 'x' - 1
	.byte (HandleOther-PrintfBranchOnAsciiCharacter)/4
.endr


/*
FormatStrAsciiTable:  @ branch table used to branch inside printf. some branches are sort of long, so we use hword
@ (based on ascii character read from the format string)
.hword (BranchToHandleNullByte-PrintfBranchOnAsciiCharacter)/2 @ '\0'
.rept ' ' - 1
	.hword (HandleOther-PrintfBranchOnAsciiCharacter)/2
.endr
@FillSpaceBetweenChars '\0', ' ', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.hword (BranchToHandleSpace-PrintfBranchOnAsciiCharacter)/2 @ ' '
@FillSpaceBetweenChars ' ', '#', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept '#' - ' ' - 1
	.hword (HandleOther-PrintfBranchOnAsciiCharacter)/2
.endr
.hword (BranchToHandlePound-PrintfBranchOnAsciiCharacter)/2 @ '#'
@FillSpaceBetweenChars '#', '%', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept '%' - '#' - 1
	.hword (HandleOther-PrintfBranchOnAsciiCharacter)/2
.endr
.hword (BranchToHandlePercent-PrintfBranchOnAsciiCharacter)/2 @ '%'
@FillSpaceBetweenChars '*', '%', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept '*' - '%' - 1
	.hword (HandleOther-PrintfBranchOnAsciiCharacter)/2
.endr
.hword (BranchToHandleStar-PrintfBranchOnAsciiCharacter)/2 @ '*'
.hword (BranchToHandlePlus-PrintfBranchOnAsciiCharacter)/2 @ '+'
.hword (HandleOther-PrintfBranchOnAsciiCharacter)/2
.hword (BranchToHandleDash-PrintfBranchOnAsciiCharacter)/2 @ '-'
@FillSpaceBetweenChars '-', '0', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept '0' - '-' - 1
	.hword (HandleOther-PrintfBranchOnAsciiCharacter)/2
.endr
.hword (BranchToHandleZero-PrintfBranchOnAsciiCharacter)/2 @ '0'
.rept 9 @ handle the digits [1-9]
	.hword (BranchToHandleDigits-PrintfBranchOnAsciiCharacter)/2 @ '[1-9]'
.endr
@FillSpaceBetweenChars '9', 'X', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept 'X' - '9' - 1
	.hword (HandleOther-PrintfBranchOnAsciiCharacter)/2
.endr
.hword (HandleBigX-PrintfBranchOnAsciiCharacter)/2 @ 'X' (in caps)
@FillSpaceBetweenChars 'X', 'c', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept 'c' - 'X' - 1
	.hword (HandleOther-PrintfBranchOnAsciiCharacter)/2
.endr
.hword (HandleC-PrintfBranchOnAsciiCharacter)/2 @ 'c'
.hword (HandleD-PrintfBranchOnAsciiCharacter)/2 @ 'd'
@FillSpaceBetweenChars 'd', 'h', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept 'h' - 'd' - 1 
	.hword (HandleOther-PrintfBranchOnAsciiCharacter)/2
.endr
.hword (BranchToHandleH-PrintfBranchOnAsciiCharacter)/2 @ 'h'
.hword (HandleD-PrintfBranchOnAsciiCharacter)/2 @ 'i' @ same as 'd'
@FillSpaceBetweenChars 'i', 'l', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept 'l' - 'i' -1
	.hword (HandleOther-PrintfBranchOnAsciiCharacter)/2
.endr
.hword (BranchToHandleL-PrintfBranchOnAsciiCharacter)/2 @ 'l'
@FillSpaceBetweenChars 'l', 'n', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept 'n'- 'l' - 1
	.hword (HandleOther-PrintfBranchOnAsciiCharacter)/2
.endr
.hword (HandleN-PrintfBranchOnAsciiCharacter)/2 @ 'n'
@FillSpaceBetweenChars 'n', 'o', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept 'o' - 'n' - 1
	.hword (HandleOther-PrintfBranchOnAsciiCharacter)/2
.endr
.hword (HandleO-PrintfBranchOnAsciiCharacter)/2 @ 'o'
.hword (HandleP-PrintfBranchOnAsciiCharacter)/2 @ 'p'
@FillSpaceBetweenChars 'p', 's', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept 's' - 'p' - 1
	.hword (HandleOther-PrintfBranchOnAsciiCharacter)/2
.endr
.hword (HandleS-PrintfBranchOnAsciiCharacter)/2 @ 's'
@FillSpaceBetweenChars 's', 'u', (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept 'u' - 's' - 1
	.hword (HandleOther-PrintfBranchOnAsciiCharacter)/2
.endr
.hword (HandleU-PrintfBranchOnAsciiCharacter)/2 @ 'u'
.rept 'x' - 'u' - 1
	.hword (HandleOther-PrintfBranchOnAsciiCharacter)/2
.endr
.hword (HandleX-PrintfBranchOnAsciiCharacter)/2 @ 'x'
@FillSpaceBetweenChars 'x', 256, (HandleOther-PrintfBranchOnAsciiCharacter)/2
.rept 256 - 'x' - 1
	.hword (HandleOther-PrintfBranchOnAsciiCharacter)/2
.endr
*/

ArgAsciiTable: @ branch table used to branch inside ObtainValueFromNextArg 
@ (based on ascii character read from the argument string)

.byte (ArgHandleNullOrComma-OBFNABranchOnCharacter)/2 @ '\0'
@FillSpaceBetweenChars '\0', '\t', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept 8 @ up to \t (cant rely on assemblers with crap parsers)
	.byte (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.byte (HandleWSP-OBFNABranchOnCharacter)/2 @ '\t'
@FillSpaceBetweenChars '\t', '\n', (ErrorCharArg-OBFNABranchOnCharacter)/2
.byte (HandleWSP-OBFNABranchOnCharacter)/2 @ '\n'
@FillSpaceBetweenChars '\n', '\r', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept 2 @.rept '\r' - '\n' - 1
	.byte (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.byte (HandleWSP-OBFNABranchOnCharacter)/2 @ '\r'
@FillSpaceBetweenChars '\r', ' ', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept ' ' - '\r' - 1
	.byte (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.byte (HandleWSP-OBFNABranchOnCharacter)/2 @ ' '
@FillSpaceBetweenChars ' ', '+', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept '+' - ' ' - 1
	.byte (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.byte (ArgHandlePlus-OBFNABranchOnCharacter)/2 @ '+'
.byte (ArgHandleNullOrComma-OBFNABranchOnCharacter)/2 @ ','
.byte (ArgHandleMinus-OBFNABranchOnCharacter)/2 @ '-'
@FillSpaceBetweenChars '-', '0', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept '0' - '-' - 1
	.byte (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.byte (ArgHandleNaught-OBFNABranchOnCharacter)/2 @ '0'
.rept 9
	.byte (ArgHandleDigits-OBFNABranchOnCharacter)/2 @ '[1-9]'
.endr
@FillSpaceBetweenChars '9', '[', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept '[' - '9' - 1
	.byte (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.byte (ArgHandleLeftBracket-OBFNABranchOnCharacter)/2 @ '['
@FillSpaceBetweenChars '[', ']', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept ']' - '[' - 1
	.byte (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.byte (ArgHandleRightBracket-OBFNABranchOnCharacter)/2 @ ']'
@FillSpaceBetweenChars ']', 'l', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept 'l' - ']' - 1
	.byte (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.byte (ArgHandleL-OBFNABranchOnCharacter)/2 @ 'l'
@FillSpaceBetweenChars 'l', 'p', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept 'p' - 'l' - 1
	.byte (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.byte (ArgHandleP-OBFNABranchOnCharacter)/2 @ 'p'
@FillSpaceBetweenChars 'p', 'r', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept 'r' - 'p' - 1
	.byte (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.byte (ArgHandleR-OBFNABranchOnCharacter)/2 @ 'r'
.byte (ArgHandleS-OBFNABranchOnCharacter)/2 @ 's'
@FillSpaceBetweenChars 's', 256, (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept 255 - 's'
	.byte (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr


/*
ArgAsciiTable: @ branch table used to branch inside ObtainValueFromNextArg 
@ (based on ascii character read from the argument string)

.hword (ArgHandleNullOrComma-OBFNABranchOnCharacter)/2 @ '\0'
@FillSpaceBetweenChars '\0', '\t', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept 8 @ up to \t (cant rely on assemblers with crap parsers)
	.hword (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.hword (HandleWSP-OBFNABranchOnCharacter)/2 @ '\t'
@FillSpaceBetweenChars '\t', '\n', (ErrorCharArg-OBFNABranchOnCharacter)/2
.hword (HandleWSP-OBFNABranchOnCharacter)/2 @ '\n'
@FillSpaceBetweenChars '\n', '\r', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept 2 @.rept '\r' - '\n' - 1
	.hword (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.hword (HandleWSP-OBFNABranchOnCharacter)/2 @ '\r'
@FillSpaceBetweenChars '\r', ' ', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept ' ' - '\r' - 1
	.hword (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.hword (HandleWSP-OBFNABranchOnCharacter)/2 @ ' '
@FillSpaceBetweenChars ' ', '+', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept '+' - ' ' - 1
	.hword (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.hword (ArgHandlePlus-OBFNABranchOnCharacter)/2 @ '+'
.hword (ArgHandleNullOrComma-OBFNABranchOnCharacter)/2 @ ','
.hword (ArgHandleMinus-OBFNABranchOnCharacter)/2 @ '-'
@FillSpaceBetweenChars '-', '0', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept '0' - '-' - 1
	.hword (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.hword (ArgHandleNaught-OBFNABranchOnCharacter)/2 @ '0'
.rept 9
	.hword (ArgHandleDigits-OBFNABranchOnCharacter)/2 @ '[1-9]'
.endr
@FillSpaceBetweenChars '9', '[', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept '[' - '9' - 1
	.hword (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.hword (ArgHandleLeftBracket-OBFNABranchOnCharacter)/2 @ '['
@FillSpaceBetweenChars '[', ']', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept ']' - '[' - 1
	.hword (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.hword (ArgHandleRightBracket-OBFNABranchOnCharacter)/2 @ ']'
@FillSpaceBetweenChars ']', 'l', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept 'l' - ']' - 1
	.hword (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.hword (ArgHandleL-OBFNABranchOnCharacter)/2 @ 'l'
@FillSpaceBetweenChars 'l', 'p', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept 'p' - 'l' - 1
	.hword (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.hword (ArgHandleP-OBFNABranchOnCharacter)/2 @ 'p'
@FillSpaceBetweenChars 'p', 'r', (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept 'r' - 'p' - 1
	.hword (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
.hword (ArgHandleR-OBFNABranchOnCharacter)/2 @ 'r'
.hword (ArgHandleS-OBFNABranchOnCharacter)/2 @ 's'
@FillSpaceBetweenChars 's', 256, (ErrorCharArg-OBFNABranchOnCharacter)/2
.rept 255 - 's'
	.hword (ErrorCharArg-OBFNABranchOnCharacter)/2
.endr
*/


DigitsLookup:
.byte '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'x'

DigitsLookupCaps:
.byte '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', 'X'


.align
.data @ the stuff up there can safely reside in flash memory, but everything downstairs is modified at runtime


.align
PrintCharStaticVars: @ for functions that do printing (static store)
	@ stores regvar_buffer, regvar_buffercount, regvar_printedchars, regvar_outputfunc
.word 0, 0, 0, 0

TheUserStack: @ we keep values of the user registers here
.rept 16
	.word 0
.endr
		
ArgValue: // keeps values of argument fetched from the argument string, (in ObtainValueFromNextArg)
// and value calculated if using registers values as arguments (that is, not a buffer/number in memory)
.rept 16 @ enough to store the three arguments from the argument specifier
	.byte 0
.endr

@ OUTPUTSTRINGSIZE >= Ceil ( (8*MAXNUMBERSIZE)/3 ) // worst case is printing octal digits
.equ BUFFERSIZE, 32 @ this is the internal print buffer. it could be replaced entirely by a, say, str instruction to some output device, which would also eliminate the need for outputfunc, for that matter
	@ actual size of buffer that holds chars before they go out to outputfunc
.equ MAXNUMBYTESIZE, 16 @ we can print-format numbers of up to this many bytes
	@ maximum number of bytes a number (in memory) can have and still be print-formatted by
	@ our printf (given in the "lengthspec" field of the format specifier)
.equ OUTPUTSTRINGSIZE, (8*MAXNUMBYTESIZE)/3 + 1 @ big enough to hold ceil(MAXNUMBYTESIZE*8/3) octal digits
	@ this buffer holds the formatted print number's ascii codes before it is dispatched to the internal print buffer

Buffer: // buffer that stores the string to be passed to outputfunc
@ space time tradeoff: make the buffer big and outputfunc will be called only once as a result
.rept BUFFERSIZE+1  @ important to have the \0 terminator for the 'full buffer flushes'
	.byte 0
.endr

OutputString: // keeps ascii characters while processing before printout
.rept OUTPUTSTRINGSIZE + 1 @ could keep the \0 terminator so we can flush this beast as a string
	.byte 0
.endr
.align

Number: // keeps internal representation of number (unsigned) for manipulation
.rept MAXNUMBYTESIZE // ceiling of maximum bytelength/4
	.byte 0
.endr

.align @ this message is customizable... we can't really put it in flash (aprox. 200 bytes)
ErrorCharArgMsg:
	.ascii "Error: detected an invalid "
ArgStrOffendingChar: @ place here the offending spurious character to be reported in an error message
	.byte 0
	.ascii " character at position\n"
ArgStrOffendingCharPosition: @ place where we store the index.
	.ascii "        " @ 8 blanks. replace this with number indicating offset of invalid character
	.asciz " in an argument specifier in the argument string\n"
.align

ErrorCharMsg:
	.ascii "Error: detected an invalid "
OffendingChar: @ place here the offending spurious character to be reported in an error message
	.byte 0
	.ascii " character at position\n"
OffendingCharPosition: @ place where we store the index.
	.ascii "        " @ 8 blanks. replace this with number indicating offset of invalid character
	.asciz " in a format specifier in the format string\n"
.align

