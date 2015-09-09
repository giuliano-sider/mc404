/*  ubbx.s   - macro para emulas a instrucçaõ ubfx rd, rn, sbit, nbits
   onde rd e rn são registradores (<r8), sbit e nbitrs são constantes (0..31)
*/
.syntax unified
.align
.text
.global main
.macro ubfx rd,rn, sbit,nbits	@macro to emulate ubfx instruction
mask .req r8
        mov mask, #-1		@ initial mask all 1's
	lsl mask, #\nbits	@ set ls nbits to 1, others 0: 000...00|111...11| nbits 1
	eor mask, #-1		@ complement all bits: ls nbits = 0, others =1: 111...11|000...00|
	lsr \rn, #\sbit		@ shift right sbits of rn: field aligned to bits 0...nbits-1 
	and \rd, \rn, mask	@ insert nbits of rn clear othef bts 
.endm
