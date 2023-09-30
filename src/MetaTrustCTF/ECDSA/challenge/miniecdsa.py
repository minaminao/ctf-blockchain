#!/usr/bin/python3
from challenge.math_utils import *

# SECP256K1
# SP = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f
# SN = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141
# SA = 0x0000000000000000000000000000000000000000000000000000000000000000
# SB = 0x0000000000000000000000000000000000000000000000000000000000000007
# SGX = 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798
# SGY = 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8

# SECP256R1
SP = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF
SN = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551
SA = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC
SB = 0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B
SGX = 0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296
SGY = 0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5


# Returns (x / y) % P
def bigint_div_mod(x, y, P):
    res = div_mod(x, y, P)
    return res


# Returns (x + y) % P
def bigint_add_mod(x, y, P):
    add = x + y
    res = bigint_div_mod(add, 1, P)
    return res


# Returns (x - y) % P
def bigint_sub_mod(x, y, P):
    sub = x - y
    res = bigint_div_mod(sub, 1, P)
    return res


# Returns (x * y) % P
def bigint_mul_mod(x, y, P):
    z = x * y
    res = bigint_div_mod(z, 1, P)
    return res


class EPoint:
    def __init__(self, x, y):
        self.x = x
        self.y = y


# Returns the slope of the elliptic curve at the given point.
# The slope is used to compute pt + pt.
# Assumption: pt != 0.
def compute_doubling_slope(pt: EPoint):
    # Note that y cannot be zero: assume that it is, then pt = -pt, so 2 * pt = 0, which
    # contradicts the fact that the size of the curve is odd.
    x_sqr = bigint_mul_mod(pt.x, pt.x, SP)
    y_2 = 2 * pt.y
    slope = bigint_div_mod((3 * x_sqr + SA), y_2, SP)
    return slope


# Returns the slope of the line connecting the two given points.
# The slope is used to compute pt0 + pt1.
# Assumption: pt0.x != pt1.x (mod curve_prime).
def compute_slope(pt0: EPoint, pt1: EPoint):
    x_diff = pt0.x - pt1.x
    y_diff = pt0.y - pt1.y
    slope = bigint_div_mod(y_diff, x_diff, SP)
    return slope


# Given a point 'pt' on the elliptic curve, computes pt + pt.
def ec_double(pt: EPoint):
    if pt.x == 0:
        return pt

    slope = compute_doubling_slope(pt)
    slope_sqr = bigint_mul_mod(slope, slope, SP)

    new_x = bigint_div_mod(slope_sqr - 2 * pt.x, 1, SP)

    x_diff_slope = bigint_mul_mod(slope, (pt.x - new_x), SP)

    new_y = bigint_sub_mod(x_diff_slope, pt.y, SP)

    return EPoint(new_x, new_y)


# Adds two points on the elliptic curve.
# Assumption: pt0.x != pt1.x (however, pt0 = pt1 = 0 is allowed).
# Note that this means that the function cannot be used if pt0 = pt1
# (use ec_double() in this case) or pt0 = -pt1 (the result is 0 in this case).
def fast_ec_add(pt0: EPoint, pt1: EPoint):
    if pt0.x == 0:
        return pt1

    if pt1.x == 0:
        return pt0

    slope = compute_slope(pt0, pt1)
    slope_sqr = bigint_mul_mod(slope, slope, SP)

    new_x = bigint_div_mod(slope_sqr - pt0.x - pt1.x, 1, SP)

    x_diff_slope = bigint_mul_mod(slope, (pt0.x - new_x), SP)

    new_y = bigint_sub_mod(x_diff_slope, pt0.y, SP)

    return EPoint(new_x, new_y)


# Same as fast_ec_add, except that the cases pt0 = ±pt1 are supported.
def ec_add(pt0: EPoint, pt1: EPoint):
    x_diff = bigint_sub_mod(pt0.x, pt1.x, SP)
    if x_diff != 0:
        # pt0.x != pt1.x so we can use fast_ec_add.
        return fast_ec_add(pt0, pt1)

    y_sum = bigint_add_mod(pt0.y, pt1.y, SP)
    if y_sum == 0:
        # pt0.y = -pt1.y.
        # Note that the case pt0 = pt1 = 0 falls into this branch as well.
        ZERO_POINT = EPoint(0, 0)
        return ZERO_POINT
    else:
        # pt0.y = pt1.y.
        return ec_double(pt0)


# Do the transform: Point(x, y) -> Point(x, -y)
def ec_neg(pt: EPoint):
    neg_y = bigint_sub_mod(0, pt.y, SP)
    res = EPoint(pt.x, neg_y)
    return res


def bit(k, i):
    if i == 0:
        return k & 1
    return (k >> i) & 1


def mult(P, r):  #  multiplication r*P
    # P.affine()
    a = r
    R = EPoint(0, 0)
    k = 256

    for i in range(k - 1, -1, -1):
        R = ec_double(R)
        if bit(a, i) == 1:
            R = fast_ec_add(R, P)
    return R


# Verify a point lies on the curve.
# y^2 = x^3 + ax + b
def verify_point(pt: EPoint):
    y_sqr = bigint_mul_mod(pt.y, pt.y, SP)
    x_sqr = bigint_mul_mod(pt.x, pt.x, SP)
    x_cub = bigint_mul_mod(x_sqr, pt.x, SP)
    a_x = bigint_mul_mod(pt.x, SA, SP)
    right1 = bigint_add_mod(x_cub, a_x, SP)
    right = bigint_add_mod(right1, SB, SP)
    diff = bigint_sub_mod(y_sqr, right, SP)
    if diff == 0:
        return 1
    else:
        return 0


# Verifies that val is in the range [1, N).
def validate_signature_entry(val, N):
    if val > N:
        return 0
    else:
        return 1


def random(m, s):
    x1 = 0x53B907251BC1CEB7AB0EB41323AFB7126600FE4CB2A9A2E8A797127508F97009
    y1 = 0xC7B390484E2BAAE92DF41F50E537E57185CB18017650A6D3220A42A97727217D
    x2 = 0xACBC2999FB58C6E9015A12A4C5F3849E301649B2271EAAAF21906ED03CAFDF45
    y2 = 0x146AAC3F7F74047FD45CF0098FADEE5CD00F7F6871440387BA402F2390D7276F
    P1 = EPoint(x1, y1)
    P2 = EPoint(x2, y2)

    PM1 = mult(P1, m)
    PS1 = mult(P2, s)

    res = bigint_add_mod(PM1.x, PS1.x, SN)

    # print("random = (",hex(res),")")
    return res


def pubkey(sk):
    gen_pt = EPoint(SGX, SGY)
    res = mult(gen_pt, sk)
    return res


def sign_ecdsa(sk, msg_hash):
    gen_pt = EPoint(SGX, SGY)
    k = random(msg_hash, sk)
    pg = mult(gen_pt, k)

    r = bigint_mul_mod(pg.x, 1, SN)

    rsk = bigint_mul_mod(r, sk, SN)
    m_rsk = bigint_add_mod(msg_hash, rsk, SN)
    s = bigint_div_mod(m_rsk, k, SN)
    return r, s


# Verifies a ECDSA signature.
def verify_ecdsa(public_key_pt: EPoint, msg_hash, r, s):
    if verify_point(public_key_pt) != 1:
        return 0
    if validate_signature_entry(r, SN) != 1:
        return 0
    if validate_signature_entry(s, SN) != 1:
        return 0

    gen_pt = EPoint(SGX, SGY)

    # Compute u1 and u2.
    u1 = bigint_div_mod(msg_hash, s, SN)

    u2 = bigint_div_mod(r, s, SN)

    gen_u1 = mult(gen_pt, u1)
    pub_u2 = mult(public_key_pt, u2)

    res = ec_add(gen_u1, pub_u2)

    diff = bigint_sub_mod(res.x, r, SP)
    # The following assert also implies that res is not the zero point.
    if diff == 0:
        return 1
    return 0


def verify_ctf(r, s):
    pm3 = 0xD935BB512B4F5E4BCB07F2BE42EE5A54804379008B86B9C6C98FD605CCA64F55
    pkx = 0x209D386328994AF4BBF0FF8BB6CDBB0E87E01E2118B1C12B94C555A1726129C6
    pky = 0x76AC8F2FDA3A921BD3DCC1D2F0741B91DCD18D053A67A4ECE89761E64A0881B1
    pk = EPoint(pkx, pky)
    res = verify_ecdsa(pk, pm3, r, s)
    assert res == 1
    return res


# pub = pubkey(ps_bob)

pkx = 0x209D386328994AF4BBF0FF8BB6CDBB0E87E01E2118B1C12B94C555A1726129C6
pky = 0x76AC8F2FDA3A921BD3DCC1D2F0741B91DCD18D053A67A4ECE89761E64A0881B1

pm1 = 0xCA1AD489AB60EA581E6C119CC39D94DDBFC5FAA0E178A23CA66202C8C2A72277
pm2 = 0x0F1AE6C77FEE73F3AC9BE1217F50C576C07D7E5FAA0E178A232DD33D09FF2CDE

# (pr1,ps1) = sign_ecdsa(ps_bob,pm1)
# (pr2,ps2) = sign_ecdsa(ps_bob,pm2)
pr1 = 0x22C2921ACF3A393A0BBAF1F68EE7E02F8385FF60CA67C41A1DE3CFF3FDAA1A74
ps1 = 0x1878DBC4684DE3A63A5975325B467CDBA846B24D949322016FE4C8FD2C0862A1

pr2 = 0xB9201D2D40D63EB41D934C9D45280837CA09B03C4E063946CAA06EABEAACB944
ps2 = 0xBA69F449ED11E3677AB37367D99EC3B399A006FE875941F5DA57156A8FE9C8E0

pub = EPoint(pkx, pky)
res = verify_ecdsa(pub, pm1, pr1, ps1)
print("res_pm1 =", res)

res = verify_ecdsa(pub, pm2, pr2, ps2)
print("res_pm2 =", res)
