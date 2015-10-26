/************ MC404C, Giuliano Sider, 20/10/2015 *************
*** Atividade Desafio (MINI CHALLENGE 1)
We use a 256 byte lookup table to immediately reverse the individual bytes of the input word.
Thanks to the M3 Cortex instruction set, we can do the whole operation in 13 instructions;
if we could afford a 128K lookup table (probably not on an embedded device), then we could
do it in 7 instructions.

FUNCTION: rbit_emulate: @ int rbit_emulate(int i)
INPUT: r0 = > 32 bit integer
OUTPUT: r0 = > 32 bit integer, every bit reversed
SIDE EFFECTS: clobber r1-r3
NOTE: 

*************************************************************/

.syntax unified
.text
.global main
.align
main:
	ldr r0, =Prompt
	bl printf
	ldr r0, =Input
	ldr r1, =UserInput
	bl scanf
	ldr r0, =UserInput
	ldr r0, [r0]
	bl rbit_emulate
	mov r1, r0
	ldr r0, =Output
	bl printf
	b main @ press ctrl-c to quit

Prompt: .asciz "enter 32 bit integer in hex format\n"
Input: .asciz " %08x"
Output: .asciz "reversed integer: %08x\n"

rbit_emulate: @ int32 rbit_emulate(int32 i) out: r0 (reversed_i), in: r0 (i), clobber: r1-r3
	ubfx r1, r0, 0, 8 @ swap the two reversed bytes at the ends
	ubfx r2, r0, 24, 8
	ldr r3, =ReverseByteLookUp @ base address of lookup table
	ldrb r1, [r3, r1]
	ldrb r2, [r3, r2]
	bfi r0, r1, 24, 8
	bfi r0, r2, 0, 8
	ubfx r1, r0, 8, 8 @ now swap the middle two reversed bytes
	ubfx r2, r0, 16, 8
	ldrb r1, [r3, r1]
	ldrb r2, [r3, r2]
	bfi r0, r1, 16, 8
	bfi r0, r2, 8, 8
mov pc, lr

ReverseByteLookUp:
.byte 0,128,64,192,32,160,96,224,16,144,80,208,48,176,112,240,8,136,72,200,40,168,104,232
.byte 24,152,88,216,56,184,120,248,4,132,68,196,36,164,100,228,20,148,84,212,52,180,116,244
.byte 12,140,76,204,44,172,108,236,28,156,92,220,60,188,124,252,2,130,66,194,34,162,98,226,18
.byte 146,82,210,50,178,114,242,10,138,74,202,42,170,106,234,26,154,90,218,58,186,122,250,6
.byte 134,70,198,38,166,102,230,22,150,86,214,54,182,118,246,14,142,78,206,46,174,110,238,30
.byte 158,94,222,62,190,126,254,1,129,65,193,33,161,97,225,17,145,81,209,49,177,113,241,9,137
.byte 73,201,41,169,105,233,25,153,89,217,57,185,121,249,5,133,69,197,37,165,101,229,21,149
.byte 85,213,53,181,117,245,13,141,77,205,45,173,109,237,29,157,93,221,61,189,125,253,3,131
.byte 67,195,35,163,99,227,19,147,83,211,51,179,115,243,11,139,75,203,43,171,107,235,27,155
.byte 91,219,59,187,123,251,7,135,71,199,39,167,103,231,23,151,87,215,55,183,119,247,15,143
.byte 79,207,47,175,111,239,31,159,95,223,63,191,127,255

/* special thanks to the C language
int main() {
	int nibbles[16] = { 0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15};
	int i, uppernibble, lowernibble;
	printf(".byte ");
	for(i = 0; i < 256; i++) {
		uppernibble = i >> 4;
		lowernibble = i & 15;
		lowernibble = nibbles[lowernibble];
		uppernibble = nibbles[uppernibble];
		printf("%i%c", ( lowernibble << 4 ) | uppernibble , i==255 ? '\n' : ',');
	}
}
*/
.data
UserInput: .word 0
