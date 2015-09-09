/*  macrosum.s   - exemplo de macro com parametros default
		- gera 5 palavras com os valores 0 a 5
		- do manual do assembler as extraido para macros.html
		- para ver o codigo gerado use o utilitario objdump
*/
.syntax unified
.align
.text
.global main
.macro  sum from=0, to=5
        .long   \from
        .if     \to-\from
        sum     "(\from+1)",\to
        .endif
        .endm
main:
    push {lr}
    pop  {pc}
   sum

