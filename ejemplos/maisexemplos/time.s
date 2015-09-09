/* time.s	- uso das funcoes time e sleep da libc para medir "elapsed time"em segundos
   Para descobrir como parametros sao passados em assembler para funcoes da libc compile um
   teste simples digamos, time.c, com o comando a seguir e examine o codigo gerado em time.lst:
   gcc -c -g -Wa,-a,-ad time.c > time.lst
*/
.syntax unified
.thumb
.align
.text
.global main
main:
   push {lr}
   mov r0,#0	@ parametro NULL para time
   bl time	@ time devolve o clock em segundos desde a "epoca"
   push {r0}	@ salva clock(segundos desde "epoca")
   mov r0,#2	@ parametro para sleep (2 segs)
   bl sleep	@ delay 2 segs
   mov r0,#0    @ parametro NULL
   bl time
   pop {r1}     @ recupera primeira medida do clock
   sub r0,r1 	@ r0= elapsed time (segs)
   mov r1,r0
   bl print     @ exibe elapsed time (= 2 segs)
   pop {pc}
print:
   push {r0-r4,lr}
   ldr r0,=fmt
   bl printf
pop {r0-r4,pc}
fmt: .asciz "r1= %d\n"
