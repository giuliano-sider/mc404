/* ctinline.c   - inline exemplo: uso de constantes com inline assembly
  MC 404 Jun 2015 Prof. Célio
*/
#include <stdio.h>
#define const 31
#define JMPADDR 0xFFFFFF00
int main(){
   unsigned int val;
   asm ("mov %0, %1": "=r" (val): "I" (0x80 << 24));
   printf ("%08x\n", val); //exibe 80000000
   asm ("mov %0, %1": "=r" (val): "I" (0xf000f0));
   printf ("%08x\n", val); // exibe 00f00f0
   val=1;
   asm ("mov %0, %1, ror %2": "=r" (val): "0" (val), "M" (const) );
   printf ("%08x\n", val); // exibe 00000002

   asm volatile("mov %0, %1" : "=r" (val) : "r" (JMPADDR)); 
   printf ("%8x\n", val); // exibe FFFFFF00

   asm ("ldr r3,=0xfff000f0" "\n\t"
        "mov %0, r3" "\n\t"
        : "=r" (val) : : "r3"
       );
   printf ("%8x\n", val); // exibe fff000f0
}

