@ Giuliano Sider, ra146271, Laboratório #7, MC404C.
@ Cronômetro com interrupção periódica no ARM, versão 7, simulado pelo JARM do Prof. Anido

@ modos de interrupção no registrador de status
	.set IRQ_MODE, 0x12 @ ???????????????????? not FIQ ????
	.set USER_MODE, 0x10

@ flag para habilitar interrupções externas no registrador de status
	.set IRQ, 0x80

@enderecos dispositivos
	.set DISPLAY,     0x80000
	.set TIMER,       0x80020
	.set LED_ON_OFF,  0x80024
	.set BTN_ON_OFF,  0x80028
	.set RESET_BTN,   0x8002c
@ constantes
	.set INTERVAL, 1000
	.set BIT_READY, 1
	
@ vetor de interrupções
	.org  7*4               @ preenche apenas uma posição do vetor,
	                        @ correspondente ao tipo 6
	b       tratador_timer

	.org 0x1000
_start: @ this is Prof. Anido's initialization magic
	mov	sp,#0x400	@ seta pilha do modo supervisor
	mov	r0, #IRQ_MODE	@ coloca processador no modo IRQ (interrupção externa)
	msr	cpsr,r0		@ processador agora no modo IRQ
	mov	sp, #0x300	@ seta pilha de interrupção IRQ
	mov	r0 ,#USER_MODE	@ coloca processador no modo usuário
	bic     r0,r0,#IRQ      @ interrupções IRQ habilitadas
	msr	cpsr,r0		@ processador agora no modo usuário
	mov	sp, #0x10000	@ pilha do usuário no final da memória 

	bl DisplayResetCode @ display 23:59:48 and then go to "clock off polling loop"
loop_off: @ polling loop to check if we should make a transition from timer off to on.
	ldr r1, =RESET_BTN
	ldr r0, [r1] @ check if reset button has been pressed
	cmp r0, #BIT_READY @ bit_ready===1
	bleq DisplayResetCode @ affects r2-r11
	ldr	r1, =BTN_ON_OFF @ WE CANNOT TURN THIS THING OFF PROGRAMMATICALLY. ONLY PHYSICALLY. THANK JARM
	ldr	r0, [r1]         @ verifica botao liga
	cmp	r0, #BIT_READY   @ foi pressionado?
	bne	loop_off        @ se nao foi, continua
liga: @ button was pressed. now handle the transition from timer off to on.
	ldr	r2, =LED_ON_OFF
	str  	r0,[r2]		@ liga led @ led.enabled = true @ r0 IS CARRYING VALUE 1 FROM THE PREVIOUS CHECK IN LOOP_OFF
	ldr	r0, =INTERVAL    @ liga timer @ timer.interval = 1000 @ milliseconds
	ldr	r2, =TIMER
	str  	r0,[r2]		@ seta timer
loop_on: @ polling loop to check if we should make a transition from on to off.
	ldr	r1, =BTN_ON_OFF
	ldr	r0, [r1]         @ verifica botao liga
	cmp	r0, #BIT_READY   @ foi desligado?
	bne     desliga
	ldr r1, =RESET_BTN
	ldr r0, [r1] @ check if reset button has been pressed
	cmp r0, #BIT_READY @ bit_ready===1
	bleq DisplayResetCode @ affects r2-r11
	ldr	r1,=flag        @ continua ligado, verifica flag
	ldr	r0, [r1]
	cmp	r0, #0           @ timer ligou a flag?
	beq	loop_on         @ nao, entao continua
	mov	r0, #0		@ reseta flag @ countflag = false
	str	r0, [r1]
	bl Sum1To7SegmentClock @ r2-r11 affected: ok
	b loop_on @ keep 'em pollin'

desliga: @ toggle button was pressed. now handle the transition from timer on to off.
	mov	r0, #0           @ desliga timer
	ldr	r2, =TIMER
	str  	r0, [r2]		@ seta timer @ timer.interval = 0 @ timer disabled
	ldr	r2, =LED_ON_OFF
	str  	r0, [r2]		@ desliga led @ led.enabled = false
	ldr r2, =BTN_ON_OFF
	str r0, [r2] @ clear the timer on state for the button as well
	b       loop_off

@ tratador da interrupcao:  aqui quando timer expirou
	.align 4
tratador_timer:
	ldr	r9,=flag	@ apenas liga a flag
	mov	r8,#1 @ r8-r9 are banked registers, apparently (FIQ)
	str	r8,[r9] @ countflag = true
movs	pc,lr		@ e retorna

@ seven segment digit codes
.set zero, 0x7e
.set one, 0x30
.set two, 0x6d
.set three, 0x79
.set four, 0x33
.set five, 0x5b
.set six, 0x5f
.set seven, 0x70
.set eight, 0x7f
.set nine, 0x7b
.set dot, 0x80 @ separator

Sum1To7SegmentClock:
	@ input: r4-r11 must have the codes for the display in BIG ENDIAN order (r4: lefthour, r11: rightminute)
	@ output: r2 has DISPLAY. r3 has Sum1Map. r4-r11 have the new codes for the display in /*little*/ BIG endian order.
	ldr r2, =DISPLAY
	ldr r3, =Sum1Map
@ WRITE ONLY MEMORY!!!!!!!!!!!!!!!!!! ldm r2, { r4-r11 } @ 8 words, one for each clock digit (BIG endian) !!!!!!!!!!!!!!
	ldrb r11, [r3, r11] @ rightsecond <- Sum1Map[rightsecond]
	cmp r11, #zero @ if rightsecond == 0, we carried. increment the next digit
	bne NowUpdateTheClock
	ldrb r10, [r3, r10] @ leftsecond <- Sum1Map[leftsecond]
	cmp r10, #six @ if leftsecond == 6, we carried: set it to zero and increment next digit
	bne NowUpdateTheClock
	mov r10, #zero @ leftsecond = 0
	ldrb r8, [r3, r8] @ rightminute = Sum1Map[rightminute]
	cmp r8, #zero @ if rightminute == 0, we carried: increment the next digit
	bne NowUpdateTheClock
	ldrb r7, [r3, r7] @ leftminute = Sum1Map[leftminute]
	cmp r7, #six @ if leftminute == 6, we carried: set it to zero and increment next digit
	bne NowUpdateTheClock
	mov r7, #zero @ leftminute = 0
	ldrb r5, [r3, r5] @ righthour = Sum1Map[righthour]
	cmp r5, #zero @ if righthour == 0, we carried
	bne IsItMidnight @ we still have to check if we've gotten to 24:00:00
		ldrb r4, [r3, r4] @ lefthour = Sum1Map[lefthour]
		b NowUpdateTheClock @ we know we have a valid hour because we set a valid initial value for the clock.
	IsItMidnight:
		cmp r4, #two @ if hour == 24, we've gotten to midnight. reset the hour to 00
		bne NowUpdateTheClock
		cmp r5, #four @ lefthour == 2 && righthour == 4
		moveq r5, #zero @ lefthour = righthour = 0
		moveq r4, #zero @ no IT block needed in this family
NowUpdateTheClock: @ save changes made to the clock's 7 segment display codes
	stm r2, { r4-r11 }
mov pc, lr

DisplayResetCode: @ side effect: display 23:59:48.
					@ output: r4-r11 have the new codes for the display in /*little*/ BIG endian order.
	ldr	r2, =DISPLAY	@ r2 tem porta display AND THE REST OF THE PERIPHERALS AT KNOWN OFFSETS
	ldr r3, =ResetCode @ 7 segment code for 23:59:48
@ now reset the clock to 23:59:48. 
	ldm r3, { r4-r11 }
	stm r2, { r4-r11 }
mov pc, lr

Flag: @ countflag
     .word 0
Digitos: @ seven segment display codes: 0, 1,2,3, 4,5,6, 7,8,9, .
     .byte 0x7e, 0x30,0x6d,0x79, 0x33,0x5b,0x5f, 0x70,0x7f,0x7b, 0x80 @ last one is the '.' separator
.align
ResetCode: @ 23:59:48 programmed here as the reset time
	.word two, three, dot, five, nine, dot, four, eight @ graphical layout forces us to be big endian...
Sum1Map: 
@ made in excel. for a given 7 segment code (the offset into this table), it
@ adds 1, modulo 10. 0xff marks unused entries.
.byte 0xff,0xff,0xff,0xff, 0xff,0xff,0xff,0xff, 0xff,0xff,0xff,0xff, 0xff,0xff,0xff,0xff
.byte 0xff,0xff,0xff,0xff, 0xff,0xff,0xff,0xff, 0xff,0xff,0xff,0xff, 0xff,0xff,0xff,0xff 
.byte 0xff,0xff,0xff,0xff, 0xff,0xff,0xff,0xff, 0xff,0xff,0xff,0xff, 0xff,0xff,0xff,0xff
.byte two, 0xff,0xff,five, 0xff,0xff,0xff,0xff, 0xff,0xff,0xff,0xff, 0xff,0xff,0xff,0xff
.byte 0xff,0xff,0xff,0xff, 0xff,0xff,0xff,0xff, 0xff,0xff,0xff,0xff, 0xff,0xff,0xff,0xff
.byte 0xff,0xff,0xff,0xff, 0xff,0xff,0xff,0xff, 0xff,0xff,0xff,six,  0xff,0xff,0xff,seven
.byte 0xff,0xff,0xff,0xff, 0xff,0xff,0xff,0xff, 0xff,0xff,0xff,0xff, 0xff,three,0xff,0xff
.byte eight,0xff,0xff,0xff, 0xff,0xff,0xff,0xff, 0xff,four,0xff,zero, 0xff,0xff,one,nine
