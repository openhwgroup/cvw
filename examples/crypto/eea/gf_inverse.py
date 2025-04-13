# gf_inverse.py
# Extended Euclidean Algorithm
# james.stine@okstate.edu 8 April 2025

def gf_mul(a, b, modulus):
    result = 0
    while b:
        if b & 1:
            result ^= a
        b >>= 1
        a <<= 1
        if a & (1 << 8):
            a ^= modulus
    return result & 0xFF

def gf_mul_poly(a, b):
    result = 0
    while b:
        if b & 1:
            result ^= a
        a <<= 1
        b >>= 1
    return result

def gf_divmod(a, b):
    if b == 0:
        raise ZeroDivisionError()
    deg_a = a.bit_length() - 1
    deg_b = b.bit_length() - 1
    quotient = 0
    while deg_a >= deg_b:
        shift = deg_a - deg_b
        quotient ^= 1 << shift
        a ^= b << shift
        deg_a = a.bit_length() - 1
    return quotient, a

def gf_inverse(a, modulus):
    if a == 0:
        raise ValueError("No inverse for 0 in GF(2^n)")

    r0, r1 = modulus, a
    s0, s1 = 0, 1
    loop_count = 0

    print(f"{'Loop':<5} {'r0':>6} {'r1':>6} {'q':>6} {'s0':>6} {'s1':>6}")

    while r1 != 0:
        q, _ = gf_divmod(r0, r1)
        new_r = r0 ^ gf_mul_poly(q, r1)
        new_s = s0 ^ gf_mul_poly(q, s1)

        print(f"{loop_count:<5} {r0:06X} {r1:06X} {q:06X} {s0:06X} {s1:06X}")

        r0, r1 = r1, new_r
        s0, s1 = s1, new_s
        loop_count += 1

    print(f"{loop_count:<5} {r0:06X} {' '*6} {' '*6} {s0:06X}")

    if r0 != 1:
        raise ValueError(f"No inverse for {a:#02x} mod {modulus:#04x}")

    return s0 & 0xFF

# Example usage
if __name__ == "__main__":
    import sys
    if len(sys.argv) != 3:
        print("Usage: python gf_inverse.py <value> <modulus>")
        print("Example: python gf_inverse.py 0x53 0x11B")
        sys.exit(1)

    value = int(sys.argv[1], 0)
    modulus = int(sys.argv[2], 0)

    inv = gf_inverse(value, modulus)
    print(f"\nMultiplicative inverse of {value:#02x} in GF(2^8) mod {modulus:#04x} is {inv:#02x}")
    assert gf_mul(value, inv, modulus) == 1, "Verification failed!"
