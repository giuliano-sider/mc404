/* htonl.c   - inline example : converts a 32 bit value from
  little endian to bigendian or viceversa
  MC 404 Jun 2015 Prof. Célio
*/
#include <stdio.h>
unsigned long htonl(unsigned long val)
{
 asm volatile ("eor r3, %1, %1, ror #16\n\t"
 "bic r3, r3, #0x00FF0000\n\t"
 "mov %0, %1, ror #8\n\t"
 "eor %0, %0, r3, lsr #8"
 : "=r" (val)
 : "0"(val)
: "r3"
 );
 return val;
}
int main(){
   unsigned int val=0xaabbccdd;
   printf ("In line assembly example converts little endian to big endian:\n");
   printf ("%08x\n", val);
   val= htonl(val);
   //usanndo a instrução rev rd, rn do cortex m3 obtem o mesmo efeito:
   //asm("rev %0, %0": "+r" (val));
   // ou:
   //asm("rev %0, %0": "=r" (val): "0" (val));
   printf ("%08x\n", val);
   //asm ("mov %0, %1": "=r" (val): "I" (0x80 << 24));
   asm ("mov %0, %1": "=r" (val): "I" (0x00f000f0));
   printf ("%08x\n", val);
   
}

