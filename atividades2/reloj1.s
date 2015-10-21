/*********** MC404C, Giuliano Sider, RA 146271, 16/10/2015, lab exercise #6
simple program that increments a timer (in the format hh:mm:ss, "military time") by one second
every time a function (Soma1) is called.

Function void Soma1 (char *relogio_string) : : input r0 => relogio_string : clobber r0-r3 
clobbers r0-r3 as per the ARM calling convention
increments counter by one, represented in the form hh:mm:ss as an ascii string passed in at r0.
***********/




.syntax unified
.text
.global main
.align

main:
push { r4, lr }

	ldr r4, =Relogio
	.rept 32
		mov r0, r4
		bl Soma1
		ldr r0, =PrintFormat
		mov r1, r4
		bl printf
	.endr

pop { r4, pc }

PrintFormat: .asciz "%s\n"

Soma1:
low_clock .req r2
high_clock .req r3
zero_chr .req r1
push { r4-r5, lr }
	ldr r0, =Relogio @ Error: first transfer register must be even -- `ldrd low_clock,high_clock,[r0]'
	//Error: can only transfer two consecutive registers -- `ldrd low_clock,high_clock,[r0]'
	ldrD low_clock, high_clock, [r0] @ keep string contents loaded here

	movw zero_chr, 0x3030 @ bunch of ascii bytes with code for '0'
	// Error: invalid constant (30303030) after fixup
	ubfx r5, high_clock, 24, 8 @ obtain the lsd of the seconds counter
	cmp r5, 0x39 @ compare lsd of seconds counter with '9'
	itee eq @ if it is equal, then set it to zero and carry. if not, increment it and quit
	bfieq high_clock, zero_chr, 24, 8 @ loads '0' to the lsd of seconds counter. must inspect next digit now
	addne high_clock, 1 << 24 @ increment seconds counter and we are done since it wasn't a 9
	bne Done
	
	ubfx r5, high_clock, 16, 8 @ obtain the msd of seconds counter
	cmp r5, 0x35 @ if it is '5' we must set it to zero and carry. if not, increment it and quit
	itee eq
	bfieq high_clock, zero_chr, 16, 8
	addne high_clock, 1 << 16
	bne Done

	ubfx r5, high_clock, 0, 8 @ obtain the lsd of the minutes counter
	cmp r5, 0x39 @ compare msd of minutes counter with '9'
	itee eq @ if it is equal, then set it to zero and carry. if not, increment it and quit
	bfieq high_clock, zero_chr, 0, 8 @ loads '0' to the lsd of minutes counter. must inspect next digit now
	addne high_clock, 1 @ increment minutes counter and we are done since it wasn't a 9
	bne Done

	ubfx r5, low_clock, 24, 8 @ obtain the msd of minutes counter
	cmp r5, 0x35 @ if it is '5' we must set it to zero and carry. if not, increment it and quit
	itee eq
	bfieq low_clock, zero_chr, 24, 8
	addne low_clock, 1 << 24
	bne Done
		
	ubfx r5, low_clock, 8, 8 @ obtain the lsd of hours counter
	cmp r5, 0x39 @ if it is '9' we zero the lsd of the hour counter and boost the msd
	iteee ne
	addne low_clock, 1 << 8 @ if not, just add one (we'll have to check if we reached 24 hours)
	bfieq low_clock, zero_chr, 8, 8
	addeq low_clock, 1 @ add one to the hour
	beq Done

	ubfx r5, low_clock, 0, 16
	movw r4, 0x3432 @ check if we reached 24 hours
	cmp r5, r4 @ if it's two, we just ran past the 23rd hour and must zero out the clock
	it eq
	bfieq low_clock, zero_chr, 0, 16 @ load 00 for the hour

Done:
	strD low_clock, high_clock, [r0] @ return updated clock string to memory
pop { r4-r5, pc }

.data
.align
Relogio: .asciz "23:59:48"
