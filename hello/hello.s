.syntax unified
.align 
.text
.global main
main: 
    push {lr}
    ldr r0, =Hellomessage
    movs r1, 4
    subs r1, 8
    bl printf
    pop {pc}
.align
/*.octa 0x4*/
Hellomessage: .asciz "Hello World!\n"

