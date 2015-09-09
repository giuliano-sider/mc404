/* nop.c   - inline assembly para executar um pequeno atraso
  usa o atributo volatile para informar ao gcc não otimizar 
   o código ema assembler (por exemplo eliminando-o!)
*/
int main(){
asm volatile(
   "mov r0, r0\n\t"     // \n\t "pretty printer" caso vá gerar um .s
   "mov r0, r0\n\t"
   "mov r0, r0"
   );
}
