 
 
	.globl _start
	.org   0x1000
_start:
	/* int write(int fd, const void *buf, size_t count) */
	mov     r0, #1      @ fd -> stdout
	ldr     r1, =msg    @ buf -> msg
	ldr     r2, =len    @ count -> len(msg)
	mov     r7, #4      @ write is syscall #4
	svc     0x05555     @ invoke syscall 

	/* int read(int fd, const void *buf, size_t count) */

	mov     r0, #0      @ fd -> stdin
	ldr     r1, =buffer @ buf -> buffer
	ldr     r2, =len2    @ count -> len(msg)
	mov     r7, #3      @ write is syscall #4
	svc     #0x5555     @ invoke syscall 
	mov	r2, r0      @ number of bytes read
	
	/* int write(int fd, const void *buf, size_t count) */
	mov     r0, #1      @ fd -> stdout
	ldr     r1, =buffer @ buf -> msg
	mov     r7, #4      @ write is syscall #4
	svc     0x5555      @ invoke syscall 
    
	/* exit(int status) */
	mov     r0, #0      @ status -> 0
	mov     r7, #1      @ exit is syscall #1
	svc     #0x5555     @ invoke syscall 

msg:
	.ascii   "Hello, ARM!\n"
len = . - msg

@buffer onde serao armazenados os caracteres lidos
buffer:
	.skip	256
len2 = . - buffer
 
