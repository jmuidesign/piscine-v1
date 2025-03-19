// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IPiscineV1Exchange} from "../interfaces/IPiscineV1Exchange.sol";
import {PiscineV1Pool} from "./PiscineV1Pool.sol";
import {PiscineV1Library} from "../librairies/PiscineV1Library.sol";

contract PiscineV1Exchange is IPiscineV1Exchange {
    address public owner;
    address[] public pools;
    mapping(address token0 => mapping(address token1 => address pool)) public token0ToToken1ToPool;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    function createPool(address tokenA, address tokenB) external returns (address pool) {
        if (tokenA == tokenB) revert SameToken();
        if (tokenA == address(0) || tokenB == address(0)) revert AddressZero();

        (address token0, address token1) = PiscineV1Library.sortTokens(tokenA, tokenB);

        if (token0ToToken1ToPool[token0][token1] != address(0)) revert PoolAlreadyExists();

        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        address poolAddress = address(new PiscineV1Pool{salt: salt}(token0, token1));

        pools.push(poolAddress);
        token0ToToken1ToPool[token0][token1] = poolAddress;

        emit PoolCreated(poolAddress, token0, token1);

        return poolAddress;
    }
}
