@ pisca led, sem uso do timer

@ endereço painel de leds
	.set LEDSADDR,0x90000
	.set INTERVAL,0x7fffff
	
main:
	mov	r0,#1           @ inicializa contador para leds
	ldr	r2,=LEDSADDR	@ escreve valor corrente do contador no
	str	r0,[r2]		@ painel de leds
	ldr	r1,=INTERVAL    @ inicializa contador de tempo
loop:
	subs	r1,#1		@ espera contador de tempo zerar
	bne	loop
				@ aqui quando tempo expirou
	ldr	r1,=INTERVAL    @ reinicializa contador de tempo
	add	r0,#1		@ conta
	str	r0,[r2]		@ painel de leds
	b 	loop


