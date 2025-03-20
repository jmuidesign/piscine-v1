// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IPiscineV1Exchange {
    error OnlyOwner();
    error SameToken();
    error AddressZero();
    error AmountZero();
    error PoolAlreadyExists();

    event PoolCreated(address pool, address token0, address token1);
    event LiquidityAdded(address token0, address token1, uint256 amount0, uint256 amount1);

    function createPool(address tokenA, address tokenB) external returns (address pool);
    function addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external;
}
