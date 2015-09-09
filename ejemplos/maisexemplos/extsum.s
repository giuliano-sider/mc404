/* extsum.s      - soma com precisão estendida
   a rotina extsum soma dois vetores de inteiros no formato little endian apontados por r1 e r2
   colocando a soma no vetor apontado por r1
   r3= tamanho do vetor em palavras (>0) 
   trata idiosincrasia do ARM no que diz respeito ao bit de CY
Prof  Celio - MC404 2013
*****************************************************************************/
    .syntax unified
    .text
    .align 2
    .global main
@*******************************************************************************
extsum:    @ sum integer pointed by r2 to integer pointed by r1
           @ r3 = lenght in words
	cmn r3, #0    @ clear CY; alternately, msr cpsr, #0 - clear flags in cpsr 
l0:     
	ldr r4,[r1]
	ldr r5, [r2],#4
        adcs r4,r5
        str r4, [r1],#4
        bcc cyclear
        subs r3,#1   
        bne l0	      @ if r3>0 CY continues set!	
        mov pc,lr     @ return to caller
cyclear:	      @ sum did not set CY, so it must be clear for next sum!
        subs r3, #1
        bne extsum   @ CY must be clear before reentering loop!
        mov pc,lr    @ return to caller
@*******************************************************************************
main:
    push {lr}
	ldr r1,=vet1
        ldr r2, =vet2
        mov r3, #len
        bl extsum
    pop {pc}
@*******************************************************************************
    .data
    .align 2
vet1: .word -1,-1,-1,0
.equ len, (. - vet1)/4
vet2: .word -1,-1,-1,0
.end
vet1: .word 1,2,3,4
vet2: .word 1,2,3,4
