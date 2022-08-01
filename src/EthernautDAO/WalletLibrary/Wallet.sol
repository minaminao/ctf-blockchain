// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * A lightweight multisig wallet contract
 * Calls will be delegated to the wallet library contract
 * Owners can:
 * - Submit a transaction
 * - Approve and revoke approval of pending transactions
 * - Anyone can execute a transaction after enough owners approved it
 */
contract Wallet {
    address public walletLibrary;
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    constructor(
        address _walletLibrary,
        address[] memory _owners,
        uint256 _numConfirmationsRequired
    ) {
        walletLibrary = _walletLibrary;

        (bool success,) = _walletLibrary.delegatecall(
            abi.encodeWithSignature(
                "initWallet(address[],uint256)", _owners, _numConfirmationsRequired
            )
        );

        require(success, "initWallet failed");
    }

    receive() external payable {}

    fallback() external payable {
        _delegate(walletLibrary);
    }

    function _delegate(address _imp) internal virtual {
        assembly {
            // calldatacopy(t, f, s)
            // copy s bytes from calldata at position f to mem at position t
            calldatacopy(0, 0, calldatasize())

            // delegatecall(g, a, in, insize, out, outsize)
            // - call contract at address a
            // - with input mem[in…(in+insize))
            // - providing g gas
            // - and output area mem[out…(out+outsize))
            // - returning 0 on error and 1 on success
            let result := delegatecall(gas(), _imp, 0, calldatasize(), 0, 0)

            // returndatacopy(t, f, s)
            // copy s bytes from returndata at position f to mem at position t
            returndatacopy(0, 0, returndatasize())

            switch result
                case 0 { revert(0, returndatasize()) }
                default { return(0, returndatasize()) }
        }
    }
}
