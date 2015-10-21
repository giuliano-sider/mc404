
TongPo: .asciz "lutador tailandês\n"
TongPoLength = . - TongPo

@.org 0x1000
_start:

	@ syscall write(int fd, const void *buf, size_t count)
	mov r0, #1 @ file descriptor is stdout
	ldr r1, =TongPo
	mov r2, #TongPoLength
	mov r7, #4 @ write is syscall #4. eabi convention to put it in r7
    svc #0x5555 @ invoke syscall 

    @ syscall exit(int status) 
    mov     r0, #0     @ status -> 0
    mov     r7, #1     @ exit is syscall #1
    svc     #0x5555    @ invoke syscall

