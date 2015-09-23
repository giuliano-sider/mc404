/******* lista_ligada.s *********
Programa simples em assembly para arm-none-eabi-gcc que produz uma lista ligada de inteiros
de 32 bits, em tempo de montagem, e depois imprime-a na saída padrão em tempo de execução.
Esses inteiros, após a modificação do enunciado, devem armazenar a sequência de Fibonacci
até que os números não caibam mais numa palavra de 32 bits. (47 números no total)
Giuliano Sider, RA 146271, 06/09/2015
Disciplina MC 404 C
****************************/



.syntax unified


.text
.align
.global main

/*
function void PrintList(List *lista, int howmanytoprint)
	This function prints an array of key/value pairs to the standard output.
	It takes a pointer to the list at r0, the (positive) number of pairs to print at r1,
	and clobbers r0-r3 as per the ARM calling convention. No return value. Format of key/value pairs:
	typedef struct node {
		unsigned char key;
		unsigned int value;
	} Node;
*/
main:
	push { lr }
	ldr r0, =ListHead
	mov r1, 47 @ only the first 47 numbers of the fibonacci sequence can fit in a 32 bit word; this could be checked at runtime using the carry flag
	bl PrintList
	pop { pc }

PrintList:
	push { r4-r6, lr }
	ldr r4, =Formato @ doesn't get bumped by printf here: r4 is callee saved
	mov r5, r0 @ address of array
	mov r6, r1 @ number of pairs left to print
printmore:
	mov r0, r4 @ load format string
	ldrb r1, [r5], 1 @ load the key for printing
	ldr r2, [r5], 4 @ load the address for printing
	bl printf
	subs r6, 1
	bne printmore @ if r6 (number left to print) is zero, goodbye

	pop { r4-r6, pc }


Formato: .asciz "%4d %u\n" @ byte sized key, unsigned integer value


.data @ montagem da lista em tempo de ... montagem
.align
ListHead:
	.byte 1
	.word 1
	.byte 2
	.word 1 @ initialize the fibonacci sequence
	.equ fib_current, 1
	.equ fib_old, 1
	.equ i, 3
	.rept 45 @ only the first 47 numbers of the fibonacci sequence can fit in a 32 bit word; this could be checked at runtime using the carry flag
		.equ temp, fib_current + fib_old @ supported by GNU??
		.byte i
		.word temp
		.equ fib_old, fib_current
		.equ fib_current, temp
		.equ i, i + 1	
	.endr

/*ListHead: @ this is the old assignment, but it doesn't work all that well with Susy
.equ i, 1
.equ address, ListHead + 8
.rept 32
	.word i, address
	.equ i, i + 2
	.equ address, address + 8
.endr
.word 0, 0 @ double NULL terminator of the list
*/