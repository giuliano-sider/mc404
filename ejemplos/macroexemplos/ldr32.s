/* ldr32.s		@ macro para substituir ldr reg, =constante32
   sem usar a "literal pool" para armazenar a constante32 no código
*/
.syntax unified
.thumb
.text
.align 
.global main
.macro ldr32 reg, const32   @ macro substitui instrucao ldr r0,=const32
    movw \reg, :lower16:\const32
    movt \reg, :upper16:\const32
.endm
main:
     push {lr}
     ldr32 r0,myword	@ r0 := ender de myword
     ldr r1, [r0]	@ r1:= conteudo de myword
     ldr r0,=fmt
     bl printf		@ exibe aabbccdd
     pop {pc}
fmt: .asciz "%8x\n"
.data
.align
myword: .word 0xaabbccdd
