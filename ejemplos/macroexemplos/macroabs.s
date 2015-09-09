/*macroabs.s   -  exemplo de macro que usa geracao de  rotulos locais via contador interno \@
	       - obtem o valor absoluto de um inteiro com sinal passado no registrador a
	       - MC404 Abr 2015
*/
.syntax unified
.align
.text
.global main
.macro  abs a		@ computes the absolute value of integer in register a
        cmp \a, #0
        bmi neg\@
        b done\@
neg\@:  rsb \a, #0
done\@:
.endm

main:
    push {lr}
    mov r1, #5
    abs r1
   bl print
    mov r1,#-5
    abs r1
    bl print	@ will exibit 5
    pop  {pc}
print: 
    push {lr}
    ldr r0,=fmt
    bl printf
    pop {pc}
fmt: .asciz "%d\n"


