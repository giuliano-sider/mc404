/******* qsort.s *********
Programa simples em assembly para arm-none-eabi-gcc que ordena um vetor de inteiros de 32 bits
usando o algoritmo clássico do quicksort.
Giuliano Sider, RA 146271, 06/09/2015
Disciplina MC 404 C
****************************/

.syntax unified
.align
.text
.global main

/*
function void QuickSort(int *a, int n) : clobbers r0-r3, r12 (as per the ARM calling convention)
	: r0 => a, r1 => n.
	This function takes a pointer to an array of integers at r0,
	and the size (in number of integers)
	of the array in r1, and quicksorts the array. There is no return value, and registers
	r0-r3, r12 (ip) are clobbered as per the ARM calling convention.
Tightly coupled subroutines:
	(private) void qsort(int *a, int p, int r),
	(private) int partition(int *a, int p, int r)

void GenerateRandIntArray(int *a, int n) : clobbers r0-r3 : r0 => a, r1 => n
	@ generates an array of 32 bit random integers at an already allocated buffer pointed to by a
void PrintIntArray(int *a, int n) : clobbers r0-r3 : r0 => a, r1 => n
	@ prints array of 32 bit integers to stdout
int RandInt(int low_bound, int high_bound) : clobbers r0-r3 : r0 => low_bound, r1 => high_bound
	@ loads at r0 a (uniformly) random integer in the range [low_bound, high_bound]

*/



main: @ we generate a random array, print it, sort it, print it again
.equ qsort_BUFSIZE, 32 @ could consider making this variable (input from stdin?)
array .req r7 @ pointer to the array
arraysize .req r6 @ size of the array
	push { r4-r7, lr }
	mov arraysize, qsort_BUFSIZE
	ldr array, =InputTestVector
	/*sub sp, sp, arraysize, lsl 2 @ make room for an integer array on the stack
	mov array, sp*/

	/*mov r0, array
	mov r1, arraysize
	bl GenerateRandIntArray*/

main_printnsort:
	/*mov r0, array
	mov r1, arraysize
	bl PrintIntArray*/

	mov r0, array
	mov r1, arraysize
	bl QuickSort

	mov r0, array
	mov r1, arraysize
	bl PrintIntArray

	//add sp, sp, arraysize, lsl 2
	pop { r4-r7, pc }

QuickSort: 
array .req r7 @ pointer to the array
arraysize .req r6 @ size of the array
	push { r4-r7, lr }
	mov array, r0 
	mov arraysize, r1
	mov r0, 0 @ srand(time(NULL)) to seed the randomizer (pivot selection is random)
	bl time
	bl srand
	mov r0, 0
	mov r1, arraysize @ from now on, arraysize variable isn't used anymore
	sub r1, 1 @ QSort(array, 0, arraysize - 1) @ note that array is implicit (r7) and shared between the functions. ARM calling convention says it is not among the clobbered registers (r0-r3, r12)
	bl QSort 
	pop { r4-r7, pc }
QSort: @ recursive qsort routine: void QSort(int *array, int low_bound, int high_bound)
low_bound .req r5 @ sort array in the range [low_bound, high_bound]
high_bound .req r6
pivot_index .req r4 
	push { r4-r6, lr }
	cmp r0, r1 @ if p < r
	bge donesorting @ this is the recursive base case (empty array or singleton)
	mov low_bound, r0 
	mov high_bound, r1
	bl PartitionArray
	mov pivot_index, r0 @ pivot index has been returned by partition
	mov r0, low_bound
	sub r1, pivot_index, 1
	bl QSort @ Qsort( array, low_bound, pivot_index - 1)
	add r0, pivot_index, 1
	mov r1, high_bound
	bl QSort @ QSort ( array, pivotindex + 1, high_index ) @ remember: array is shared (in r7, which is a callee saved register)
donesorting:
	pop { r4-r6, pc }

/****** Pseudo code for the (midly tricky) partition subroutine:
Sub Partition (Array A, Integer low_bound, Integer high_bound) : returns Integer pivot_index
	
	q <- SelectRandPivot(low_bound, high_bound)
	pivotvalue <- A[q]
	Swap( A[q], A[high_bound] )
	i <- p - 1
	j <- p
	While j < high_bound, do: // partition loop
		if A[j] < pivotvalue
			i++
			Swap( A[i], A[j] )
		j++
	i++
	Swap( A[i], A[j] )
	return i // returning the pivot index

End Partition
The partition loop maintains the following invariant: at the start of each iteration,
the interval [low_bound, i] has only elements smaller than the pivot, the interval (i, j) has
only elements bigger than or equal to the pivot, and the interval [j, high_bound) has unknown
values. high_bound contains the pivot itself.
******/
PartitionArray: @ int Partition(int *array, int low_bound, int high_bound) @ returns index of the pivot in our partition of the array
pivotvalue .req r2
i .req r3
j .req r4
tempreg .req r1
element .req r0
	push { r4-r6, lr }
	mov low_bound, r0 @ low_bound == r5, high_bound == r6 (both defined above at qsort)
	mov high_bound, r1
	bl RandInt @ loads at r0 a (uniformly) random integer in the range [low_bound, high_bound]
	@ swap the random pivot with the last element of the array
		ldr pivotvalue, [array, r0, lsl 2] @ r0 has the random pivot index
		ldr tempreg, [array, high_bound, lsl 2]
		str tempreg, [array, r0, lsl 2]
		str pivotvalue, [array, high_bound, lsl 2]
	sub i, low_bound, 1 @ i initialized to low_bound - 1: "smaller than pivot" set, [low_bound, i], is empty
	mov j, low_bound @ nothing in between i and j: "bigger than pivot" set, (i, j), is empty
partitionloop:
	cmp j, high_bound
	beq partitiondone
	ldr element, [array, j, lsl 2]
	cmp element, pivotvalue @ if array[j] < pivotvalue
	bge biggerorequaltopivot @ if the element is bigger than or equal to pivot, expand "bigger than" set by incrementing j
	add i, 1 @ element is smaller than pivot: expand "smaller than" set by incrementing i
	ldr tempreg, [array, i, lsl 2] @ swap array[i] and array[j] after incrementing i
	str tempreg, [array, j, lsl 2]
	str element, [array, i, lsl 2] 
biggerorequaltopivot:
	add j, 1 @ now inspect the next element
	b partitionloop
partitiondone:
	add i, 1 @ swap an element bigger than the pivot to the end
	ldr tempreg, [array, i, lsl 2] 
	str tempreg, [array, high_bound, lsl 2]
	str pivotvalue, [array, i, lsl 2] @ and move the pivot into its rightful place
	mov r0, i @ return pivot index
	pop { r4-r6, pc }

RandInt: @ int RandInt(int low_bound, int high_bound)
range .req r1 @ return a (uniformly) distributed integer in the range [low_bound, high_bound]
q .req r2
	push { r4-r6, lr }
	mov low_bound, r0 @ low_bound == r5, high_bound == r6 (both defined above at qsort)
	mov high_bound, r1
	bl rand @ 32 bit (pseudo) random integer at r0
	sub range, high_bound, low_bound
	add range, 1 @ high_bound - low_bound + 1 is the size of desired interval
	udiv q, r0, range @ q = floor ( rnd / range ). REFRESHER: UDIV {Rd}, Rm, Rn. Rd := Rm / Rn
	mls r0, q, range, r0 @ rnd - q*range = remainder. REFRESHER: MLS {Rd}, Rm, Rn, Ra. Rd := Ra - Rm*Rn
	add r0, low_bound @ now r0 has an integer plucked from a uniform [low_bound, high_bound] distribution
	pop { r4-r6, pc }

GenerateRandIntArray:
	push { r4-r5, lr }
	mov r4, r0 @ array pointer
	sub r5, r1, 1 @ offset into the array
	mov r0, 0 @ srand(time(NULL)) to seed the randomizer
	bl time
	bl srand
gen32bitnumber:
	bl rand @ loads (pseudo) random 32 bit integer to r0
	str r0, [r4, r5, lsl 2] @ save rand to array
	subs r5, 1 @ next rand
	bpl gen32bitnumber @ when countdown reaches 0, we've generated n numbers: done
	pop { r4-r5, pc }

PrintIntArray:
	push { r4-r6, lr }
	mov r4, 0 @ index
	mov r5, r1 @ array size
	mov r6, r0 @ array pointer
printnext:
	cmp r4, r5
	bge exitprintarray @ until we get to the end of the array, print
	ldr r0, =PrintFormat
	ldr r1, [r6, r4, lsl 2]
	bl printf
	add r4, 1
	b printnext
exitprintarray:
	mov r0, '\n'
	bl putchar
	/*mov r0, '\n'
	bl putchar*/
	pop { r4-r6, pc }
.align
PrintFormat: .asciz "%08x\n" @ standard format for SUSY submission

.data @ (shuffled) input vector for SUSY submission
.align
InputTestVector:
.word 0x4d9a2fdb
.word 0x6fa72ca5
.word 0x08cdb7ff
.word 0x0ae16fd9
.word 0x70a3a52b
.word 0x0d1f0796
.word 0x1a8b7f78
.word 0x20fd5db4
.word 0x37521657
.word 0x2aa84157
.word 0x502959d8
.word 0x7d8341fc
.word 0x04185faf
.word 0x28e4baf1
.word 0x7043bfa4
.word 0x40b18ccf
.word 0x0cab8628
.word 0x58a0df74
.word 0x30705b04
.word 0x3477d43f
.word 0x398150e9
.word 0x2e533cc4
.word 0x40f7702c
.word 0x6c0356a7
.word 0x47033129
.word 0x76035e09
.word 0x474a0364
.word 0x4bb5f646
.word 0x2b894868
.word 0x742d2f7a
.word 0x6de3b115
.word 0x5851f42d
