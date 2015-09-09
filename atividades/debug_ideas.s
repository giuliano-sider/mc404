





.align
DebugFormatStr: .asciz "at line %i, error code %i:\n%s\npc = %8X,  r0 = %8X,  r1 = %8X,  r2 = %8X, r3 = %8X,\nr4 = %8X,  r5 = %8X,  r6 = %8X,  r7 = %8X, r8 = %8X,\nr9 = %8X, r10 = %8X, r11 = %8X, r12 = %8X,\nlr = %8X\n"
.align
.macro	McDebug debuglabel, messaggio, line, error_code=0, next_label
McDebug_\@\():
 	push { r0-r12, lr }
		mov r1, \line @ line number 
		mov r2, \error_code @ error code 1
		ldr r3, =\debuglabel
		bl DebugPrintRegisters
	pop { r0-r12, lr }
	b \next_label
	.align
	\debuglabel\(): .asciz "\messaggio"
	.align
.endm
	
	/*push { r0-r12, lr }
			mov r1, 41 @ line number 
			mov r2, 0 @ error code 1
			ldr r3, =RegDbgMsg
			bl DebugPrintRegisters
	pop { r0-r12, lr }*/
	McDebug "DbgTest", "testiiiiiii ng\n", 61, 0, "main_printnsort"
	.align
	RegDbgMsg: .asciz "testiiiiiii ng\n"
	.align

DebugPrintRegisters:
	push { lr }
	ldr r0, =DebugFormatStr
	bl printf
	pop { pc }