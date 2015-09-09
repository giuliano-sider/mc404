/******* fib.s *********
Programa simples em assembly para arm-none-eabi-gcc que gera os números da sequência de
Fibonacci menores de 1000.
Giuliano Sider, RA 146271, 05/09/2015
Disciplina MC 404 C
***********************/

.syntax unified
.align
.text
.global main
main:
	push { lr }
	ldr r0, =FibRange
	ldr r0, [r0]
	bl PrintFibRange
	pop { pc }
/************************
function: void PrintFibRange(int UpperBound);
prints elements of the fibonacci sequence from 1 to UpperBound, which is passed in at r0.
returns nothing. clobbers r0-r3 (as per the ARM calling convention).
uses format string "%10d\n\0" to print out elements
************************/
PrintFibRange:
UpperBound .req r4 @this is the upper bound of the range of fibonacci values calculated
Fib_1 .req r5 @latest fibonacci element calculated
Fib_2 .req r6 @previous fibonacci value calculated
	mov UpperBound, r0
	push { r4-r6, lr }
	mov Fib_1, 1
	mov Fib_2, 1
	cmp UpperBound, Fib_1
	blt ExitPrintFibRange @only print up to a certain value given as argument
	ldr r0, =Formato
	mov r1, Fib_1
	bl printf
	ldr r0, =Formato
	mov r1, Fib_1
	bl printf @print the first 2 elements of the sequence: 1
FibLoop:
	mov r3, Fib_1 @temp workspace
	add r5, Fib_1, Fib_2
	mov Fib_2, r3
	cmp UpperBound, Fib_1
	blt ExitPrintFibRange @only print up to a certain value given as argument
	ldr r0, =Formato
	mov r1, Fib_1
	bl printf
	b FibLoop
ExitPrintFibRange:
	pop { r4-r6, pc }

.align
Formato: .ascii "%10d\n\0"

.data
.align
FibRange: .word 1000
