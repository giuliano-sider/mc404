
/* to complile C program and generate C with assembler listing file type:
gcc -c -g -Wa,-a,-ad prog.c > prog.lst
*/
@format.s - using printf to display numerical values
@ up to 3 values can be displayed (in r1, r2, r3) 

.syntax unified
    .align 
    .text
    .global main
main:
    push {lr}
    mov r1,#19
    mov r2,#22
    mov r3,#33
    bl myprintf
    pop {pc}
myprintf:
    push {r0-r3, lr}
    ldr r0, =fmtmsg
    bl printf	@ displays r1,r2 and r3 using format in fmtmsg
                @ printf destroys r0,r1,r2,r3
    pop {r0-r3, pc}
fmtmsg: .ascii  "Hora Local: %2d hs %2d min %2d s\n\0"

