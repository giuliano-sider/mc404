#include <stdio.h>
int rand();
void showarray(unsigned int *); 
void sort (unsigned int l,unsigned int r,unsigned int *a){
	unsigned int i,j,x,w;
	i=l; j=r;
	x= a[(l+r)/2];
	do{
		while (a[i] < x)
			i++;
		while (x < a[j])
			j--;
		if (i<=j){
			w=a[i]; a[i]=a[j]; a[j]=w;
			i++; j--;
		}
	}while (i<=j);
	if (l<j) sort (l,j,a);
	if (i<r) sort (i,r,a);
}
#define N 32
unsigned int array[N+1];
int main(){
unsigned int i;
     for (i=1; i<=N; i++){
         array[i]= rand();
    }
    sort(1,N,array);
    showarray(array);
    return 0;
}
void showarray(unsigned int * a){
unsigned int i;
 for (i=1; i<=N; i++){
       printf("%08x\n",a[i]);
 }
}

