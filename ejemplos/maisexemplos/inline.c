#include <stdio.h>
int rdv=10;
int wdv=100;
int table[]= {-1,2,3,4,5,6,7,8};
int main(){
int i;
asm volatile("ldr %0, [%1]"     "\n\t"
             "str %2, [%1, #4]" "\n\t"
             "str %0, [%1, #8]" "\n\t"
             : "=&r" (rdv)
             : "r" (&table), "r" (wdv)
             : "memory");
for (i=0; i<=7; i++)
    printf ("%d\n", table[i]);

}
