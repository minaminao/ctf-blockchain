// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract ConfidentialHash {
    string public firstUser = "ALICE";
    uint256 public alice_age = 24;
    bytes32 private ALICE_PRIVATE_KEY; //Super Secret Key
    bytes32 public ALICE_DATA = "QWxpY2UK";
    bytes32 private aliceHash = hash(ALICE_PRIVATE_KEY, ALICE_DATA);

    string public secondUser = "BOB";
    uint256 public bob_age = 21;
    bytes32 private BOB_PRIVATE_KEY; // Super Secret Key
    bytes32 public BOB_DATA = "Qm9iCg";
    bytes32 private bobHash = hash(BOB_PRIVATE_KEY, BOB_DATA);

    constructor() {}

    function hash(bytes32 key1, bytes32 key2) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(key1, key2));
    }

    function checkthehash(bytes32 _hash) public view returns (bool) {
        require(_hash == hash(aliceHash, bobHash));
        return true;
    }
}
