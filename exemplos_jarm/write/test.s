@ exemplo de chamada de sistema write
	
msg:
    .ascii      "Hello, ARM!\n"
len = . - msg
 
   .org 0x1000
_start:


    @ syscall write(int fd, const void *buf, size_t count) 
    mov     r0, #1     @ fd -> stdout
    ldr     r1, =msg   @ buf -> msg
    ldr     r2, =len   @ count -> len(msg)
    mov     r7, #4     @ write is syscall #4
    svc     #0x5555    @ invoke syscall 
    
    @ syscall exit(int status) 
    mov     r0, #0     @ status -> 0
    mov     r7, #1     @ exit is syscall #1
    svc     #0x5555    @ invoke syscall 
