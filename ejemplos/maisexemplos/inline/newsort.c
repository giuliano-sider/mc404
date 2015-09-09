//insort.c   - insertion sort of array[1] ... array[N]

#include <stdio.h>
void insort(unsigned int a[]);  // external subroutine in assembler
#define N 32
unsigned int array[N+1];
int main(){
        unsigned int i;
        for (i=1; i<=N; i++){   // fill array with N random integers
            array[i]= rand();
    }
        array[0]=N;
        //showarray(array);
        insort(array);		// calls external assemby routine
        showarray(array);	// and shows array
}
int showarray(unsigned int * a){
        unsigned int i;
        int n=a[0];
        for (i=1; i<=n; i++)
           printf("%08x\n",a[i]);
}

