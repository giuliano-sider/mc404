/* gdbtest.s - Exemplo para ser testado com gdb
  possui um erro que faz o programa entrar em loop
  MC404c Set 2014
*/
.syntax unified
.data
.align
oddtab: .word 3,5,7,9,11,0xffffffff
.align 
.text
.global main
main:
    push {lr}
    ldr r0,=oddtab
loop:
    ldr r1,[r0],#4
    bl debug
    cmp r0,#0xffffffff
    bne loop
    pop {pc}
@_________________________________________________________
debug:
    push {r0-r3,lr}
    ldr r0, =msg
    bl printf
    pop {r0-r3,pc}
@_________________________________________________________
msg: .string "Next table entry: %10d\n"

