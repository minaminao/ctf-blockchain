# darkCTF Blockchain Challenges Writeups

We participated in [darkCTF](https://ctf.darkarmy.xyz/). Here are the writeups for the blockchain challenges I solved.

![](https://i.gyazo.com/b62ae261aa1aee156386761d173449c7.png)

## Table of Contents
- [[Cryptography] Duplicacy Within](#[Cryptography]_Duplicacy_Within)
- [[Misc] Secret Of The Contract](#[Misc]_Secret_Of_The_Contract)

## [Cryptography] Duplicacy Within

>Looks like Mr. Jones has found a secret key. Can you retrieve it like him?
>
>Format : darkCTF{hex value of key}
>
>[https://www.blockchain.com/btc/tx/83415dded4757181c6e1c55104e2742a6f8cff05a9a46fbf029ae47b0054d511](https://www.blockchain.com/btc/tx/83415dded4757181c6e1c55104e2742a6f8cff05a9a46fbf029ae47b0054d511)
>
>z1 = `0xc0e2d0a89a348de88fda08211c70d1d7e52ccef2eb9459911bf977d587784c6e`
>
>z2 = `0x17b0f41c8c337ac1e18c98759e83a8cccbc368dd9d89e5f03cb633c265fd0ddc`

I googled the value of z1 and found the following tool.

[daedalus/bitcoin-recover-privkey: Proof of concept of bitcoin private key recovery using weak ECDSA signatures](https://github.com/daedalus/bitcoin-recover-privkey)

The ECDSA random number generation of Bitcoin was incomplete, and the vulnerability existed that allowed for the calculation of a private key. Bitcoin has already fixed this vulnerability by implementing "[RFC 6979: Deterministic Usage of the Digital Signature Algorithm (DSA) and Elliptic Curve Digital Signature Algorithm (ECDSA)](https://tools.ietf.org/html/rfc6979)."

I run the following script.

```py
#!/usr/bin/env python
#
# Proof of concept of bitcoin private key recovery using weak ECDSA signatures
#
# Based on http://www.nilsschneider.net/2013/01/28/recovering-bitcoin-private-keys.html
# Regarding Bitcoin Tx https://blockchain.info/tx/9ec4bc49e828d924af1d1029cacf709431abbde46d59554b62bc270e3b29c4b1.
# As it's said in the previous article you need to poke around into the OP_CHECKSIG function in order to get z1 and z2,
# in other hand for every other parameters you should be able to get them from the Tx itself.
#
# Author Dario Clavijo <dclavijo@protonmail.com> , Jan 2013
# Donations: 1LgWNdNTnzeNgNMzWHtPtXPjxcutJKu74r
#
# This code is licensed under the terms of the GPLv3 license http://gplv3.fsf.org/
#
# Disclaimer: Do not steal other peoples money, that's bad.

# The math
# Q=dP compute public key Q where d is a secret scalar and G the base point
# (x1,y1)=kP where k is random choosen an secret
# r= x1 mod n
# compute k**-1 or inv(k)
# compute z=hash(m)
# s= inv(k)(z + d) mod n
# sig=k(r,s) or (r,-s mod n)
# Key recovery
# d = (sk-z)/r where r is the same 

import hashlib

tx = "83415dded4757181c6e1c55104e2742a6f8cff05a9a46fbf029ae47b0054d511"
p  = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
#r  = 0xd47ce4c025c35ec440bc81d99834a624875161a26bf56ef7fdc0f5d52f843ad1
#s1 = 0x44e1ff2dfd8102cf7a47c21d5c9fd5701610d04953c6836596b4fe9dd2f53e3e
#s2 = 0x9a5f1c75e461d7ceb1cf3cab9013eb2dc85b6d0da8c3c6e27e3a5a5b3faa5bab
z1 = 0xc0e2d0a89a348de88fda08211c70d1d7e52ccef2eb9459911bf977d587784c6e
z2 = 0x17b0f41c8c337ac1e18c98759e83a8cccbc368dd9d89e5f03cb633c265fd0ddc

# r1 and s1 are contained in this ECDSA signature encoded in DER (openssl default).
der_sig1 = "30440220d47ce4c025c35ec440bc81d99834a624875161a26bf56ef7fdc0f5d52f843ad102202f88bf73d0f94a1e917d1a6e65ba15a9dbf52d0999c91f2c2c6bb710e018f7e001"

# the same thing with the above line.
der_sig2 = "30440220d47ce4c025c35ec440bc81d99834a624875161a26bf56ef7fdc0f5d52f843ad102203602aff824a32c19825425704546145d5fbc282ee912089923e824f46867647b01"

params = {'p':p,'sig1':der_sig1,'sig2':der_sig2,'z1':z1,'z2':z2}

def hexify (s, flip=False):
    if flip:
        return s[::-1].encode ('hex')
    else:
        return s.encode ('hex')

def unhexify (s, flip=False):
    if flip:
        return s.decode ('hex')[::-1]
    else:
        return s.decode ('hex')

def inttohexstr(i):
	tmpstr = hex(i)
	hexstr = tmpstr.replace('0x','').replace('L','').zfill(64)
	return hexstr

b58_digits = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

def dhash(s):
    return hashlib.sha256(hashlib.sha256(s).digest()).digest()

def rhash(s):
    h1 = hashlib.new('ripemd160')
    h1.update(hashlib.sha256(s).digest())
    return h1.digest()

def base58_encode(n):
    l = []
    while n > 0:
        n, r = divmod(n, 58)
        l.insert(0,(b58_digits[r]))
    return ''.join(l)

def base58_encode_padded(s):
    res = base58_encode(int('0x' + s.encode('hex'), 16))
    pad = 0
    for c in s:
        if c == chr(0):
            pad += 1
        else:
            break
    return b58_digits[0] * pad + res

def base58_check_encode(s, version=0):
    vs = chr(version) + s
    check = dhash(vs)[:4]
    return base58_encode_padded(vs + check)

def get_der_field(i,binary):
        if (ord(binary[i]) == 02):
                length = binary[i+1]
                end = i + ord(length) + 2
                string = binary[i+2:end]
                return string
        else:
                return None

# Here we decode a DER encoded string separating r and s
def der_decode(hexstring):
        binary = unhexify(hexstring)
        full_length = ord(binary[1])
        if ((full_length + 3) == len(binary)):
                r = get_der_field(2,binary)
                s = get_der_field(len(r)+4,binary)
                return r,s
        else:
                return None

def show_results(privkeys):
		print "Posible Candidates..."
		for privkey in privkeys:
        		hexprivkey = inttohexstr(privkey)
			# print "intPrivkey = %d"  % privkey
			print "darkCTF{%s}" % hexprivkey
			# print "bitcoin Privkey (WIF) = %s" % base58_check_encode(hexprivkey.decode('hex'),version=128)
			# print "bitcoin Privkey (WIF compressed) = %s" % base58_check_encode((hexprivkey + "01").decode('hex'),version=128)


def show_params(params):
	for param in params:
		try:
			print "%s: %s" % (param,inttohexstr(params[param]))
		except:
			print "%s: %s" % (param,params[param])

# By the Fermat's little theorem we can say that:
# a * pow(b,p-2,p) is the same as (a/b mod p) 
# This is needed to avoid floating numbers since we are dealing with prime numbers 
# and beacuse this the python built in division isn't suitable for our needs,
# it returns floating point numbers rounded and we don't want them.
def inverse_mult(a,b,p):
	y =  (a * pow(b,p-2,p))  #(pow(a, b) modulo p) where p should be a prime number
	return y

# Here is the wrock!
def derivate_privkey(p,r,s1,s2,z1,z2):
        privkey = []

        s1ms2 = s1-s2
        s1ps2 = s1+s2
        ms1ms2 = -s1-s2
        ms1ps2 = -s1+s2
        z1ms2 = z1*s2
        z2ms1 = z2*s1
        z1s2mz2s1 = z1ms2-z2ms1
        z1s2pz2s1 = z1ms2+z2ms1
        rs1ms2 = r*s1ms2
        rs1ps2 = r*s1ps2
        rms1ms2 = r*ms1ms2
        rms1ps2 = r*ms1ps2

        privkey.append(inverse_mult(z1s2mz2s1,rs1ms2,p) % p)
        privkey.append(inverse_mult(z1s2mz2s1,rs1ps2,p) % p)
        privkey.append(inverse_mult(z1s2mz2s1,rms1ms2,p) % p)
        privkey.append(inverse_mult(z1s2mz2s1,rms1ps2,p) % p)
        privkey.append(inverse_mult(z1s2pz2s1,rs1ms2,p) % p)
        privkey.append(inverse_mult(z1s2pz2s1,rs1ps2,p) % p)
        privkey.append(inverse_mult(z1s2pz2s1,rms1ms2,p) % p)
        privkey.append(inverse_mult(z1s2pz2s1,rms1ps2,p) % p)

        return privkey

def process_signatures(params):

	p = params['p']
	sig1 = params['sig1']
	sig2 = params['sig2']
	z1 = params['z1']
	z2 = params['z2']

	tmp_r1,tmp_s1 = der_decode(sig1) # Here we extract r and s from the signature encoded in DER.
	tmp_r2,tmp_s2 = der_decode(sig2) # Idem.

	# the key of ECDSA are the integer numbers thats why we convert hexa from to them.
	r1 = int(tmp_r1.encode('hex'),16)
	r2 = int(tmp_r2.encode('hex'),16)
	s1 = int(tmp_s1.encode('hex'),16)
	s2 = int(tmp_s2.encode('hex'),16)

	if (r1 == r2): # If r1 and r2 are equal the two signatures are weak and we can recover the private key.
 		if (s1 != s2): # This: (s1-s2)>0 should be complied in order be able to compute the private key.
			privkey = derivate_privkey(p,r1,s1,s2,z1,z2)
			return privkey
		else:
			raise Exception("Privkey not computable: s1 and s2 are equal.")
	else:
		raise Exception("Privkey not computable: r1 and r2 are not equal.")

def main():
	show_params(params)
	privkey = process_signatures(params)
	if len(privkey)>0:
		show_results(privkey)

if __name__ == "__main__":
    main()
```

The result is as follows.

```sh
$ pyenv local 2.7.18
$ python ProofOfConcept.py 
sig1: 30440220d47ce4c025c35ec440bc81d99834a624875161a26bf56ef7fdc0f5d52f843ad102202f88bf73d0f94a1e917d1a6e65ba15a9dbf52d0999c91f2c2c6bb710e018f7e001
p: fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141
sig2: 30440220d47ce4c025c35ec440bc81d99834a624875161a26bf56ef7fdc0f5d52f843ad102203602aff824a32c19825425704546145d5fbc282ee912089923e824f46867647b01
z1: c0e2d0a89a348de88fda08211c70d1d7e52ccef2eb9459911bf977d587784c6e
z2: 17b0f41c8c337ac1e18c98759e83a8cccbc368dd9d89e5f03cb633c265fd0ddc
Posible Candidates...
darkCTF{791198f7b09c5e63fc5798df41c4090d2265d8066e4d4a917a9d604f17ccf856}
darkCTF{12cba205306996b4fc6d9f6a4b920cebecf0c7b88b2b773af0c3b6a551b16339}
darkCTF{ed345dfacf96694b03926095b46df312cdbe152e241d2900cf0ea7e77e84de08}
darkCTF{86ee67084f63a19c03a86720be3bf6f1984904e040fb55aa4534fe3db86948eb}
darkCTF{4d35700e35810e99564f9aeade7c0687298d0b401f2096845eb6f24285f71115}
darkCTF{a02e8abb6d006105a2325510e70f723f4f0ad8dbba57605a39cfec10d47e695c}
darkCTF{5fd1754492ff9efa5dcdaaef18f08dbf6ba4040af4f13fe18602727bfbb7d7e5}
darkCTF{b2ca8ff1ca7ef166a9b065152183f9779121d1a6902809b7611b6c4a4a3f302c}
```

The flag is `darkCTF{791198f7b09c5e63fc5798df41c4090d2265d8066e4d4a917a9d604f17ccf856}`


## [Misc] Secret Of The Contract
>Ropsten network contains my dark secret. Help us find it. Name of the contract was `0x6e5EA18371748Db7F12A70037d647cDFCf458e45`

I took a look at the transactions in the Ropsten network explorer (Etherscan).

[https://ropsten.etherscan.io/tx/0x55cb76f021a69c1c5bae2830af946d4b11022c94dd91eeb65d520c11a3b5fca3](https://ropsten.etherscan.io/tx/0x55cb76f021a69c1c5bae2830af946d4b11022c94dd91eeb65d520c11a3b5fca3)


![](https://gyazo.com/989f869d73ef309c40f95cd5ebbb408b/thumb/1000)

There are two successful transactions associated with this contract.

[The first](https://ropsten.etherscan.io/tx/0x55cb76f021a69c1c5bae2830af946d4b11022c94dd91eeb65d520c11a3b5fca3) is the contract creation transaction. I looked at the change in state due to this transaction.

![](https://gyazo.com/b9f5c38a4803bb25ee3286e7d169d16f/thumb/1000)

There is a hexadecimal string of alphabets.
 The decoding result:

```sh
$ echo 3337373233343665333533343633333733313330366537640000000000000030 | xxd -r -p
3772346e3534633731306e7d0
$ echo 3772346e3534633731306e7d0 | xxd -r -p
7r4n54c710n}
```
This string appears to be the end of the flag.

I looked at the change in the state due to [the second transaction](https://ropsten.etherscan.io/tx/0x4cfd851b6e64e2f96ba7396c09965987e5a8a0ad8a294afacea25414a1080091).

![](https://gyazo.com/def59cb9970d78a44836a660a53ff893/thumb/1000)

The decoding result:

```sh
$ echo 486d6d2d36343631373236423433353434363742333337343638333337323333 | xxd -r -p
Hmm-6461726B4354467B337468337233⏎
$ echo 6461726B4354467B337468337233 | xxd -r -p
darkCTF{3th3r3

$ echo 3735364435463335333733303732333436373333354600000000000000000000 | xxd -r -p
756D5F353730723467335F
$ echo 756D5F353730723467335F | xxd -r -p
um_570r4g3_
```

I joined together all the pieces and got the flag: `darkCTF{3th3r3um_570r4g3_7r4n54c710n}`