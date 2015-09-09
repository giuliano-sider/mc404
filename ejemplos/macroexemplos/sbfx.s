/*  sbfx.s   - macro para emulas a instruc√ßa√sbfx rd, rn, sbit, nbits
   onde rd e rn sao registradores (<r8), sbit e nbitrs sao constantes (0..31)
*/
.syntax unified
.align
.text
.global main
.macro sbfx rd,rn, sbit,nbits	@macro to emulate sbfx instruction
	lsl \rn, 32-(\sbit+\nbits)  @ posiciona campo a partir do bit 31 de rn
	asr \rd, \rn, 32-\nbits     @ desloca com sinal para os nbits - signif
.endm
main:
    push {lr}
    ldr r1, = 0xef8bcd
    mov r0, -1
    sbfx r0, r1, 8, 8
    mov r1, r0
    bl print		@ exibe ffffff8b
    ldr r1, = 0xef7bcd
    sbfx r0, r1, 8, 8
    mov r1,r0
    bl print		@ exibe 0000007b
   pop {pc}

print: 
    push {lr}
    ldr r0,=fmt
    bl printf
    pop {pc}
fmt: .asciz "%08x\n"


