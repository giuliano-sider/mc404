/* known JARM bugs:
doesn't display memory properly at I/O addresses (race conditions in java??).
doesn't have strd, ldrd, bfi, ubfx, etc. thinks they are different instructions.
documentation is totally wrong on a number of different points, leading users to
various most annoying errors. Ex: just try to read the doc (that is, the sample 
config file, the only real doc) for the seven segment display. nuff said.

"design" of this clock app is convoluted because of said bugs popping out of blind
corners and shooting the developer in the face. refactoring necessary but will cost
precious time.
*/

@ modos de interrupção no registrador de status
	.set IRQ_MODE,0x12
	.set FIQ_MODE,0x11
	.set USER_MODE,0x10

@ flag para habilitar interrupções externas no registrador de status
	.set IRQ, 0x80
	.set FIQ, 0x40

@enderecos dispositivos
	.set DISPLAY,     0x80000
	.set TIMER,       0x90000
	.set LED_ON_OFF,  0x90004
	.set BTN_ON_OFF,  0x90008
	.set BTN_RESET,   0x9000c @ my reset clock push button
@ constantes
	.set INTERVAL,1000
	.set BIT_READY,1
	
@ vetor de interrupções
	.org  7*4               @ preenche apenas uma posição do vetor,
	                        @ correspondente ao tipo 6
	b       tratador_timer

// what the...

.macro bfi dest, reg, sbit, nbits @ sbit and nbits are compile time constants

scratch2 .req r2 @ DO NOT USE dest or reg as r2 !!!!!!!!!!!!!!!!

push { scratch2 }
	
	mov scratch2, #-1
	lsl scratch2, #\nbits @ prepare our insertion mask
	.if (\sbit == 0)
		and \dest, \dest, scratch2 @ ror takes an integer in interval [1, 31]
	.else 
		and \dest, \dest, scratch2, ror #(32-\sbit) 
	.endif @ clear the bit field where we will make an insertion
	bic scratch2, \reg, scratch2 @ select bit field to insert
	orr \dest, \dest, scratch2, lsl #\sbit @ make the insertion
	//str scratch1, [scratch3]
pop { scratch2 }

.endm

// OMG
.macro bfieq dest, reg, sbit, nbits @ sbit and nbits are compile time constants

scratch2 .req r2 @ DO NOT USE dest or reg as r2 !!!!!!!!!!!!!!!!

bne exitthismacro\@
push { scratch2 }
	
	mov scratch2, #-1
	lsl scratch2, #\nbits @ prepare our insertion mask
	.if (\sbit == 0)
		and \dest, \dest, scratch2 @ ror takes an integer in interval [1, 31]
	.else 
		and \dest, \dest, scratch2, ror #(32-\sbit) 
	.endif @ clear the bit field where we will make an insertion
	bic scratch2, \reg, scratch2 @ select bit field to insert
	orr \dest, \dest, scratch2, lsl #\sbit @ make the insertion
	//str scratch1, [scratch3]
pop { scratch2 }
exitthismacro\@:

.endm

// what the...
.macro ubfx dest, reg, sbit, nbits @ sbit and nbits are compile time constants

	//ldr scratch3, =\addr @ Error: cannot represent T32_OFFSET_IMM relocation in this object file format
	//ldr scratch1, [scratch3] @ is there a way to avoid this indirection ???
	mov \dest, #-1
	lsr \dest, #(32-\nbits) @ prepare our insertion mask
	and \dest, \dest, \reg, lsr #\sbit

.endm



	.org 0x1000

_start:
flag .req r4
display_addr .req r5
reset_btn .req r6
on_off_btn .req r7

clockstring .req r10
initialclockstring .req r11
	mov	sp,#0x400	@ seta pilha do modo supervisor
	mov	r0,#IRQ_MODE	@ coloca processador no modo IRQ (interrupção externa)
	msr	cpsr,r0		@ processador agora no modo IRQ
	mov	sp,#0x300	@ seta pilha de interrupção IRQ
	mov	r0,#USER_MODE	@ coloca processador no modo usuário
	bic     r0,r0,#IRQ      @ interrupções IRQ habilitadas
	msr	cpsr,r0		@ processador agora no modo usuário
	mov	sp,#0x10000	@ pilha do usuário no final da memória 
	/*mov	sp,#0x400	@ seta pilha do modo supervisor
	mov	r0,#FIQ_MODE	@ coloca processador no modo FIQ (interrupção externa)
	msr	cpsr,r0		@ processador agora no modo FIQ
	mov	sp,#0x300	@ seta pilha de interrupção FIQ
	mov	r0,#USER_MODE	@ coloca processador no modo usuário
	bic r0,r0, #FIQ      @ interrupções FIQ habilitadas
	msr	cpsr,r0		@ processador agora no modo usuário
	mov	sp,#0x10000	@ pilha do usuário no final da memória */

	ldr	on_off_btn, =BTN_ON_OFF
	ldr reset_btn, =BTN_RESET
	//ldr r0, =ResetCode
	//ldm r0, {reset1, reset2} @ padrao de bits para valor 23:59:48
	ldr	display_addr, =DISPLAY	@ r2 tem porta display
	ldr	flag, =Flag
	ldr clockstring, =ClockString
	ldr initialclockstring, =ResetClockString
	//mov	counter,#0		@ r3 tem contador
DoResetTheClock:
	bl ResetTheClock
	
loop_off:
	ldr r0, [reset_btn] @ check if the reset button has been clicked
	cmp r0, #1
	beq DoResetTheClock @ if BTN_RESET is clicked, then we reset the clock to 23:59:48

	ldr	r0, [on_off_btn]         @ verifica botao liga
	cmp	r0, #BIT_READY   @ foi pressionado?
	bne	loop_off        @ se nao foi, continua
liga:	
	ldr	r1, =LED_ON_OFF
	str r0, [r1]		@ liga led (r0 == 1 if we got here)
	bl TimerOn
loop_on:
	ldr r0, [reset_btn] @ check if the reset button has been clicked   POLL...
	cmp r0, #1
	beq desligaAndResetTheClock @ reset the clock and turn off timer, led, go to 'off' state

	ldr	r0, [on_off_btn]         @ verifica botao liga  POLL...
	cmp	r0,#BIT_READY   @ foi desligado?
	bne     desliga
       
	ldr	r0, [flag] @ continua ligado, verifica flag
	cmp	r0, #0           @ timer ligou a flag? POLL...
	beq	loop_on         @ nao, entao continua
	mov	r0, #0		@ reseta flag
	str	r0, [flag]
	@ aqui conta
	/* add	r3,r3,#1	@ incrementa contador e
	cmp	r3,#10		@ volta a zero se necessario
	moveq	r3,#0
	ldrb	r0,[r4,r3]      @ padrao de bits para valor
	strb  	r0,[r2]	*/	@ seta display
Increment:
	//bl TimerOff @ debugging

	ldm clockstring, {r0, r1} @ pass the clock string for incrementation by Soma1
	bl Soma1
	stm clockstring, {r0, r1} @ now save the new clockstring after incrementation
	bl ConvertAsciiTo7Segment @ produce that 7 segment code from the ascii clock string 
	
	ubfx r2, r0, 0, 8
	str r2, [display_addr] @ send it to the display
	ubfx r2, r0, 8, 8
	str r2, [display_addr, #4] @ send it to the display
	ubfx r2, r0, 16, 8
	str r2, [display_addr, #8] @ send it to the display
	ubfx r2, r0, 24, 8
	str r2, [display_addr, #12] @ send it to the display
	ubfx r2, r1, 0, 8
	str r2, [display_addr, #16] @ send it to the display
	ubfx r2, r1, 8, 8
	str r2, [display_addr, #20] @ send it to the display
	ubfx r2, r1, 16, 8
	str r2, [display_addr, #24] @ send it to the display
	ubfx r2, r1, 24, 8
	str r2, [display_addr, #28] @ send it to the display

	//bl TimerOn @ debugging. how are you supposed to debug with a fucking timer
	b	loop_on
desligaAndResetTheClock:
	bl ResetTheClock
desliga:	
	bl TimerOff
	ldr	r1, =LED_ON_OFF
	str r0, [r1]		@ desliga led
	b loop_off

TimerOff:
	mov	r0, #0           @ desliga timer
	ldr	r1, =TIMER
	str r0, [r1]		@ seta timer
	mov pc, lr

TimerOn:
	ldr	r0, =INTERVAL    @ liga timer
	ldr	r1, =TIMER
	str r0, [r1]		@ seta timer
	mov pc, lr

ResetTheClock:
	ldm initialclockstring, {r0, r1} @ clock string must be set to "23:59:48"
	stm clockstring, {r0, r1}
	ldr r2, =ResetCode
	mov r3, #0
LoadValues:
	ldr r0, [r2, r3, lsl #2]	@ seta valor inicial display
	str r0, [display_addr, r3, lsl #2]
	add r3, #1
	cmp r3, #8
	bne LoadValues
	mov pc, lr

Flag:
     .word 0
status: // not used...
     .word 0
Digitos:
    .word 0x7e,0x30,0x6d,0x79,0x33,0x5b,0x5f,0x70,0x7f,0x7b, 0x80 @ last one is the '.' separator
.align 2
ClockString:
	.ascii "23:59:48" // ascii representation of time
.align 2
ResetClockString:
	.ascii "23:59:48" // ascii representation of initial time
.align 2
ResetCode: @ 23:59:48 programmed here as the reset time
	.word 0x6d, 0x79, 0x80, 0x5b, 0x7b, 0x80, 0x33, 0x7f

@ tratador da interrupcao	
@ aqui quando timer expirou
	.align 4
tratador_timer:	
	mov	r8, #1 @ apenas liga a flag. R8 IS A BANKED REGISTER IN FIQ MODE
	str	r8, [flag] @ flag is r4 so it's not banked
	movs	pc,lr		@ e retorna


.align 2
low_clock .req r0
high_clock .req r1
code7seg .req r3
digit_offset .req r2
digitos .req r12
ConvertAsciiTo7Segment: @ takes in the clock string in the format hh:mm:ss and produces the corresponding seven segment display codes in the same 8 bytes of r0-r1 (little endian)
	ldr digitos, =Digitos
	/*mov r2, #0x3a @ insert this for the ":" to get the right offset (10 bytes) into the Digitos array where the 7 segment codes are stored
	bfi low_clock, r2, 8, 8
	bfi high_clock, r2, 16, 8*/
	movw r2, #0x3030
	movt r2, #0x3030
	sub low_clock, low_clock, r2 @ now we get the offsets by subtracting 0x30
	sub high_clock, high_clock, r2
@ now convert, byte for byte, from the offset to the seven segment code in the Digitos look up table
//Digitos: .word 0x7e,0x30,0x6d,0x79,0x33,0x5b,0x5f,0x70,0x7f,0x7b, 0x80
	ubfx digit_offset, low_clock, 0, 8 @ Rd, Rn, lsb, width
	ldr code7seg, [digitos, digit_offset, lsl #2]
	bfi low_clock, code7seg, 0, 8 @ Rd, Rn, lsb, width

	ubfx digit_offset, low_clock, 8, 8 @ Rd, Rn, lsb, width
	ldr code7seg, [digitos, digit_offset, lsl #2]
	bfi low_clock, code7seg, 8, 8 @ Rd, Rn, lsb, width

	ubfx digit_offset, low_clock, 16, 8 @ Rd, Rn, lsb, width
	ldr code7seg, [digitos, digit_offset, lsl #2]
	bfi low_clock, code7seg, 16, 8 @ Rd, Rn, lsb, width

	ubfx digit_offset, low_clock, 24, 8 @ Rd, Rn, lsb, width
	ldr code7seg, [digitos, digit_offset, lsl #2]
	bfi low_clock, code7seg, 24, 8 @ Rd, Rn, lsb, width


	ubfx digit_offset, high_clock, 0, 8 @ Rd, Rn, lsb, width
	ldr code7seg, [digitos, digit_offset, lsl #2]
	bfi high_clock, code7seg, 0, 8 @ Rd, Rn, lsb, width

	ubfx digit_offset, high_clock, 8, 8 @ Rd, Rn, lsb, width
	ldr code7seg, [digitos, digit_offset, lsl #2]
	bfi high_clock, code7seg, 8, 8 @ Rd, Rn, lsb, width

	ubfx digit_offset, high_clock, 16, 8 @ Rd, Rn, lsb, width
	ldr code7seg, [digitos, digit_offset, lsl #2]
	bfi high_clock, code7seg, 16, 8 @ Rd, Rn, lsb, width

	ubfx digit_offset, high_clock, 24, 8 @ Rd, Rn, lsb, width
	ldr code7seg, [digitos, digit_offset, lsl #2]
	bfi high_clock, code7seg, 24, 8 @ Rd, Rn, lsb, width

mov pc, lr

Soma1: @ clock string in the format hh:mm:ss is passed (ascii encoded) in r0-r1 (little endian)
	   @ clock string incremented by one second is passed out in r0-r1
	   @ clobbers r0-r3 and r12 (as per the ARM calling convention)
low_clock .req r0
high_clock .req r1
zero_chr .req r3
tmpreg .req r2
	movw zero_chr, 0x3030 @ bunch of ascii bytes with code for '0'
//Digitos: .word 0x7e,0x30,0x6d,0x79,0x33,0x5b,0x5f,0x70,0x7f,0x7b, 0x80
	ubfx tmpreg, high_clock, 24, 8 @ obtain the lsd of the seconds counter
	cmp tmpreg, #0x39 @ compare lsd of seconds counter with '9'
	//itee eq @ if it is equal, then set it to zero and carry. if not, increment it and quit
	bfieq high_clock, zero_chr, 24, 8 @ loads '0' to the lsd of seconds counter. must inspect next digit now
	addne high_clock, #0x01000000 //#1 lsl #24 @ increment seconds counter and we are done since it wasn't a 9
	bne Done
	
	ubfx tmpreg, high_clock, 16, 8 @ obtain the msd of seconds counter
	cmp tmpreg, #0x35 @ if it is '5' we must set it to zero and carry. if not, increment it and quit
	//itee eq
	bfieq high_clock, zero_chr, 16, 8
	addne high_clock, #0x00010000 //#1 lsl #16
	bne Done

	ubfx tmpreg, high_clock, 0, 8 @ obtain the lsd of the minutes counter
	cmp tmpreg, #0x39 @ compare msd of minutes counter with '9'
	//itee eq @ if it is equal, then set it to zero and carry. if not, increment it and quit
	bfieq high_clock, zero_chr, 0, 8 @ loads '0' to the lsd of minutes counter. must inspect next digit now
	addne high_clock, #1 @ increment minutes counter and we are done since it wasn't a 9
	bne Done

	ubfx tmpreg, low_clock, 24, 8 @ obtain the msd of minutes counter
	cmp tmpreg, #0x35 @ if it is '5' we must set it to zero and carry. if not, increment it and quit
	//itee eq
	bfieq low_clock, zero_chr, 24, 8
	addne low_clock, #0x01000000 //#1 lsl #24
	bne Done
		
	ubfx tmpreg, low_clock, 8, 8 @ obtain the lsd of hours counter
	cmp tmpreg, #0x39 @ if it is '9' we zero the lsd of the hour counter and boost the msd
	//iteee ne
	addne low_clock, #0x00000100 //#1 lsl #8 @ if not, just add one (we'll have to check if we reached 24 hours)
	bfieq low_clock, zero_chr, 8, 8
	addeq low_clock, #1 @ add one to the hour
	beq Done

	ubfx tmpreg, low_clock, 0, 16
	movw r12, 0x3432 @ check if we reached 24 hours
	cmp tmpreg, r12 @ if it's two, we just ran past the 23rd hour and must zero out the clock
	//it eq
	bfieq low_clock, zero_chr, 0, 16 @ load 00 for the hour

Done:
	mov pc, lr
