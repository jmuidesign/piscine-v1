// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {PiscineV1Pool} from "../contracts/PiscineV1Pool.sol";
import "openzeppelin-contracts/contracts/utils/Create2.sol";

library PiscineV1Library {
    function sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function getPoolAddress(address tokenA, address tokenB, address exchange) internal pure returns (address) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);

        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        bytes memory constructorArgs = abi.encode(token0, token1);
        bytes32 bytecodeHash = keccak256(abi.encodePacked(type(PiscineV1Pool).creationCode, constructorArgs));
        address poolAddress = Create2.computeAddress(salt, bytecodeHash, exchange);

        return poolAddress;
    }
}
