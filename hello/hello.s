.syntax unified
.align 
.text
.global main
main:
    push {lr}
    ldr r0, =Hellomessage
    bl printf
    pop {pc}
Hellomessage: .string "Hello World!\n"

