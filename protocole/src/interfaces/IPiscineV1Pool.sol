// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPiscineV1Pool {
    event LiquidityAdded(address indexed liquidityProvider, uint256 amount0, uint256 amount1, uint256 lpTokensMinted);
    event LiquidityRemoved(address indexed liquidityRemover, uint256 amount0, uint256 amount1, uint256 lpTokensBurned);
    event TokensSwapped(address indexed swapper, uint256 amountIn, uint256 amountOut);

    error AmountZero();
    error InvalidRatio();
    error InsufficientLiquidity();
    error InsufficientOutputAmount();

    function addLiquidity(address liquidityProvider) external;
    function removeLiquidity(uint256 lpTokensAmount, address liquidityRemover) external;
    function swapTokens(address tokenIn, uint256 minAmountOut, address swapper) external;
}
