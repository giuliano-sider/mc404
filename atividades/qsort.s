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
function void qsort(int *a, int n)
	This function takes a pointer to an array of integers at r0,
	and the size (in number of integers)
	of the array in r1, and quicksorts the array. There is no return value, and registers
	r0-r3, r12 (ip) are clobbered as per the ARM calling convention.
	(private) Subroutines: void qsort_recursive(int *a, int p, int r),
	(private) int partition(int *a, int p, int r),

	 void GenerateRandIntArray(int *a, int n) : clobbers r0-r3
	 void PrintIntArray(int *a, int n) : clobbers r0-r3. prints array to stdout
	 TO DO: inline asm, and timer (gettimeofday, struct timeval...)

*/



main:
.equ qsort_BUFSIZE, 100 @ could consider making this variable (input from stdin?)
array .req r7 @ pointer to the array
arraysize .req r6 @ size of the array
	push { r4-r7, lr }
	mov arraysize, qsort_BUFSIZE
	sub sp, sp, arraysize, lsl 2 @ make room for an integer array
	mov array, sp

	mov r0, array
	mov r1, arraysize
	bl GenerateRandIntArray

main_printnsort:
	mov r0, array
	mov r1, arraysize
	bl PrintIntArray

	mov r0, array
	mov r1, arraysize
	bl QuickSort

	mov r0, array
	mov r1, arraysize
	bl PrintIntArray

	add sp, sp, arraysize, lsl 2
	pop { r4-r7, pc }

QuickSort: 
array .req r7 @ pointer to the array
arraysize .req r6 @ size of the array
	push { r4-r7, lr }
	mov array, r0 
	mov arraysize, r1
	mov r0, 0 @ srand(time(NULL)) to seed the randomizer
	bl time
	bl srand
	mov r0, 0
	mov r1, arraysize
	sub r1, 1 @ QSort(array, 0, arraysize - 1) @ note that array is implicit (r7) and shared between the functions. ARM calling convention says it is not among the clobbered registers (r0-r3, r12)
	bl QSort
	pop { r4-r7, pc }
QSort: @ void QSort(int *array, int low_bound, int high_bound)
low_bound .req r5
high_bound .req r6
	push { r4-r6, lr }
	cmp r0, r1 @ if p < r
	bge donesorting @ this is the recursive base case (empty array or singleton)
	mov low_bound, r0
	mov high_bound, r1
	bl PartitionArray
	mov r4, r0 @ pivot index has been returned by partition
	mov r0, low_bound
	sub r1, r4, 1
	bl QSort @ Qsort( array, low_bound, pivotindex - 1)
	add r0, r4, 1
	mov r1, high_bound
	bl QSort @ QSort ( array, pivotindex + 1, high_index )
donesorting:
	pop { r4-r6, pc }

PartitionArray: @ int Partition(int *array, int low_bound, int high_bound) @ returns index of the pivot in our partition of the array
pivotvalue .req r0
i .req r3
j .req r4
tempreg .req r1
	push { r4-r6, lr }
	mov low_bound, r0
	mov high_bound, r1
	bl rand
	sub r1, r6, r5
	add r1, 1 @ range of numbers in the array
	udiv r2, r0, r1 @ q = floor ( rnd / range )
	mls r2, r2, r1, r0 @ rnd - q*range = remainder
	add r2, low_bound @ now r2 has an integer plucked from a uniform [low_bound, high_bound] distribution
	ldr r0, [array, r2, lsl 2] @ r0 is the pivotvalue now
	ldr tempreg, [array, high_bound, lsl 2] @ swap the pivot to the end of the array
	str tempreg, [array, r2, lsl 2]
	str pivotvalue, [array, high_bound, lsl 2]
	sub i, low_bound, 1 @ i initialized to low_index - 1: smaller than pivot set is empty
	mov j, low_bound @ nothing in between i and j: bigger than pivot set is empty
partitionloop:
	cmp j, high_bound
	beq partitiondone
	ldr tempreg, [array, j, lsl 2]
	cmp tempreg, pivotvalue @ if array[j] < pivotvalue
	bge biggerorequaltopivot
	add i, 1
	ldr r2, [array, i, lsl 2] @ swap array[i] and array[j] after incrementing i
	str r2, [array, j, lsl 2]
	str tempreg, [array, i, lsl 2] 
biggerorequaltopivot:
	add j, 1
	b partitionloop
partitiondone:
	add i, 1 @swap an element bigger than the pivot to the end
	ldr tempreg, [array, i, lsl 2] 
	str tempreg, [array, high_bound, lsl 2]
	str pivotvalue, [array, i, lsl 2] @ and move the pivot into its rightful place
	mov r0, i @ return pivot index
	pop { r4-r6, pc }

GenerateRandIntArray:
	push { r4-r5, lr }
	mov r4, r0 @ array pointer
	sub r5, r1, 1 @ offset into the array
	mov r0, 0 @ srand(time(NULL)) to seed the randomizer
	bl time
	bl srand
gen32bitnumber:
	bl rand
	str r0, [r4, r5, lsl 2] @ save rand to array
	subs r5, 1 @ next rand
	bpl gen32bitnumber @ gotta generate n numbers as passed in from r1
	pop { r4-r5, pc }

PrintIntArray:
	push { r4-r6, lr }
	mov r4, 0 @ index
	mov r5, r1 @ array size
	mov r6, r0 @ array pointer
printnext:
	cmp r4, r5
	bge exitprintarray @until we get to the end of the array, print
	ldr r0, =PrintFormat
	ldr r1, [r6, r4, lsl 2]
	bl printf
	add r4, 1
	b printnext
exitprintarray:
	mov r0, '\n'
	bl putchar
	mov r0, '\n'
	bl putchar
	pop { r4-r6, pc }

.align
PrintFormat: .asciz "%08X\n"
