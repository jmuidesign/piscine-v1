// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface IPiscineV1Exchange {
    event PoolCreated(address pool, address token0, address token1);
    event ForwardFeesWithdrawn(address token, uint256 amount);

    error OnlyOwner();
    error SameToken();
    error AddressZero();
    error AmountZero();
    error PoolAlreadyExists();
    error PoolDoesNotExist();

    function createPool(address tokenA, address tokenB) external;
    function addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external;
    function removeLiquidity(address tokenA, address tokenB, uint256 lpTokensAmount) external;
    function swapTokens(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut) external;
    function withdrawForwardFees(address token, uint256 amount) external;
}
