/* inline.c - exemplo do tutorial: gira -a direita 1 bit da variável val
   volatile: informa ao gcc para não excluir pelo otimizador o código assemnbler
*/
#include <stdio.h>
int main(){
   unsigned int val=1;
   #define const 31     // número de bits para girar a variável val no 2o teste
   asm volatile ("mov %0, %0, ror #1": "+r" (val) );
   //asm("mov %0, %0, ror #1": "=r" (val): "0" (val) ); // mesmo efeito que anterior
   printf ("%08x\n", val);  //exibe 80000000
   val=1;
   asm volatile ("mov %0, %1, ror %2": "=r" (val): "0" (val), "M" (const) );
   printf ("%08x\n", val);  // exibe 00000002


}

