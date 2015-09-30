.syntax unified

/*************
programa teste para usar o gdb tui 
30/09/2015
mc404c
**************/

.text
.align

.global main
main:
inputformat .req r4
inputnum .req r5
randnum .req r6
	push { r4-r6 , lr }
	mov r0, 0
	bl time
	bl srand @ srand(time(NULL)); to seed the randomizer, where NULL == 0
	ldr inputformat, =ReadNumStr
	ldr inputnum, =InputNumLocation @ we do this to avoid repeated accesses to memory...
Guess_Loop:
	ldr r0, =PromptMsg
	bl printf
	bl rand
	mov r1, 1
	add randnum, r1, r0, lsr 22 @ only use ten random bits... and add 1 to it. result: unif( 1, 1024) (included)
	Nth_Guess_Loop:
		mov r0, inputformat
		mov r1, inputnum
		bl scanf
		ldr r1, [inputnum]
		cbz r1, EndOfGame
		cmp r1, randnum
		beq CorrectGuess
		ITE gt
		ldrgt r0, =BiggerThanMsg
		ldrle r0, =LessThanMsg
		bl printf
		b Nth_Guess_Loop
	CorrectGuess:
		ldr r0, =SuccessMsg
		bl printf
		b Guess_Loop
EndOfGame:
	ldr r0, =GoodbyeMsg
	bl printf
	pop { r4-r6, pc }
.data 
.align
PromptMsg: .asciz "Guess a number from 1 to 1024. Enter 0 to quit.\n"
GoodbyeMsg: .asciz "Thanks for playing. Have a good.\n"
SuccessMsg: .asciz "Congratulations! %i is the correct number\n"
BiggerThanMsg: .asciz "%i is more than the correct number\n"
LessThanMsg: .asciz "%i is less than the correct number\n"
.align
ReadNumStr: .asciz "%i"
InputNumLocation: .word 0

