/******* lista_ligada.s *********
Programa simples em assembly para arm-none-eabi-gcc que produz uma lista ligada de inteiros
de 32 bits, em tempo de montagem, e depois imprime-a na saída padrão em tempo de execução.
Giuliano Sider, RA 146271, 06/09/2015
Disciplina MC 404 C
****************************/

.syntax unified
.align
.text
.global main

/*
function void PrintList(List *lista)
	This function prints a linked list of integers to the standard output. The integer of the
	last node should be zero, as well as the 'next' pointer. It takes a pointer to the list at r0,
	and clobbers r0-r3 as per the ARM calling convention. No return value.
	typedef struct lista { //size 8
		int key; //offset 0
		struct lista *next; //offset 4
	} List;
*/
main:
	push { lr }
	ldr r0, =ListHead
	bl PrintList
	pop { pc }

PrintList:
	push { r4-r6, lr }
	ldr r4, =Formato
	mov r5, r0
printmore:
	cbz r5, finishedprint @ null pointer: print it and return
	mov r0, r4 @ load formatted string 
	ldr r1, [r5], 4 @ load the key for printing
	ldr r2, [r5] @ load the address for printing
	mov r5, r2 @ load r5 with the address of the next node
	bl printf
	b printmore
finishedprint:
	/*mov r0, r4
	mov r1, 0
	mov r2, 0
	bl printf*/
	pop { r4-r6, pc }

.align
Formato: .asciz "%4d %08x\n" @ integer key and address of next node
.align
.data
ListHead:
.equ i, 1
.equ address, ListHead + 8
.rept 32
	.word i, address
	.equ i, i + 2
	.equ address, address + 8
.endr
.word 0, 0 @ double NULL terminator of the list
