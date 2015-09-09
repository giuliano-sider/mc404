/* rev.s  -- conversão de"endian format"
 converte 32 bits de "little endian" para "big endian" e vice versa
 ARM usa "little endian" pacotes na Internet usam "big endian"
 thumb2 tem uma instrução especícfica para isto "rev rd,rn"
O ARM convencional requer uma rotina (complexa!)com 5 instruções
Desafio: prove que ela funciona qualquer que seja a entrada!
*/
.syntax unified
    .align 
    .text
    .global main
main:
    push {lr}
        ldr r1,=0xaabbccdd
        rev r2,r1
    ldr r0, =msg
    bl printf
    pop {pc}
msg: .string "antes: %10x após rev: %10x\n"

