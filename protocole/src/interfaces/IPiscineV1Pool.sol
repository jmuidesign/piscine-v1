// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IPiscineV1Pool {
    error InvalidRatio();

    function addLiquidity(uint256 amount0, uint256 amount1, address liquidityProvider) external;
}
