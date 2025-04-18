
/*!
@addtogroup crypto_block_aes_ttable AES TTable Reference
@brief Standard TTable implementation of AES w.out acceleration .
@ingroup crypto_block_aes
@{
*/

#include "util.h"

#include "api_aes.h"
#include "common.h"

#define AES_DEC_TBOX_X { \
  TUPLE(52,A7,51,F4,50), TUPLE(09,65,7E,41,53), TUPLE(6A,A4,1A,17,C3), TUPLE(D5,5E,3A,27,96), \
  TUPLE(30,6B,3B,AB,CB), TUPLE(36,45,1F,9D,F1), TUPLE(A5,58,AC,FA,AB), TUPLE(38,03,4B,E3,93), \
  TUPLE(BF,FA,20,30,55), TUPLE(40,6D,AD,76,F6), TUPLE(A3,76,88,CC,91), TUPLE(9E,4C,F5,02,25), \
  TUPLE(81,D7,4F,E5,FC), TUPLE(F3,CB,C5,2A,D7), TUPLE(D7,44,26,35,80), TUPLE(FB,A3,B5,62,8F), \
  TUPLE(7C,5A,DE,B1,49), TUPLE(E3,1B,25,BA,67), TUPLE(39,0E,45,EA,98), TUPLE(82,C0,5D,FE,E1), \
  TUPLE(9B,75,C3,2F,02), TUPLE(2F,F0,81,4C,12), TUPLE(FF,97,8D,46,A3), TUPLE(87,F9,6B,D3,C6), \
  TUPLE(34,5F,03,8F,E7), TUPLE(8E,9C,15,92,95), TUPLE(43,7A,BF,6D,EB), TUPLE(44,59,95,52,DA), \
  TUPLE(C4,83,D4,BE,2D), TUPLE(DE,21,58,74,D3), TUPLE(E9,69,49,E0,29), TUPLE(CB,C8,8E,C9,44), \
  TUPLE(54,89,75,C2,6A), TUPLE(7B,79,F4,8E,78), TUPLE(94,3E,99,58,6B), TUPLE(32,71,27,B9,DD), \
  TUPLE(A6,4F,BE,E1,B6), TUPLE(C2,AD,F0,88,17), TUPLE(23,AC,C9,20,66), TUPLE(3D,3A,7D,CE,B4), \
  TUPLE(EE,4A,63,DF,18), TUPLE(4C,31,E5,1A,82), TUPLE(95,33,97,51,60), TUPLE(0B,7F,62,53,45), \
  TUPLE(42,77,B1,64,E0), TUPLE(FA,AE,BB,6B,84), TUPLE(C3,A0,FE,81,1C), TUPLE(4E,2B,F9,08,94), \
  TUPLE(08,68,70,48,58), TUPLE(2E,FD,8F,45,19), TUPLE(A1,6C,94,DE,87), TUPLE(66,F8,52,7B,B7), \
  TUPLE(28,D3,AB,73,23), TUPLE(D9,02,72,4B,E2), TUPLE(24,8F,E3,1F,57), TUPLE(B2,AB,66,55,2A), \
  TUPLE(76,28,B2,EB,07), TUPLE(5B,C2,2F,B5,03), TUPLE(A2,7B,86,C5,9A), TUPLE(49,08,D3,37,A5), \
  TUPLE(6D,87,30,28,F2), TUPLE(8B,A5,23,BF,B2), TUPLE(D1,6A,02,03,BA), TUPLE(25,82,ED,16,5C), \
  TUPLE(72,1C,8A,CF,2B), TUPLE(F8,B4,A7,79,92), TUPLE(F6,F2,F3,07,F0), TUPLE(64,E2,4E,69,A1), \
  TUPLE(86,F4,65,DA,CD), TUPLE(68,BE,06,05,D5), TUPLE(98,62,D1,34,1F), TUPLE(16,FE,C4,A6,8A), \
  TUPLE(D4,53,34,2E,9D), TUPLE(A4,55,A2,F3,A0), TUPLE(5C,E1,05,8A,32), TUPLE(CC,EB,A4,F6,75), \
  TUPLE(5D,EC,0B,83,39), TUPLE(65,EF,40,60,AA), TUPLE(B6,9F,5E,71,06), TUPLE(92,10,BD,6E,51), \
  TUPLE(6C,8A,3E,21,F9), TUPLE(70,06,96,DD,3D), TUPLE(48,05,DD,3E,AE), TUPLE(50,BD,4D,E6,46), \
  TUPLE(FD,8D,91,54,B5), TUPLE(ED,5D,71,C4,05), TUPLE(B9,D4,04,06,6F), TUPLE(DA,15,60,50,FF), \
  TUPLE(5E,FB,19,98,24), TUPLE(15,E9,D6,BD,97), TUPLE(46,43,89,40,CC), TUPLE(57,9E,67,D9,77), \
  TUPLE(A7,42,B0,E8,BD), TUPLE(8D,8B,07,89,88), TUPLE(9D,5B,E7,19,38), TUPLE(84,EE,79,C8,DB), \
  TUPLE(90,0A,A1,7C,47), TUPLE(D8,0F,7C,42,E9), TUPLE(AB,1E,F8,84,C9), TUPLE(00,00,00,00,00), \
  TUPLE(8C,86,09,80,83), TUPLE(BC,ED,32,2B,48), TUPLE(D3,70,1E,11,AC), TUPLE(0A,72,6C,5A,4E), \
  TUPLE(F7,FF,FD,0E,FB), TUPLE(E4,38,0F,85,56), TUPLE(58,D5,3D,AE,1E), TUPLE(05,39,36,2D,27), \
  TUPLE(B8,D9,0A,0F,64), TUPLE(B3,A6,68,5C,21), TUPLE(45,54,9B,5B,D1), TUPLE(06,2E,24,36,3A), \
  TUPLE(D0,67,0C,0A,B1), TUPLE(2C,E7,93,57,0F), TUPLE(1E,96,B4,EE,D2), TUPLE(8F,91,1B,9B,9E), \
  TUPLE(CA,C5,80,C0,4F), TUPLE(3F,20,61,DC,A2), TUPLE(0F,4B,5A,77,69), TUPLE(02,1A,1C,12,16), \
  TUPLE(C1,BA,E2,93,0A), TUPLE(AF,2A,C0,A0,E5), TUPLE(BD,E0,3C,22,43), TUPLE(03,17,12,1B,1D), \
  TUPLE(01,0D,0E,09,0B), TUPLE(13,C7,F2,8B,AD), TUPLE(8A,A8,2D,B6,B9), TUPLE(6B,A9,14,1E,C8), \
  TUPLE(3A,19,57,F1,85), TUPLE(91,07,AF,75,4C), TUPLE(11,DD,EE,99,BB), TUPLE(41,60,A3,7F,FD), \
  TUPLE(4F,26,F7,01,9F), TUPLE(67,F5,5C,72,BC), TUPLE(DC,3B,44,66,C5), TUPLE(EA,7E,5B,FB,34), \
  TUPLE(97,29,8B,43,76), TUPLE(F2,C6,CB,23,DC), TUPLE(CF,FC,B6,ED,68), TUPLE(CE,F1,B8,E4,63), \
  TUPLE(F0,DC,D7,31,CA), TUPLE(B4,85,42,63,10), TUPLE(E6,22,13,97,40), TUPLE(73,11,84,C6,20), \
  TUPLE(96,24,85,4A,7D), TUPLE(AC,3D,D2,BB,F8), TUPLE(74,32,AE,F9,11), TUPLE(22,A1,C7,29,6D), \
  TUPLE(E7,2F,1D,9E,4B), TUPLE(AD,30,DC,B2,F3), TUPLE(35,52,0D,86,EC), TUPLE(85,E3,77,C1,D0), \
  TUPLE(E2,16,2B,B3,6C), TUPLE(F9,B9,A9,70,99), TUPLE(37,48,11,94,FA), TUPLE(E8,64,47,E9,22), \
  TUPLE(1C,8C,A8,FC,C4), TUPLE(75,3F,A0,F0,1A), TUPLE(DF,2C,56,7D,D8), TUPLE(6E,90,22,33,EF), \
  TUPLE(47,4E,87,49,C7), TUPLE(F1,D1,D9,38,C1), TUPLE(1A,A2,8C,CA,FE), TUPLE(71,0B,98,D4,36), \
  TUPLE(1D,81,A6,F5,CF), TUPLE(29,DE,A5,7A,28), TUPLE(C5,8E,DA,B7,26), TUPLE(89,BF,3F,AD,A4), \
  TUPLE(6F,9D,2C,3A,E4), TUPLE(B7,92,50,78,0D), TUPLE(62,CC,6A,5F,9B), TUPLE(0E,46,54,7E,62), \
  TUPLE(AA,13,F6,8D,C2), TUPLE(18,B8,90,D8,E8), TUPLE(BE,F7,2E,39,5E), TUPLE(1B,AF,82,C3,F5), \
  TUPLE(FC,80,9F,5D,BE), TUPLE(56,93,69,D0,7C), TUPLE(3E,2D,6F,D5,A9), TUPLE(4B,12,CF,25,B3), \
  TUPLE(C6,99,C8,AC,3B), TUPLE(D2,7D,10,18,A7), TUPLE(79,63,E8,9C,6E), TUPLE(20,BB,DB,3B,7B), \
  TUPLE(9A,78,CD,26,09), TUPLE(DB,18,6E,59,F4), TUPLE(C0,B7,EC,9A,01), TUPLE(FE,9A,83,4F,A8), \
  TUPLE(78,6E,E6,95,65), TUPLE(CD,E6,AA,FF,7E), TUPLE(5A,CF,21,BC,08), TUPLE(F4,E8,EF,15,E6), \
  TUPLE(1F,9B,BA,E7,D9), TUPLE(DD,36,4A,6F,CE), TUPLE(A8,09,EA,9F,D4), TUPLE(33,7C,29,B0,D6), \
  TUPLE(88,B2,31,A4,AF), TUPLE(07,23,2A,3F,31), TUPLE(C7,94,C6,A5,30), TUPLE(31,66,35,A2,C0), \
  TUPLE(B1,BC,74,4E,37), TUPLE(12,CA,FC,82,A6), TUPLE(10,D0,E0,90,B0), TUPLE(59,D8,33,A7,15), \
  TUPLE(27,98,F1,04,4A), TUPLE(80,DA,41,EC,F7), TUPLE(EC,50,7F,CD,0E), TUPLE(5F,F6,17,91,2F), \
  TUPLE(60,D6,76,4D,8D), TUPLE(51,B0,43,EF,4D), TUPLE(7F,4D,CC,AA,54), TUPLE(A9,04,E4,96,DF), \
  TUPLE(19,B5,9E,D1,E3), TUPLE(B5,88,4C,6A,1B), TUPLE(4A,1F,C1,2C,B8), TUPLE(0D,51,46,65,7F), \
  TUPLE(2D,EA,9D,5E,04), TUPLE(E5,35,01,8C,5D), TUPLE(7A,74,FA,87,73), TUPLE(9F,41,FB,0B,2E), \
  TUPLE(93,1D,B3,67,5A), TUPLE(C9,D2,92,DB,52), TUPLE(9C,56,E9,10,33), TUPLE(EF,47,6D,D6,13), \
  TUPLE(A0,61,9A,D7,8C), TUPLE(E0,0C,37,A1,7A), TUPLE(3B,14,59,F8,8E), TUPLE(4D,3C,EB,13,89), \
  TUPLE(AE,27,CE,A9,EE), TUPLE(2A,C9,B7,61,35), TUPLE(F5,E5,E1,1C,ED), TUPLE(B0,B1,7A,47,3C), \
  TUPLE(C8,DF,9C,D2,59), TUPLE(EB,73,55,F2,3F), TUPLE(BB,CE,18,14,79), TUPLE(3C,37,73,C7,BF), \
  TUPLE(83,CD,53,F7,EA), TUPLE(53,AA,5F,FD,5B), TUPLE(99,6F,DF,3D,14), TUPLE(61,DB,78,44,86), \
  TUPLE(17,F3,CA,AF,81), TUPLE(2B,C4,B9,68,3E), TUPLE(04,34,38,24,2C), TUPLE(7E,40,C2,A3,5F), \
  TUPLE(BA,C3,16,1D,72), TUPLE(77,25,BC,E2,0C), TUPLE(D6,49,28,3C,8B), TUPLE(26,95,FF,0D,41), \
  TUPLE(E1,01,39,A8,71), TUPLE(69,B3,08,0C,DE), TUPLE(14,E4,D8,B4,9C), TUPLE(63,C1,64,56,90), \
  TUPLE(55,84,7B,CB,61), TUPLE(21,B6,D5,32,70), TUPLE(0C,5C,48,6C,74), TUPLE(7D,57,D0,B8,42)  \
}

#define TUPLE(a1,a9,aB,aD,aE) 0x##aE##a9##aD##aB
uint32_t AES_DEC_TBOX_0[] = AES_DEC_TBOX_X;
#undef TUPLE
#define TUPLE(a1,a9,aB,aD,aE) 0x##a9##aD##aB##aE
uint32_t AES_DEC_TBOX_1[] = AES_DEC_TBOX_X;
#undef TUPLE
#define TUPLE(a1,a9,aB,aD,aE) 0x##aD##aB##aE##a9
uint32_t AES_DEC_TBOX_2[] = AES_DEC_TBOX_X;
#undef TUPLE
#define TUPLE(a1,a9,aB,aD,aE) 0x##aB##aE##a9##aD
uint32_t AES_DEC_TBOX_3[] = AES_DEC_TBOX_X;
#undef TUPLE
#define TUPLE(a1,a9,aB,aD,aE) 0x##a1##a1##a1##a1
uint32_t AES_DEC_TBOX_4[] = AES_DEC_TBOX_X;
#undef TUPLE

#define AES_DEC_RND_INIT() {    \
  t_0 = rkp[ 0 ] ^ t_0;         \
  t_1 = rkp[ 1 ] ^ t_1;         \
  t_2 = rkp[ 2 ] ^ t_2;         \
  t_3 = rkp[ 3 ] ^ t_3;         \
                                \
  rkp -= AES_128_NB;            \
}

#define AES_DEC_RND_ITER() {                                                 \
  t_4 = rkp[ 0 ] ^ ( AES_DEC_TBOX_0[ ( t_0 >>  0 ) & 0xFF ]              ) ^ \
                   ( AES_DEC_TBOX_1[ ( t_3 >>  8 ) & 0xFF ]              ) ^ \
                   ( AES_DEC_TBOX_2[ ( t_2 >> 16 ) & 0xFF ]              ) ^ \
                   ( AES_DEC_TBOX_3[ ( t_1 >> 24 ) & 0xFF ]              ) ; \
  t_5 = rkp[ 1 ] ^ ( AES_DEC_TBOX_0[ ( t_1 >>  0 ) & 0xFF ]              ) ^ \
                   ( AES_DEC_TBOX_1[ ( t_0 >>  8 ) & 0xFF ]              ) ^ \
                   ( AES_DEC_TBOX_2[ ( t_3 >> 16 ) & 0xFF ]              ) ^ \
                   ( AES_DEC_TBOX_3[ ( t_2 >> 24 ) & 0xFF ]              ) ; \
  t_6 = rkp[ 2 ] ^ ( AES_DEC_TBOX_0[ ( t_2 >>  0 ) & 0xFF ]              ) ^ \
                   ( AES_DEC_TBOX_1[ ( t_1 >>  8 ) & 0xFF ]              ) ^ \
                   ( AES_DEC_TBOX_2[ ( t_0 >> 16 ) & 0xFF ]              ) ^ \
                   ( AES_DEC_TBOX_3[ ( t_3 >> 24 ) & 0xFF ]              ) ; \
  t_7 = rkp[ 3 ] ^ ( AES_DEC_TBOX_0[ ( t_3 >>  0 ) & 0xFF ]              ) ^ \
                   ( AES_DEC_TBOX_1[ ( t_2 >>  8 ) & 0xFF ]              ) ^ \
                   ( AES_DEC_TBOX_2[ ( t_1 >> 16 ) & 0xFF ]              ) ^ \
                   ( AES_DEC_TBOX_3[ ( t_0 >> 24 ) & 0xFF ]              ) ; \
                                                                             \
  rkp -= AES_128_NB; t_0 = t_4; t_1 = t_5; t_2 = t_6; t_3 = t_7;             \
}

#define AES_DEC_RND_FINI() {                                                 \
  t_4 = rkp[ 0 ] ^ ( AES_DEC_TBOX_4[ ( t_0 >>  0 ) & 0xFF ] & 0x000000FF ) ^ \
                   ( AES_DEC_TBOX_4[ ( t_3 >>  8 ) & 0xFF ] & 0x0000FF00 ) ^ \
                   ( AES_DEC_TBOX_4[ ( t_2 >> 16 ) & 0xFF ] & 0x00FF0000 ) ^ \
                   ( AES_DEC_TBOX_4[ ( t_1 >> 24 ) & 0xFF ] & 0xFF000000 ) ; \
  t_5 = rkp[ 1 ] ^ ( AES_DEC_TBOX_4[ ( t_1 >>  0 ) & 0xFF ] & 0x000000FF ) ^ \
                   ( AES_DEC_TBOX_4[ ( t_0 >>  8 ) & 0xFF ] & 0x0000FF00 ) ^ \
                   ( AES_DEC_TBOX_4[ ( t_3 >> 16 ) & 0xFF ] & 0x00FF0000 ) ^ \
                   ( AES_DEC_TBOX_4[ ( t_2 >> 24 ) & 0xFF ] & 0xFF000000 ) ; \
  t_6 = rkp[ 2 ] ^ ( AES_DEC_TBOX_4[ ( t_2 >>  0 ) & 0xFF ] & 0x000000FF ) ^ \
                   ( AES_DEC_TBOX_4[ ( t_1 >>  8 ) & 0xFF ] & 0x0000FF00 ) ^ \
                   ( AES_DEC_TBOX_4[ ( t_0 >> 16 ) & 0xFF ] & 0x00FF0000 ) ^ \
                   ( AES_DEC_TBOX_4[ ( t_3 >> 24 ) & 0xFF ] & 0xFF000000 ) ; \
  t_7 = rkp[ 3 ] ^ ( AES_DEC_TBOX_4[ ( t_3 >>  0 ) & 0xFF ] & 0x000000FF ) ^ \
                   ( AES_DEC_TBOX_4[ ( t_2 >>  8 ) & 0xFF ] & 0x0000FF00 ) ^ \
                   ( AES_DEC_TBOX_4[ ( t_1 >> 16 ) & 0xFF ] & 0x00FF0000 ) ^ \
                   ( AES_DEC_TBOX_4[ ( t_0 >> 24 ) & 0xFF ] & 0xFF000000 ) ; \
                                                                             \
  rkp -= AES_128_NB; t_0 = t_4; t_1 = t_5; t_2 = t_6; t_3 = t_7;             \
}



/*!
*/
void    aes_dec_key_schedule_inv_mc (
    uint32_t * const rk,
    uint8_t  * const ck,
    int              nr
){
    // First, call the encryption key-schedule
    for( int i = 1; i < nr; i++ ) {
      uint32_t t_0 = rk[ ( i * 4 ) + 0 ];
      uint32_t t_1 = rk[ ( i * 4 ) + 1 ];
      uint32_t t_2 = rk[ ( i * 4 ) + 2 ];
      uint32_t t_3 = rk[ ( i * 4 ) + 3 ];

      t_0 = AES_DEC_TBOX_0[ AES_ENC_TBOX_4[ ( t_0 >>  0 ) & 0xFF ] & 0xFF ] ^
            AES_DEC_TBOX_1[ AES_ENC_TBOX_4[ ( t_0 >>  8 ) & 0xFF ] & 0xFF ] ^
            AES_DEC_TBOX_2[ AES_ENC_TBOX_4[ ( t_0 >> 16 ) & 0xFF ] & 0xFF ] ^
            AES_DEC_TBOX_3[ AES_ENC_TBOX_4[ ( t_0 >> 24 ) & 0xFF ] & 0xFF ] ;
      t_1 = AES_DEC_TBOX_0[ AES_ENC_TBOX_4[ ( t_1 >>  0 ) & 0xFF ] & 0xFF ] ^
            AES_DEC_TBOX_1[ AES_ENC_TBOX_4[ ( t_1 >>  8 ) & 0xFF ] & 0xFF ] ^
            AES_DEC_TBOX_2[ AES_ENC_TBOX_4[ ( t_1 >> 16 ) & 0xFF ] & 0xFF ] ^
            AES_DEC_TBOX_3[ AES_ENC_TBOX_4[ ( t_1 >> 24 ) & 0xFF ] & 0xFF ] ;
      t_2 = AES_DEC_TBOX_0[ AES_ENC_TBOX_4[ ( t_2 >>  0 ) & 0xFF ] & 0xFF ] ^
            AES_DEC_TBOX_1[ AES_ENC_TBOX_4[ ( t_2 >>  8 ) & 0xFF ] & 0xFF ] ^
            AES_DEC_TBOX_2[ AES_ENC_TBOX_4[ ( t_2 >> 16 ) & 0xFF ] & 0xFF ] ^
            AES_DEC_TBOX_3[ AES_ENC_TBOX_4[ ( t_2 >> 24 ) & 0xFF ] & 0xFF ] ;
      t_3 = AES_DEC_TBOX_0[ AES_ENC_TBOX_4[ ( t_3 >>  0 ) & 0xFF ] & 0xFF ] ^
            AES_DEC_TBOX_1[ AES_ENC_TBOX_4[ ( t_3 >>  8 ) & 0xFF ] & 0xFF ] ^
            AES_DEC_TBOX_2[ AES_ENC_TBOX_4[ ( t_3 >> 16 ) & 0xFF ] & 0xFF ] ^
            AES_DEC_TBOX_3[ AES_ENC_TBOX_4[ ( t_3 >> 24 ) & 0xFF ] & 0xFF ] ;

      rk[ ( i * 4 ) + 0 ] = t_0;
      rk[ ( i * 4 ) + 1 ] = t_1;
      rk[ ( i * 4 ) + 2 ] = t_2;
      rk[ ( i * 4 ) + 3 ] = t_3;
    }
}

// defined in aes_enc.c
extern void    aes_key_schedule (
    uint32_t * const rk , //!< Output Nk*(Nr+1) word cipher key.
    uint8_t  * const ck , //!< Input Nk byte cipher key
    const int  Nk , //!< Number of words in the key.
    const int  Nr   //!< Number of rounds.
);

void    aes_128_dec_key_schedule (
    uint32_t * const rk,
    uint8_t  * const ck
){
    aes_128_enc_key_schedule(rk, ck);
    aes_dec_key_schedule_inv_mc(rk,ck,AES_128_NR);
}

void    aes_192_dec_key_schedule (
    uint32_t * const rk,
    uint8_t  * const ck
){
    aes_192_enc_key_schedule(rk, ck);
    aes_dec_key_schedule_inv_mc(rk,ck,AES_192_NR);
}


void    aes_256_dec_key_schedule (
    uint32_t * const rk,
    uint8_t  * const ck
){
    aes_256_enc_key_schedule(rk, ck);
    aes_dec_key_schedule_inv_mc(rk,ck,AES_256_NR);
}

void    aes_ecb_decrypt (
    uint8_t     pt [AES_BLOCK_BYTES],
    uint8_t     ct [AES_BLOCK_BYTES],
    uint32_t  * rk,
    int         nr
){
    uint32_t *rkp = ( AES_128_NB * nr) + ( uint32_t* )( rk ), t_0, t_1, t_2, t_3, t_4, t_5, t_6, t_7;

    t_0 = U8_TO_U32LE((ct +  0));
    t_1 = U8_TO_U32LE((ct +  4));
    t_2 = U8_TO_U32LE((ct +  8));
    t_3 = U8_TO_U32LE((ct + 12));

    AES_DEC_RND_INIT();

    for( int i = 1; i < nr; i++ ) {
      AES_DEC_RND_ITER();
    }

    AES_DEC_RND_FINI(); 

    U32_TO_U8LE(pt, t_0,  0 );
    U32_TO_U8LE(pt, t_1,  4 );
    U32_TO_U8LE(pt, t_2,  8 );
    U32_TO_U8LE(pt, t_3, 12 );
}

void    aes_128_ecb_decrypt (
    uint8_t     pt [AES_BLOCK_BYTES],
    uint8_t     ct [AES_BLOCK_BYTES],
    uint32_t  * rk
){
    aes_ecb_decrypt(pt,ct,rk,AES_128_NR);
}


void    aes_192_ecb_decrypt (
    uint8_t     pt [AES_BLOCK_BYTES],
    uint8_t     ct [AES_BLOCK_BYTES],
    uint32_t  * rk
){
    aes_ecb_decrypt(pt,ct,rk,AES_192_NR);
}


void    aes_256_ecb_decrypt (
    uint8_t     pt [AES_BLOCK_BYTES],
    uint8_t     ct [AES_BLOCK_BYTES],
    uint32_t  * rk
){
    aes_ecb_decrypt(pt,ct,rk,AES_256_NR);
}

//!@}

