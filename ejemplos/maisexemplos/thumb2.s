@tumb2.s   exemplo de instrucoes de 16 bits
@MC404	1o Semestre 2015

.syntax unified
.thumb
.align
.text
.global main
main:
   push {lr}
   mov R11, R12       @ para quaisquer registradores Rd e Rs
   add R11,R12        @ para quaisquer registradores Rd e Rs
   movs R7, 0xff      @ Rd < 8, cte 8 bits
   adds R7, #255      @ Rd < 8, cte 8 bits
   adds R0, R7,#7     @ Rd, Rn < 8, cte 3 bits
   lsls  R0, R7, #0x1f @   Rd, Rn < 8, cte 5 bits
   pop {pc}

/* codigo gerado via:  arm-none-eabi-objdump  -d thumb2 > thumb2.lst
 8a58:       b500            push    {lr}
    8a5a:       46e3            mov     fp, ip
    8a5c:       44e3            add     fp, ip
    8a5e:       27ff            movs    r7, #255        ; 0xff
    8a60:       37ff            adds    r7, #255        ; 0xff
    8a62:       1df8            adds    r0, r7, #7
    8a64:       07f8            lsls    r0, r7, #31
    8a66:       bd00            pop     {pc}
*/


