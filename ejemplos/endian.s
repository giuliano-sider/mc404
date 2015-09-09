/* endian.s
	- o ARM armazena dados na memoria no formato little-endian, ou seja 
	- bytes de uma palavra são armazenados "em endereços crescentes" na ordem low,..., high
	- no exemplo os bytes da palavra 11223344 são armazenados em enderecos
	- crescentes da RAM na ordem inversa: 44332211
	- MC404 2o sem 2013 */
.syntax unified
    .text
    .align 2 
    .global main
main:
    push {lr}
    ldr r0,=myword
    ldr r1,=0x11223344
    str r1, [r0]
    ldrb r1,[r0], 1
    ldrb r2,[r0], 1
    ldrb r3,[r0], 1
    bl debug
    pop {pc}
debug:
    push {lr}
    ldr r0, =debugmsg
    bl printf
    pop {pc}
debugmsg:   .asciz  "r1 em hexa: %x r2 em hexa: %x r3 em hexa: %x\n"
    .data
    .align 2
myword: .word 0

