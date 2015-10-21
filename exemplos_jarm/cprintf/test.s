@ cprintf
@     console printing system call example
@ first parameter (in r0): address of format string
@     accepted format specifiers: %d, %x, %c	
@ second parameter (in r1) scalar value
@ third parameter (in r2) scalar value
@ fourth parameter (in r3) scalar value
	
format:
    .asciz      "Hello, I'm ARM!\n\nThree values: 0x%08x %d %c\n"
len = . - format
 
   .org 0x1000
_start:
	
    @ syscall cprintf(const char * restrict format, ...)
    ldr     r0, =format  @ format string -> format
    mov     r1, #0x2     @ var 1 -> r1
    mov     r2, #-1      @ var 2 -> r2
    mov     r3, #0x61    @ var 3 -> r3
    mov     r7, #0x21    @ cprintf is syscall #21
    svc     #0x5555      @ invoke syscall 
    
    @ syscall exit(int status) 
    mov     r0, #0      @ status -> 0
    mov     r7, #1      @ exit is syscall #1
    svc     #0x5555     @ invoke syscall 

#end:
