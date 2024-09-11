// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {MessageHashUtils} from "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

library PermitLibrary {
    function getDigest(
        address tokenAddress,
        address ownerAddress,
        address spenderAddress,
        uint256 value,
        uint256 deadline
    ) internal view returns (bytes32) {
        IERC20Permit token = IERC20Permit(tokenAddress);

        bytes32 _PERMIT_TYPEHASH =
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
        uint256 nonce = token.nonces(ownerAddress);
        bytes32 structHash =
            keccak256(abi.encode(_PERMIT_TYPEHASH, ownerAddress, spenderAddress, value, nonce, deadline));

        bytes32 DOMAIN_SEPARATOR = token.DOMAIN_SEPARATOR();
        return MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, structHash);
    }
}
