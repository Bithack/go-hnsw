//+build !noasm,!appengine

#include "textflag.h"

// func L2Squared(x, y []float32) (sum float32)
TEXT ·L2Squared(SB), NOSPLIT, $0
	MOVQ    x_base+0(FP), SI  // SI = &x
	MOVQ    y_base+24(FP), DI // DI = &y
	
    MOVQ    x_len+8(FP), BX  // BX = min( len(x), len(y) )
	CMPQ    y_len+32(FP), BX
	CMOVQLE y_len+32(FP), BX
	CMPQ    BX, $0            // if BX == 0 { return }
	JE      l2_end
	
    MOVSD $(0.0), X1 // sum = 0	

	XORQ    AX, AX            // i = 0
	PXOR    X2, X2            // 2 NOP instructions (PXOR) to align
	PXOR    X3, X3            // loop to cache line
	MOVQ    DI, CX
	ANDQ    $0xF, CX          // Align on 16-byte boundary for ADDPS
	JZ      l2_no_trim      // if CX == 0 { goto l2_no_trim }

	XORQ $0xF, CX // CX = 4 - floor( BX % 16 / 4 )
	INCQ CX
	SHRQ $2, CX

l2_align: // Trim first value(s) in unaligned buffer  do {
	MOVSS (SI)(AX*4), X2 // X2 = x[i]
	MULSS X0, X2         // X2 *= a
	ADDSS (DI)(AX*4), X2 // X2 += y[i]
	MOVSS X2, (DI)(AX*4) // y[i] = X2
	INCQ  AX             // i++
	DECQ  BX
	JZ    l2_end       // if --BX == 0 { return }
	LOOP  l2_align     // } while --CX > 0

l2_no_trim:
	MOVQ   BX, CX
	ANDQ   $0xF, BX         // BX = len % 16
	SHRQ   $4, CX           // CX = int( len / 16 )
	JZ     l2_tail4_start // if CX == 0 { return }
	
l2_loop: // Loop unrolled 16x   do {
	MOVAPS (SI)(AX*4), X2   // X2 = x[i:i+4]
	MOVAPS 16(SI)(AX*4), X3
	MOVAPS 32(SI)(AX*4), X4
	MOVAPS 48(SI)(AX*4), X5
	
    SUBPS  (DI)(AX*4), X2   // X2 -= y[i:i+4]
	SUBPS  16(DI)(AX*4), X3
	SUBPS  32(DI)(AX*4), X4
	SUBPS  48(DI)(AX*4), X5

    MULPS X2, X2
    MULPS X3, X3
    MULPS X4, X4
    MULPS X5, X5

    ADDPS X2, X1
    ADDPS X3, X1
    ADDPS X4, X1
    ADDPS X5, X1

	ADDQ   $16, AX          // i += 16
	LOOP   l2_loop        // while (--CX) > 0
	CMPQ   BX, $0           // if BX == 0 { return }
	JE     l2_end

l2_tail4_start: // Reset loop counter for 4-wide tail loop
	MOVQ BX, CX          // CX = floor( BX / 4 )
	SHRQ $2, CX
	JZ   l2_tail_start // if CX == 0 { goto l2_tail_start }

l2_tail4: // Loop unrolled 4x   do {
	MOVUPS (SI)(AX*4), X2 // X2 = x[i]
	MULPS  X0, X2         // X2 *= a
	ADDPS  (DI)(AX*4), X2 // X2 += y[i]
	MOVUPS X2, (DI)(AX*4) // y[i] = X2
	ADDQ   $4, AX         // i += 4
	LOOP   l2_tail4     // } while --CX > 0

l2_tail_start: // Reset loop counter for 1-wide tail loop
	MOVQ BX, CX   // CX = BX % 4
	ANDQ $3, CX
	JZ   l2_end // if CX == 0 { return }

l2_tail:
	MOVSS (SI)(AX*4), X1 // X1 = x[i]
	MULSS X0, X1         // X1 *= a
	ADDSS (DI)(AX*4), X1 // X1 += y[i]
	MOVSS X1, (DI)(AX*4) // y[i] = X1
	INCQ  AX             // i++
	LOOP  l2_tail      // } while --CX > 0

l2_end:    
	
    MOVUPS X1, X0
    SHUFPS $0x93, X0, X0
    ADDPS X0, X1
    SHUFPS $0x93, X0, X0
    ADDPS X0, X1
    SHUFPS $0x93, X0, X0
    ADDPS X0, X1
    
    MOVUPS    X1, sum+48(FP) // Return final sum.
	RET
