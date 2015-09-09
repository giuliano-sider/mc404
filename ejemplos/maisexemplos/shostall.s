/* shostall.s   - executa várias funções (operações) de semihosting para o ARM
http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.dui0471c/CHDJHHDI.html
Sugestão para teste: 
../gcc.sh shostall.s
qemu-arm shostall Hello World!
*/

.syntax unified
.align
.text
.global main
/* código da operação é passado em r0, parametros em r1
 operacoes semihosting testadas: */
.equ SYS_WRITEC, 0x03;	@ exibe um caracter no vídeo
.equ SYS_WRITE0, 0x04;	@ exibe uma cadeia tipo C no vídeo
.equ SYS_TIME, 0x11	    @ retorna numer de segundos desde 01/01/1970
.equ SYS_SYSTEM, 0x12	@ executa um comando ("ls -l")  passado como parametro
.equ SYS_GET_CMDLINE, 0x15 @ obtem a linha de comando que invocou o programa
main:
  push {lr}
  mov r0,#SYS_WRITEC	@ show character in buffer pointed by r1
  ldr r1,=outchar	    @ character shown: !
  bkpt 0xab		        @ semihosting call
  mov r0,#SYS_WRITEC    @ change line after printing !
  ldr r1,=lf
  bkpt 0xab
@-------------------------------------------------------------------------
  mov r0, #SYS_WRITE0	@ show string pointed by r1
  ldr r1,=buffer
  bkpt 0xab		@ do it
@-------------------------------------------------------------------------
  mov r0, #SYS_TIME	    @ returns in r0 num of seconds since 01/01/1970
  bkpt 0xab
  mov r1,r0             @ exibit with printf
  ldr r0,=secsmsg
  bl printf		        @ do it
@-------------------------------------------------------------------------
  mov r0,#1		@ delay 1 second
  bl sleep		@ do it
@-------------------------------------------------------------------------
  ldr r0,=SYS_SYSTEM	
  ldr r1,=cmdptr1       @ execute a command: r1 points to two words:
			            @ first word points to string with command
			            @ second word contains size of string in bytes
  bkpt 0xab		        @ do it
@-------------------------------------------------------------------------
  mov r0, #SYS_TIME	    @ returns in r0 num of seconds since 01/01/1970
  bkpt 0xab
  mov r1,r0
  ldr r0,=secsmsg
  bl printf		        @ show it
@-------------------------------------------------------------------------
  @ldr r0,=msg
  @bl printf
  mov r0, #SYS_GET_CMDLINE @ obtain the command line: "qemu-arm shostall Hello World!"
  ldr r1,=cmdline          @ command line will be sored in buffer:
  bkpt 0xab
  mov r0, #SYS_WRITE0	@ show string pointed by r1
  ldr r1,=buffer        @ buffer has command line from previous operation
  bkpt 0xab             @ do it
  mov r0,#SYS_WRITEC    @ change line so that prompt after execution comes ina new line
  ldr r1,=lf
  bkpt 0xab             @ do it
  pop {pc}
outchar: .byte '!'
lf:     .byte '\n'
secsmsg: .asciz "Seconds since 01/01/1970: %d\n"
cmdptr1: .word cmdln
         .word 6
cmdln: .asciz "ls -l\n"

.data
.align
cmdline: .word buffer
         .word 30
buffer: .asciz "Minha terra tem palmeiras...\n"
