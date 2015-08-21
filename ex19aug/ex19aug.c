#include <stdio.h>
#include <stdlib.h>

//BIT FIELD CLEAR
void bfc(unsigned int *dest, unsigned int src, const int sbit, const int nbits);

int main(){

  unsigned int test_src, test_dest;
  puts("enter a 32 bit hexadecimal integer for testing:");
  scanf("%8x", &test_src);
  
  bfc(&test_dest, test_src, 5, 14); // numbers for testing bfc
  printf("%#08X", test_dest);
  

  return 0;
}

void bfc(unsigned int *dest, unsigned int src, const int sbit, const int nbits){

  unsigned int mask = (unsigned int) -1 >> (32 - nbits); //we use 32 bit words
  mask <<= sbit;
  mask = ~mask;
  *dest = src & mask;

}
