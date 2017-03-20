//+build !noasm,!appengine

#include "textflag.h"

// This is the 16-byte SSE2 version.
// It skips pointer alignment checks, since latest GO versions seems to align all []float32 slices on 16-bytes

// func L2Squared(x, y []float32) (sum float32)
TEXT ·L2Squared(SB), NOSPLIT, $0
	MOVQ    x_base+0(FP), SI  // SI = &x
	MOVQ    y_base+24(FP), DI // DI = &y
	
    MOVQ    x_len+8(FP), BX  // BX = min( len(x), len(y) )
	CMPQ    y_len+32(FP), BX
	CMOVQLE y_len+32(FP), BX
	CMPQ    BX, $0            // if BX == 0 { return }
	JE      l2_end
	
    XORPS 	X1, X1 // sum = 0	
	XORQ    AX, AX            // i = 0

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
	MOVUPS (SI)(AX*4), X2   // X2 = x[i]
    SUBPS  (DI)(AX*4), X2   // X2 -= y[i:i+4]
	MULPS  X2, X2           // X2 *= X2
	ADDPS  X2, X1 			// X1 += X2
	ADDQ   $4, AX         // i += 4
	LOOP   l2_tail4     // } while --CX > 0

l2_tail_start: // Reset loop counter for 1-wide tail loop
	MOVQ BX, CX   // CX = BX % 4
	ANDQ $3, CX
	JZ   l2_end // if CX == 0 { return }

l2_tail:
	MOVSS (SI)(AX*4), X2 // X1 = x[i]
	SUBSS (DI)(AX*4), X2 // X1 -= y[i]
	MULSS X2, X2         // X1 *= a
	ADDSS X2, X1 		 // sum += X2	
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
    
    MOVSS    X1, ret+48(FP) // Return final sum.
	RET
