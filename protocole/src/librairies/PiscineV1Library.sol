// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {PiscineV1Pool} from "../contracts/PiscineV1Pool.sol";
import {Create2} from "openzeppelin-contracts/contracts/utils/Create2.sol";

library PiscineV1Library {
    function _sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function _sortTokensAndAmounts(address tokenA, address tokenB, uint256 amountA, uint256 amountB)
        internal
        pure
        returns (address, address, uint256, uint256)
    {
        return tokenA < tokenB ? (tokenA, tokenB, amountA, amountB) : (tokenB, tokenA, amountB, amountA);
    }

    function _getPoolAddress(address tokenA, address tokenB, address exchange) internal pure returns (address) {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);

        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        bytes memory constructorArgs = abi.encode(token0, token1);
        bytes32 bytecodeHash = keccak256(abi.encodePacked(type(PiscineV1Pool).creationCode, constructorArgs));
        address poolAddress = Create2.computeAddress(salt, bytecodeHash, exchange);

        return poolAddress;
    }
}
