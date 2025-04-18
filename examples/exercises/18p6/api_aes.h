
#include <stdint.h>

/*!
@defgroup crypto_block_aes Crypto Block AES
@{

AES  |   Nk  | Nb   | Nr
-----|-------|------|---------------
128  |  4    | 4    | 10
192  |  6    | 4    | 12
256  |  8    | 4    | 14

*/

#ifndef __API_AES_H__
#define __API_AES_H__

//! Number of bytes in a single AES block
#define AES_BLOCK_BYTES     16

//! Block size in 4-byte words for AES 128
#define AES_128_NB          4
#define AES_192_NB          4
#define AES_256_NB          4

//! Words in AES 128 cipher key
#define AES_128_NK          4 
#define AES_192_NK          6 
#define AES_256_NK          8 

//! Number of rounds for AES 128
#define AES_128_NR          10
#define AES_192_NR          12
#define AES_256_NR          14

//! Bytes in an AES 128 Cipher key
#define AES_128_KEY_BYTES   (4*AES_128_NK)
#define AES_192_KEY_BYTES   (4*AES_192_NK)
#define AES_256_KEY_BYTES   (4*AES_256_NK)

#define AES_128_RK_WORDS    44
#define AES_192_RK_WORDS    52
#define AES_256_RK_WORDS    60

//! Number of bytes in the expanded AES 128 key
#define AES_128_RK_BYTES    (4*AES_128_RK_WORDS)
#define AES_192_RK_BYTES    (4*AES_192_RK_WORDS)
#define AES_256_RK_BYTES    (4*AES_256_RK_WORDS)


/*!
@brief Key expansion function for the AES 128 parameterisation - encrypt
@param [out] rk - The expanded key schedule
@param [in]  ck - The cipher key to expand
*/
void    aes_128_enc_key_schedule (
    uint32_t * const rk,
    uint8_t  * const ck
);

/*!
@brief Key expansion function for the AES 192 parameterisation - encrypt
@param [out] rk - The expanded key schedule
@param [in]  ck - The cipher key to expand
*/
void    aes_192_enc_key_schedule (
    uint32_t * const rk,
    uint8_t  * const ck
);

/*!
@brief Key expansion function for the AES 256 parameterisation - encrypt
@param [out] rk - The expanded key schedule
@param [in]  ck - The cipher key to expand
*/
void    aes_256_enc_key_schedule (
    uint32_t * const rk,
    uint8_t  * const ck
);


/*!
@brief Key expansion function for the AES 128 parameterisation - decrypt
@param [out] rk - The expanded key schedule
@param [in]  ck - The cipher key to expand
*/
void    aes_128_dec_key_schedule (
    uint32_t * const rk,
    uint8_t  * const ck
);


/*!
@brief Key expansion function for the AES 192 parameterisation - decrypt
@param [out] rk - The expanded key schedule
@param [in]  ck - The cipher key to expand
*/
void    aes_192_dec_key_schedule (
    uint32_t * const rk,
    uint8_t  * const ck
);

/*!
@brief Key expansion function for the AES 256 parameterisation - decrypt
@param [out] rk - The expanded key schedule
@param [in]  ck - The cipher key to expand
*/
void    aes_256_dec_key_schedule (
    uint32_t * const rk,
    uint8_t  * const ck
);


/*!
@brief single-block AES 128 encrypt function
@param [out] ct - Output cipher text
@param [in]  pt - Input plaintext
@param [in]  rk - The expanded key schedule
@param [in]  nr - Number of encryption rounds to perform.
*/
void    aes_128_ecb_encrypt (
    uint8_t     ct [AES_BLOCK_BYTES],
    uint8_t     pt [AES_BLOCK_BYTES],
    uint32_t  * rk
);

/*!
@brief single-block AES 192 encrypt function
@param [out] ct - Output cipher text
@param [in]  pt - Input plaintext
@param [in]  rk - The expanded key schedule
@param [in]  nr - Number of encryption rounds to perform.
*/
void    aes_192_ecb_encrypt (
    uint8_t     ct [AES_BLOCK_BYTES],
    uint8_t     pt [AES_BLOCK_BYTES],
    uint32_t  * rk
);

/*!
@brief single-block AES 256 encrypt function
@param [out] ct - Output cipher text
@param [in]  pt - Input plaintext
@param [in]  rk - The expanded key schedule
@param [in]  nr - Number of encryption rounds to perform.
*/
void    aes_256_ecb_encrypt (
    uint8_t     ct [AES_BLOCK_BYTES],
    uint8_t     pt [AES_BLOCK_BYTES],
    uint32_t  * rk
);

/*!
@brief single-block AES 128 decrypt function
@param [out] pt - Output plaintext
@param [in]  ct - Input cipher text
@param [in]  rk - The expanded key schedule
@param [in]  nr - Number of decryption rounds to perform.
*/
void    aes_128_ecb_decrypt (
    uint8_t     pt [AES_BLOCK_BYTES],
    uint8_t     ct [AES_BLOCK_BYTES],
    uint32_t  * rk
);

/*!
@brief single-block AES 192 decrypt function
@param [out] pt - Output plaintext
@param [in]  ct - Input cipher text
@param [in]  rk - The expanded key schedule
@param [in]  nr - Number of decryption rounds to perform.
*/
void    aes_192_ecb_decrypt (
    uint8_t     pt [AES_BLOCK_BYTES],
    uint8_t     ct [AES_BLOCK_BYTES],
    uint32_t  * rk
);


/*!
@brief single-block AES 256 decrypt function
@param [out] pt - Output plaintext
@param [in]  ct - Input cipher text
@param [in]  rk - The expanded key schedule
@param [in]  nr - Number of decryption rounds to perform.
*/
void    aes_256_ecb_decrypt (
    uint8_t     pt [AES_BLOCK_BYTES],
    uint8_t     ct [AES_BLOCK_BYTES],
    uint32_t  * rk
);

#endif

//! @}
