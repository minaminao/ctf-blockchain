// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract RareNFT is ERC721 {
    bool _lock = false;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function mint(address to, uint256 tokenId) public {
        require(!_lock, "Locked");
        _mint(to, tokenId);
    }

    function lock() public {
        _lock = true;
    }
}

contract NMToken is ERC20 {
    bool _lock = false;
    address admin;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        admin = msg.sender;
    }

    function mint(address to, uint256 amount) public {
        // shh - admin function
        require(msg.sender == admin, "admin only");
        _mint(to, amount);
    }

    function move(address from, address to, uint256 amount) public {
        // shh - admin function
        require(msg.sender == admin, "admin only");
        _transfer(from, to, amount);
    }

    function lock() public {
        _lock = true;
    }
}

contract NFTMarketplace {
    error TransferFromFailed();

    event GetFlag(bool success);

    bool public initialized;
    bool public tested;
    RareNFT public rareNFT;
    NMToken public nmToken;
    Order[] public orders;

    struct Order {
        address maker;
        address token;
        uint256 tokenId;
        uint256 price;
    }

    constructor() {}

    function initialize() public {
        require(!initialized, "Initialized");
        initialized = true;

        nmToken = new NMToken{salt: keccak256("NMToken")}("NM Token", "NMToken");
        nmToken.mint(address(this), 1000000);
        nmToken.mint(msg.sender, 100);
        nmToken.lock();
        nmToken.approve(address(this), type(uint256).max);

        rareNFT = new RareNFT{salt: keccak256("rareNFT")}("Rare NFT", "rareNFT");
        rareNFT.mint(address(this), 1);
        rareNFT.mint(address(this), 2);
        rareNFT.mint(address(this), 3);
        rareNFT.mint(msg.sender, 4);
        rareNFT.lock();

        // NFTMarketplace(this).createOrder(address(rareNFT), 1, 10000000000000);  // I think it's super rare.
        NFTMarketplace(this).createOrder(address(rareNFT), 2, 100);
        NFTMarketplace(this).createOrder(address(rareNFT), 3, 100000);
    }

    function getTokenVersion() public pure returns (bytes memory) {
        return type(NMToken).creationCode;
    }

    function getNFTVersion() public pure returns (bytes memory) {
        return type(RareNFT).creationCode;
    }

    function createOrder(address token, uint256 tokenId, uint256 price) public returns (uint256) {
        orders.push(Order(msg.sender, token, tokenId, price));
        _safeTransferFrom(token, msg.sender, address(this), tokenId);
        return orders.length - 1;
    }

    function cancelOrder(uint256 orderId) public {
        require(orderId < orders.length, "Invalid orderId");
        Order memory order = orders[orderId];
        require(order.maker == msg.sender, "Invalid maker");
        _deleteOrder(orderId);
        _safeTransferFrom(order.token, address(this), order.maker, order.tokenId);
    }

    function fulfill(uint256 orderId) public {
        require(orderId < orders.length, "Invalid orderId");
        Order memory order = orders[orderId];
        require(order.maker != address(0), "Invalid maker");
        _deleteOrder(orderId);
        nmToken.move(msg.sender, order.maker, order.price);
        _safeTransferFrom(order.token, address(this), msg.sender, order.tokenId);
    }

    function fulfillTest(address token, uint256 tokenId, uint256 price) public {
        require(!tested, "Tested");
        tested = true;
        uint256 orderId = NFTMarketplace(this).createOrder(token, tokenId, price);
        fulfill(orderId);
    }

    function verify() public {
        require(nmToken.balanceOf(address(this)) == 0, "failed");
        require(nmToken.balanceOf(msg.sender) > 1000000, "failed");
        require(
            rareNFT.ownerOf(1) == msg.sender && rareNFT.ownerOf(2) == msg.sender && rareNFT.ownerOf(3) == msg.sender
                && rareNFT.ownerOf(4) == msg.sender
        );
        emit GetFlag(true);
    }

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

    function _deleteOrder(uint256 orderId) internal {
        orders[orderId] = orders[orders.length - 1];
        orders.pop();
    }
}

// // User Contract Example
// interface Callee {
//     function initialize() external;
//     function verify() external;
// }
//
// contract UserContract {
//     function execute(address target) public {
//         Callee callee = Callee(target);
//         callee.initialize();
//         callee.verify();
//     }
// }
