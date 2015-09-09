/*macros.s   - Exemplos de macros para o ARM
	     - MC404 2o sem 2013
*/
.syntax unified
    .text
    .align 2
Hellomessage: .asciz "Hello World! %x %x\n"
    .align 2
    .global main
.macro average avg,sum,a,b,c,d	@ calcula a media de a, b, c, d; parametros sao registradores
# avg = (a+b+c+d)/4;
	add \sum, \a, \b
	add \sum, \c, \sum
	add \sum, \d, \sum
	mov \avg, \sum, lsr #2	
.endm

.macro SHIFTLEFT a, b	@ a= reg, b=constante se b>=0 desloca a b bits p/ esquerda 
  .if \b < 0 		@ se b < 0 desloca a com sinal |b| bits p/ direita 
     MOV \a, \a, ASR -\b 
     .exitm 
  .endif 
  MOV \a, \a, LSL \b 
.endm

.macro exchangeregs a, b
# troca os regs a com b somente se a < b 
     cmp \a, \b
     bhs \@
     eor \a, \b
     eor \b, \a
     eor \a, \b
\@: 
.endm

main:
    push {lr}
    mov r0, 0xab
    mov r1, 0xff
    mov r2, -1
    exchangeregs r0,r1		@ troca r1 := ab r0:= ff
   exchangeregs r1, r2   	@ troca: r1:=ffffffff r2:=ab
   
   ldr r0, =Hellomessage
   bl printf
   mov r1, 1
   mov r2,2
   mov r3, 3
   mov r4, 6
   average r0,r0,r1,r2,r3,r4
   mov r1,r0
   ldr r0, =Hellomessage
   bl printf	@ average =12/ 4= 3 r2= 2
   pop {pc}
