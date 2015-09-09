
/* macro-calls-macro.s	- exemplo de invocação de macro no corpo de outra macro
	a macro sumabs invoca 2 vezes a macro abs para obter os valores absolutos
dos registradores a e b e em seguida calcula a sua soma
/*

/*  iabs.s   -  exemplo de macro que usa geracao de  rotulo locais \@
	- obtem o valor absoluto de um inteiro com sinal passado no registrador a
*/
.syntax unified
.align
.text
.global main
.macro  abs a	@ computes the absolute value of register a
        cmp \a, #0
        bmi neg\@
        b done\@
neg\@: rsb \a, 0
done\@:
.endm
.macro sumabs sum, a, b @ sum absolute values of registers a,b
	abs \a
	abs \b
	add \sum, \a, \b
.endm
main:
    push {lr}
    mov r1, 5
    mov r2, -15
    sumabs r3, r1, r2
    mov r1, r3
    ldr r0,=fmt    
    bl printf
    pop  {pc}
fmt: .asciz "5 + |-15| = %d\n"


