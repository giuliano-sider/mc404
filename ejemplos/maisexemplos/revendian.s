/* revendian.s
	- invertendo a "endianess" dos bytes num registrador
        - dada uma constante em r1 a rotina "magica" xcghendian a seguir inverte os bytes de r1, ou seja,
        - se r1 contem o valor 0x12345678 passa a ter o valor 0x78563412
	- Desafio: prove que a rotina esta' correta usando a definicao do "ou exclusivo", 
        - e que ela eh comutativa, lembrando que: d eor d = 0, qualquer que seja o valor de d.
	- MC404 2o sem 2013  Prof. Celio*/
.syntax unified
    .data
    .align 2
msgdes: .asciz " dada um valor em r1 a rotina "magica" xcghendian a seguir inverte os bytes de r1:\n \
- por exemplo, se r1 contem o valor 0x12345678 passa a ter o valor 0x78563412\n \
- Desafio: prove que a rotina esta' correta usando a definicao de ou exclusivo,\n \
- que ele e' comutativo e que: d eor d = 0, qualquer que seja o valor de d.\n\n"

initmsg: .asciz "valor inicial de r1= %x\n"
endmsg:   .asciz  "valor final de r1 (em hexa)= %x \n"
    .text
    .align 2 
    .global main
main:
    push {lr}
    ldr r0,=msgdes
    bl printf
    ldr r1,=0x12345678
    push {r1}
    ldr r0,=initmsg
    bl printf
    pop {r1}
    bl xchgendian
    ldr r0,=endmsg
    bl printf
    pop {pc}
@*****************************************************************************************
xchgendian:	@ inverte os bytes no registrador r1,
		@ ou seja, troca a "endianess" do conteudo de r1
		@ destroi r2
    eor r2,r1,r1, ror #16
    bic r2, #0x00ff0000	  @ "bit clear": zera em r2 os bits 1 na mascara nao altera os outros
    mov r1, r1, ror #8
    eor r1, r1, r2, lsr #8
    mov pc,lr
@ bic acima equivale a: and r2, 0x11001111

