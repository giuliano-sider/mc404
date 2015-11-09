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
	ldr r0, =PromptString
	ldr r1, =FormatString
	ldr r2, =ArgumentString @ read 2 strings from the user
	bl scanf
	cmp r0, 2 @ check if input was read (both format specifiers having been filled)
	bne InputError
	ldr r0, =puts @ glibc function used for writing string to stdout 
	ldr r1, =FormatString
	ldr r2, =ArgumentString
	bl printf_baremetal
	cmp r0, -1
	itt eq
	ldreq r0, [sp] @ load error message
	bleq puts
	b UserPromptLoop
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

WelcomeMsg: .asciz "Welcome to the printf bare metal test module. The world's finest bare metal ARM assembly printf. ^D to quit\n"
UserPromptMsg: .asciz "USAGE: <FormatString> \\n <ArgumentString> \\n > "
PromptString: " %1023[^\n] %1023[^\n]" @ should be enough for testing purposes
GoodbyeMsg: .asciz "thanks for testing out the world's finest when it comes to printfs. buhbye\n"

.align
printf_baremetal: 
@ int printf_baremetal( int (*outputfunc)(const char*) , const char *formatstr, const char *argstr)
@ outputfunc used for testing is puts (wrapper not necessary in asm: no typing)
push { r0-r12, lr } @ we keep track of sp. lr is pc. original lr is not available, clobbered during branch and link.





pop { r0-r12, pc }


.data
.align
.equ bufsize_format, 1024 @ store user inputted format string: should be enough for testing purposes
.equ bufsize_argument, 1024 @ store user inputted argument string: should be enough for testing purposes

FormatString: 
.rept bufsize_format
	.byte 0
.endr

ArgumentString:
.rept bufsize_argument
	.byte 0
.endr









Pseudo Code for mitigating psychological torture during the assembly coding process:
/**************
in C:
int printf ( int (*outputfunc) (const char *), const char *formatstr, const char *argstr);

grammar of printf:
int printf( <outputfunc>, <format str>, <arg str> ) // follows ARM calling convention

outputfunc := function that takes a pointer to a nul-terminated array of characters and 
prints it to standard output. the function returns an integer (model is puts from libc)

format str := string containing regular characters and '%' followed by format specifications.
format specification := %[flags][width][lengthspec]specifier
arg str := string containing comma separated list of arguments. whitespace is ignored.
argument := [ '[' ] <reg>|<const> [+- <reg>|<const> [lsl <reg>|<const>]] [ "]" ]
reg := r0|r1| ... r15 @ but not lr==r14
const := [0x|0]<digits>
***************/
printedchars = 0 // characters actually flushed via outputfunc
i = 0 @ index along the FormatString, next character to be read
j = 0 @ index along the argument string, next character to be read
buffer = set to N + 1 zero bytes. // keep characters printed here until flushed via outputfunc
buffersize = N // we are guaranteed to have a nul byte terminator
buffercount = 0
state = readformatstr // start by reading the format string
width = 0
lengthspec = 4 // how many bytes to consider in value to be formatted: hh: 1, h: 2, default: 4, l: 8, ll: 16
flags = none // #, 0, ' ', +, -
specifier = none // c, d, i, o, n, p, s, u, x, X
outputstring = <pointer to buffer>
finishedargs = false

stack variables: outputfunc, printedchars, finishedargs (least used)
registers: formatstr, argstr, i, j, buffersize, buffercount, state, width, flags
			outputstringlength, radix, 
			(in ObtainValueFromNextArg): argstate, offset,  arg, addressmode 
buffers: outputstring (64 bytes is more than enough), buffer (1024 might be good), args (just 12 bytes is enough)


while formatstr[i] != 0
	
	if state == readformatstr

		if formatstr[i] == '%' @ begin reading format specifier
			state = readflags
		else @ just copy the character from the formatstr to the output buffer
			PrintChar( formatstr[i] )
		i++

	else if state == readflags

		if formatstr[i] == '-'
			if flags.dash == 1 
				error "extra dash in format specifier flags field"
				return -1
			else 
				flags.dash = 1
				i++
		else if formatstr[i] == '+'
			if flags.plus == 1 
				error "extra plus in format specifier flags field"
				return -1
			else 
				flags.plus = 1
				i++
		else if formatstr[i] == ' '
			if flags.space == 1 
				error "extra space in format specifier flags field"
				return -1
			else 
				flags.space = 1
				i++
		else if formatstr[i] == '#'
			if flags.pound == 1 
				error "extra pound sign in format specifier flags field"
				return -1
			else 
				flags.pound = 1
				i++
		else if formatstr[i] == '0'
			if flags.zero == 1 
				error "extra zero in format specifier flags field"
				return -1
			else 
				flags.zero = 1
				i++
		else
			state = readwidth // no more flags

	else if state == readwidth

		if formatstr[i] == '*'
			width = *( ObtainValueFromNextArg(4 bytes) ) // arg preceding argument to be formatted carries (32 bit) width value
			i++
		else
			 // width==0 implies no minimum number of characters to be printed
			while formatstr[i] == '0' || '1' || '2' || '3' || '4' || '5' || '6' || '7' || '8' || '9' 
				width = width * 10 + (asciicode(formatstr[i])-30) // decodes number in string as a decimal integer. 30 is code for 0, 31, for 1, etc
				i++
		state = readlengthspec

	else if state == readlengthspec

		if formatstr[i] == 'h'
			if formatstr[i+1] == 0
				Error "format string ended in the middle of a format specifier"
				return -1
			else if formatstr[i+1] == 'h'
				lengthspec = 1 // specifier hh: 1 byte
				i = i + 2
			else
				lengthspec = 2 // specifier h: 2 bytes
				i++
		else if formatstr[i] == 'l'
			if formatstr[i+1] == 0
				Error "format string ended in the middle of a format specifier"
				return -1
			else if formatstr[i+1] == 'l'
				lengthspec = 16 // specifier ll: 16 bytes
				i = i + 2
			else
				lengthspec = 8 // specifier l: 8 bytes
				i++
		state = readformatspecifier

	else if state == readformatspecifier

		if formatstr[i] =='c'
			specifier = c
			if flags != < '-' only>
				error " '#', '+', ' ', '0' flags not in use with specifier c"
				return -1
			if lengthspec != 4 // default: 4 bytes
				error "length modifier not valid with c format specifier"
				return -1
		else if formatstr[i] == 'd' | 'i'
			specifier = d
			radix = 10
		else if formatstr[i] == 'n'
			specifier = n
			if flags != none || width != 0 || lengthspec != 4
				error "format specifier n doesn't take any additional parameters"
				return -1
		else if formatstr[i] == 'o'
			specifier = o
			radix = 8
		else if formatstr[i] == 'p' // our standard for printing pointers
			flags = <0, # flags set>
			width = 8
			specifier = x
			radix = 16
		else if formatstr[i] == 'u'
			specifier = u
			radix = 10
		else if formatstr[i] == 'x'
			specifier = x
			radix = 16
		else if formatstr[i] == 'X'
			specifier = X
			radix = 16
		else if formatstr[i] == 's'
			specifier = s
			if flags != < '-' only>
				error " '#', '+', ' ', '0' flags not in use with specifier s"
				return -1
			if lengthspec != 4 // default: 4 bytes
				error "length modifier not valid with s format specifier"
				return -1

		else if formatstr[i] == '%'
			PrintChar ( '%' )
			state = readformatstr
			specifier = none
			if width !=0 || flags != none || lengthspec != 4 // default: 4 bytes
				error "useless information was passed to %% specifier"
				return -1
		else
			error "illegal format specifier used"
			return -1

		if specifier != none // not % specifier; there is an argument to be read
			state = readformatarg // proceed to obtain arg
			if finishedargs == true // but we already exhausted the argstr
				error "missing arguments at the end of argument string" 
				return -1
	
		i++ // consume the format specifier character

	else if state == readformatarg

		value = ObtainValueFromNextArg( lengthspec ) // !!already comes !no! dereferenced!! in the case of [] in the argstr
		valuelength = ceil(lengthspec/4)
// value is a vector of ceil(lengthspec/4) words in memory containing the value to be formatted according to the specifiers
		outputstring = empty
		outputstringlength = 0

		if specifier == n // value is a pointer to some location that will store a 32 bit integer
			*( :lower32: value) = printedchars + buffercount // store, at the address given (value), the number of character outputted so far
			state = readformatstr
		else if specifier == c
			value[1] = :lower8: value[0] followed by null byte 
			value[0] = &value[1] // value is indexed by word, remember
			fall through next else if // treat character like a length 1 string
		else if specifier == 's' // another special case is that of a string
			string = ( :lower32: value ) // value here is a pointer to the nul terminated string
			len = StrLen( string )
			if flags.dash is unset // no dash - the default - is right justify the field
				for s = 0 to width - len (NOT INCLUDING width - len) // default width is 0, which means this for loop is correctly ignored
					PrintChar ( ' ' ) // left padding with blanks to make up the width
				for s = 0 to len (NOT INCLUDING len)
					PrintChar ( string[s] )
			else // dash means left justify
				for s = 0 to len (NOT INCLUDING len)
					PrintChar ( string[s] )
				for s = 0 to width - len (NOT INCLUDING width - len)
					PrintChar ( ' ' ) // right padding with blanks to make up the width
			state = readformatstr
		else // the other format specifiers are all numbers 
			char lookuptable[] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'A', 'B', 'C', 'D' 'E', 'F' }
			sign = positive
			if specifier == 'd'
				if most_significant_bit(value[valuelength-1]) == 1
					sign = negative
					twoscomplement( value, valuelength )

			while ! iszero( value, valuelength )
				r = div_vector_by_int16( value, valuelength, radix ) // this functions changes value to quotient
				// start copying to outputstring (in little endian order, although in the screen we see big endian).
				if specifier == 'X'
					outputstring[outputstringlength] = lookuptable[r+6] // load capital letter
				else
					outputstring[outputstringlength] = lookuptable[r]
				outputstringlength++

			if flags.plus == true && flags.space == true // space flag just gives you a space in place of the sign (if sign is positive)
				error "+ flag takes precedence over the space flag (contradictory flags)"
				return -1
			
			if outputstringlength == 0 // value is zero
				outputstring[0] = '0'
				outputstringlength = 1
			else 
				if flag.pound == true
					if specifier == o
						outputstring[outputstringlength] = '0'
						outputstringlength++
					else if specifier == x
						outputstring[outputstringlength] = 'x'
						outputstringlength++
						outputstring[outputstringlength] = '0'
						outputstringlength++
					else if specifier == X
						outputstring[outputstringlength] = 'x'
						outputstringlength++
						outputstring[outputstringlength] = '0'
						outputstringlength++
			if sign == negative
				outputstring[outputstringlength] = '-'
				outputstringlength++
			else
				if flags.plus == true
					outputstring[outputstringlength] = '+'
					outputstringlength++
				else if flags.space == true
					outputstring[outputstringlength] = ' '
					outputstringlength++
			// take care of left justification and width. then actually print
			if flag.dash == true
				for s = (outputstringlength-1) down to 0 // INCLUDING zero
					PrintChar( outputstring[s] )
				for s = 0 to width - outputstringlength // pad with space | zeroes to complete the minimum width
					if flags.zero == true
						PrintChar( '0' )
					else
						PrintChar( ' ' )
			else // dash flag unset: default, right justify field
				for s = 0 to width - outputstringlength // pad with space | zeroes to complete the minimum width
					if flags.zero == true
						PrintChar( '0' )
					else
						PrintChar( ' ' )
				for s = (outputstringlength-1) down to 0 // INCLUDING zero
					PrintChar( outputstring[s] )


		// outside the arg reading while loop

		// reset the state machine to default settings to continue reading the format string
		width = 0
		flags = none
		lengthspec = 4
		specifier = none
		state = readformatstr


// outside the while loop
if state != readformatstr
	error "format string ended in the middle of a format specifier"
	return -1

if buffercount > 0 // print whatever is left in the buffer
	buffer[buffercount] = 0 // nul terminator
	outputfunc(buffer) 
	printedchars = printedchars + buffercount // does not include the nul terminator

return printedchars

inline function PrintChar(char printthis)

	if buffercount == buffersize
		outputfunc(buffer)
		buffercount = 0
		printedchars = printedchars + buffersize
	buffer[buffercount] = printthis
	buffercount++
proceed

// not an inline function, but it shares the same scope as printf:
int *ObtainValueFromNextArg (int numbytes) 
// we treat the returned 'value' as a little endian vector of ceil(numbytes/4) words, which simplifies our decoding of the 'value' into decimal, octal, hexadecimal of different lengths
// parse the argument string to obtain the value that will be formatted above

argstate = matchleftbracket
addressmode = false
arg = 0
offset = unset

int args[3] = { 0, 0, 0 } // 3 places to put registers/constants to compose value/address
// j is the index along the argument string

if finishedargs==true
	error "missing argument in argument string"
	return -1

while argstr[j] != \0 && j != ',' // read an argument up to comma or end of argument string 

	if argstr[j] == '\t' || '\n' || '\r' || ' '
		j++ // ignore whitespace
	else
		if argstate == matchleftbracket
			if argstr[j] == '['
				addressmode = true
				argstate = readarg
				j++ // consume the [
			else
				addressmode = false
				argstate = readarg
		else if argstate == readarg
			if argstr[j] == '0' // should be an octal or hex constant, look ahead
				if argstr[j+1] == 'x' || 'X'
					j = j + 2
					if argstr[j] != '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' | 'a' | 'b' | 'c' | 'd' | 'e' | 'f' | 'A' | 'B' | 'C' | 'D' | 'E' | 'F'
						error "expected a hex constant in the argument string"
						return -1
					args[arg] = ReadHexNumber()
					arg++
					
				else if argstr[j+1] == '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'
					j++
					args[arg] = ReadOctalNumber()
					arg++
					
				else 
					error "expected a constant in argument specifier"
					return -1
			else if argstr[j] == '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'
				args[arg] = ReadDecNumber()
				arg++
				
			else if argstr[j] == 'r'
				j++
				register = ReadDecNumber()
				if register < 0 || register>15
					error "invalid register specified in argument string"
					return -1
				if register == 14
					error "link register cannot be accessed by printf. it contains the contents of pc before the call"
					return -1
				args[arg] = GetRegisterValue ( register )
				arg++
				
			else if argstr[j] == 's'
				if argstr[j+1] == 'p'
					register=13
					args[arg] = GetRegisterValue ( register )
					arg++
					j = j + 2
					
				else 
					error "invalid argument starting with s in argument string"
					return -1
			else if argstr[j] == 'p'
				if argstr[j+1] == 'c'
					register=15
					args[arg] = GetRegisterValue ( register )
					arg++
					j = j + 2
					
				else 
					error "invalid argument starting with p in argument string"
					return -1
			
			else if argstr[j] == '+'
				error "misplaced + sign in the argument string"
				return -1
			else if argstr[j] == '-'
				error "misplaced - sign in the argument string"
				return -1
			else if argstr[j] == 'l'
				if argstr[j+1] == 's' && argstr[j+2] == 'l'
					error "misplaced shift directive in argument string"
					return -1
				else if argstr[j+1] == 'r'
					error "link register cannot be accessed by printf; it contains the contents of pc before the call"
					return -1
			else
				error "unkwown sequence in the argument string"
				return -1


			if arg==3
				argstate = matchrightbracket
			else if arg==1
				argstate = matchsign
			else if arg==2
				argstate = matchshift
			else
				error " ???? "
				return -1

		else if argstate == matchsign
			if argstr[j] == '+'
				offset = positive
				argstate = readarg
			else if argstr[j] == '-'
				offset = negative
				argstate = readarg
			else
				error "must specify the sign if offset argument is specified"
			j++

		else if argstate == matchshift
			if argstr[j] == 'l'
				if argstr[j+1] == 's' && argstr[j+2] == 'l'
					argstate = readarg
				else
					error "invalid character in argument string"
					return -1
			else
				error "lsl must be specified if third argument is used in argument string"
				return -1


		else if argstate == matchrightbracket
			if argstr[j] == ']'
				if addressmode == false
					error "syntax error: mismatched ] in argument string"
					return -1
				argstate = argcomplete
				j++ // consume the ]
			else
				error "invalid character at the end of argument in arg string"
				return -1
 

if argstate == readarg // expecting an argument
	error "syntax error in argument string, incomplete argument specification"
	return -1

if offset == negative
	arg[1] = -arg[1]
val = arg[0] + ( arg[1] << arg[2]) // the default for args 1 and 2 is zero

if addressmode == false // value in a register modified by constant
	value [0..3] = val // store value in memory and return the vector. could use arg buffer as the value (works too)
	for s = 4 to numbytes-1
		value[s] = 0 // pad with zeroes in case the user wants, say, a long integer (8 bytes)
if addressmode == true // use a vector of numbytes from memory
	value = val // already a vector in memory

if argstr[j] == 0
	finishedargs = true

return value


int ReadDecNumber() // internal to ObtainValueFromNextArg
	val = 0
	while str[j] == '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'
		val = val*10 + (str[j]-30) // decode ascii into actual number
		j++
return val
int ReadOctalNumber() // internal to ObtainValueFromNextArg
	val = 0
	while argstr[j] == '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7'
		val = val*8 + (argstr[j]-30) // decode ascii into actual number
		j++
return val
int ReadHexNumber() // internal to ObtainValueFromNextArg
	val = 0
	while 1
		if argstr[j] == '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'
			val = val*16 + (argstr[j]-30) // decode ascii into actual number
		else if argstr[j] == 'a' | 'b' | 'c' | 'd' | 'e' | 'f'
			val = val*16 + (argstr[j] - (('a')-10) )
		else if argstr[j] == 'A' | 'B' | 'C' | 'D' | 'E' | 'F'
			val = val*16 + (argstr[j] - (('A')-10) )
		else
			break
		j++
return val

			
return val

// divides the vector (in little endian format) of 'numwords' words, 'value', by an up to 16 bit 'divisor'. returns remainder. quotient is stored in value
int div_vector_by_int16(value, numwords, divisor)
// inside this function we treat value as a vector of numwords/2 halfwords (and we index it as a vector of bytes)

	r = 0
	for i = (numwords/2 - 1) down to 0
		q = (r*2^16 + value[i])/divisor
		r = (r*2^16 + value[i]) - q*divisor
		value[i] = q // we clobber the value with the quotient as a convenience for this application
return r

int iszero ( value, numwords ) // returns 1 if number represented in vector value, of numwords words, is zero. returns zero otherwise.

	for i = 0 to numwords-1
		if value[i] != 0
			return 1
return 0


void twoscomplement(value, numwords) // obtains the two's complement of this vector of numwords words in little endian form

	for i = 0 to numwords-1
		value[i] = ~value[i]
	i = -1
	for i = 0 to numwords-1
		value[i]++ // update carry flag
		if carryflagclear
			break
return

// does not count the \0 terminator, like the libc version
int StrLen( const char *string )
	
	length = 0
	while string[length] != 0
		length++
return length
