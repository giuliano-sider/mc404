/* subsort.s - subroutine called frm a C progam
receives an array address in r0 and changes two elements of the array
should be a sorting routine...
*/
.syntax unified
.align
.text
.global insort
insort:
    push {r1,lr}
    mov r1,0xff
    str r1,[r0, 4] // stores ff at array[1]
    str r1,[r0, 8] // stores ff at array[2]
    pop {r1,pc}

