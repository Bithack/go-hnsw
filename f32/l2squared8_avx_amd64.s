//+build !noasm,!appengine

#include "textflag.h"

// This version is AVX optimized for vectors where the dimension is a multiple of 8
// Latest GO versions seems to align []float32 slices on 32-bytes on a 64-bit system, so we skip checks for this...

// func L2Squared8AVX(x, y []float32) (sum float32)
TEXT ·L2Squared8AVX(SB), NOSPLIT, $0	
    MOVQ    x_base+0(FP), SI  // SI = &x
    MOVQ    x_len+8(FP), AX   // AX = len(x)    
	MOVQ    y_base+24(FP), DI // DI = &y    

    MOVQ    AX, BX            // BX = len(x)
    
    SHLQ     $2, AX
    ADDQ     AX, SI
    ADDQ     AX, DI    
    SHRQ     $2, AX
    NEGQ     AX    

    BYTE $0xc5; BYTE $0xfc; BYTE $0x57; BYTE $0xc0             // vxorps ymm0,ymm0,ymm0    

    ANDQ    $0xF, BX        // BX = len % 16
    JZ      l2_loop_16

    // PRE LOOP, 8 values
    BYTE $0xc5; BYTE $0xfc; BYTE $0x28; BYTE $0x0c; BYTE $0x86                     //vmovaps ymm1,YMMWORD PTR [esi+eax*4]   
    BYTE $0xc5; BYTE $0xf4; BYTE $0x5c; BYTE $0x0c; BYTE $0x87                   // vsubps ymm1,ymm1,YMMWORD PTR [edi+eax*4] 
    BYTE $0xc5; BYTE $0xf4; BYTE $0x59; BYTE $0xc9     
    BYTE $0xc5; BYTE $0xfc; BYTE $0x58; BYTE $0xc1;    
    ADDQ    $8, AX

l2_loop_16:
    BYTE $0xc5; BYTE $0xfc; BYTE $0x28; BYTE $0x0c; BYTE $0x86                     //vmovaps ymm1,YMMWORD PTR [esi+eax*4]    
    BYTE $0xc5; BYTE $0xfc; BYTE $0x28; BYTE $0x54; BYTE $0x86; BYTE $0x20       //vmovaps ymm2,YMMWORD PTR [esi+eax*4+0x20]
    BYTE $0xc5; BYTE $0xf4; BYTE $0x5c; BYTE $0x0c; BYTE $0x87                   // vsubps ymm1,ymm1,YMMWORD PTR [edi+eax*4]
    BYTE $0xc5; BYTE $0xec; BYTE $0x5c; BYTE $0x54; BYTE $0x87; BYTE $0x20       // vsubps ymm2,ymm2,YMMWORD PTR [edi+eax*4+0x20]
    BYTE $0xc5; BYTE $0xf4; BYTE $0x59; BYTE $0xc9                              // vmulps ymmX,ymmX,ymmX 
    BYTE $0xc5; BYTE $0xec; BYTE $0x59; BYTE $0xd2     
    BYTE $0xc5; BYTE $0xfc; BYTE $0x58; BYTE $0xc1;                             // vaddps ymm0,ymm0,ymmX
    BYTE $0xc5; BYTE $0xfc; BYTE $0x58; BYTE $0xc2;
    ADDQ   $16, AX           // eax += 16
    JS     l2_loop_16    	// jump if negative

l2_end:    	
    //auto x = _mm256_permute2f128_ps(v, v, 1);
    BYTE $0xc4; BYTE $0xe3; BYTE $0x7d; BYTE $0x06; BYTE $0xc8; BYTE $0x01;  // vperm2f128 ymm1,ymm0,ymm0,0x1    
    //auto y = _mm256_add_ps(v, x);
    BYTE $0xc5;BYTE $0xfc; BYTE $0x58;BYTE $0xc1;               // vaddps ymm0,ymm0,ymm1
    //x = _mm256_shuffle_ps(y, y, _MM_SHUFFLE(2, 3, 0, 1)=0xB1);
    //_MM_SHUFFLE
    BYTE $0xc5;BYTE $0xfc;BYTE $0xc6;BYTE $0xc8; BYTE $0xb1     // vshufps ymm1,ymm0,ymm0,0xb1
    //x = _mm256_add_ps(x, y);
    BYTE $0xc5;BYTE $0xf4; BYTE $0x58;BYTE $0xc8                 // vaddps ymm1,ymm1,ymm0
    //y = _mm256_shuffle_ps(x, x, _MM_SHUFFLE(1, 0, 3, 2)=0x8E);
    BYTE $0xc5;BYTE $0xf4; BYTE $0xc6;BYTE $0xc1; BYTE $0x8e     // vshufps ymm0,ymm1,ymm1,0x8e
    //return _mm256_add_ps(x, y);
    BYTE $0xc5; BYTE $0xf4; BYTE $0x58; BYTE $0xc8                 // vaddps ymm1,ymm1,ymm0
    
    VZEROUPPER
    MOVSS    X1, ret+48(FP) // Return final sum.

	RET
