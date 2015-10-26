#include <stdio.h>

int reverse_nibble(int nibble);

int main() {
	int i, uppernibble, lowernibble;
	printf(".byte ");
	for(i = 0; i < 256; i++) {
		uppernibble = i >> 4;
		lowernibble = i & 15;
		lowernibble = reverse_nibble(lowernibble);
		uppernibble = reverse_nibble(uppernibble);
		printf("%i%c", ( lowernibble << 4 ) | uppernibble , i==255 ? '\n' : ',');
	}
}

int reverse_nibble(int nibble) {
	int nibbles[16] = { 0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15};
	return nibbles[nibble];
}

/*
	0	<->   0
	1	<->   8
	2	<->   4
	3	<->   C
	4	<->   2
	5	<->   A
	6	<->   6
	7	<->   E
	8	<->   1
	9	<->   9
	A	<->   5
	B	<->   D
	C	<->   3
	D	<->   B
	E	<->   7
	F   <->   F
*/