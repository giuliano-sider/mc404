@ incrementa contador em display

@ endereços dos dispositivos
	.set ON_OFF,0x90000
	.set COUNT,0x90010
	.set DISPLAY,0x90080
	.set LED,0x90110
@ constantes
	.set BIT_READY,1
	
main:
	ldr	r1,=ON_OFF 	@ r1 tem porta botao liga/desliga
	ldr	r2,=COUNT       @ r2 tem botao conta
	ldr	r3,=DISPLAY	@ r3 tem porta display
	ldr     r4,=LED         @ r4 tem led
	mov	r5,#0		@ r5 tem contador
	mov	r7,#digitos
	ldrb	r0,[r7]         @ padrao de bits para valor 0
	strb  	r0,[r3]		@ seta display com 0
loop:
	ldr	r0,[r1]         @ verifica botao liga
	strb  	r0,[r4]		@ seta led 
	cmp	r0,#BIT_READY   @ foi pressionado?
	bne	loop            @ se nao foi, continua
				@ aqui se botao ligado
	ldr	r0,[r2]         @ verifica botao conta
	cmp	r0,#BIT_READY   @ foi pressionado?
	bne	loop            @ se nao foi, continua

	@ aqui conta
	add	r5,#1		@ incrementa contador e
	cmp	r5,#10		@ volta a zero se necessario
	moveq	r5,#0
	ldrb	r0,[r5,r7]
	strb	r0,[r3]		@ seta display
	@strb  	r5,[r4]		@ seta led 
	b	loop
digitos:
	.byte 0x7e,0x30,0x6d,0x79,0x33,0x5b,0x5f,0x70,0x7f,0x7b
	