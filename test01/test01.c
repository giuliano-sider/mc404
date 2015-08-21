#include <stdio.h>

int main(){

  unsigned int a, b, c, d, e, f;
  unsigned char k;
  unsigned int *p_a = &a;
  
  //exercicio1
  a |= 1 << k; //liga o k esimo bit da variavel a
  a &= ~(1 << k); //desliga o k esimo bit da variavel a
  a = ~a; //inverte (complemento de um) os bits da variavel
  *p_a = *p_a | b;

  printf("hi\n");
  
  return 0;
}

  
