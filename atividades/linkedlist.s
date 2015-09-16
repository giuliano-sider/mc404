/******* lista_ligada.s *********
Programa simples em assembly para arm-none-eabi-gcc que produz uma lista ligada de inteiros
de 32 bits, em tempo de montagem, e depois imprime-a na saída padrão em tempo de execução.
Giuliano Sider, RA 146271, 06/09/2015
Disciplina MC 404 C
****************************/

/*
Teste 01: resultado incorreto

    1,32c1,32
    <    1 0001bb04
    <    3 0001bb0c
    <    5 0001bb14
    <    7 0001bb1c
    <    9 0001bb24
    <   11 0001bb2c
    <   13 0001bb34
    <   15 0001bb3c
    <   17 0001bb44

it works with a simple .align and .word 0, 0, 0, 0

*/


.syntax unified


.text
.align @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
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
	@cbz r5,finishedprint @arm mode problem???
	cmp r5, 0 @ ????? listcreate.s:34: Error: selected processor does not support ARM mode `cbz r5,finishedprint'
	beq finishedprint
	mov r0, r4 @ load formatted string 
	ldr r1, [r5], 4 @ load the key for printing
	ldr r2, [r5] @ load the address for printing
	mov r5, r2 @ load r5 with the address of the next node
	bl printf
	b printmore
	mov r0, r0
	mov r0, r0
	mov r0, r0
	mov r0, r0
	/*mov r0, r0
	mov r0, r0
	mov r0, r0
	mov r0, r0
	mov r0, r0
	mov r0, r0
	mov r0, r0
	mov r0, r0
	mov r0, r0
	mov r0, r0
	mov r0, r0
	mov r0, r0*/
finishedprint:
	/*mov r0, r4
	mov r1, 0
	mov r2, 0
	bl printf*/
	pop { r4-r6, pc }


Formato: .asciz "%4d %08x\n" @ integer key and address of next node


.data
.align @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@.word 0, 0, 0, 0
ListHead:
.equ i, 1
.equ address, ListHead + 8
.rept 32
	.word i, address
	.equ i, i + 2
	.equ address, address + 8
.endr
.word 0, 0 @ double NULL terminator of the list
