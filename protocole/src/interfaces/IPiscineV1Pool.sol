// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IPiscineV1Pool {
    event LiquidityAdded(uint256 amount0, uint256 amount1, uint256 lpTokensMinted);
    event LiquidityRemoved(uint256 amount0, uint256 amount1, uint256 lpTokensBurned);
    event TokensSwapped(uint256 amountIn, uint256 amountOut);

    error AmountZero();
    error InvalidRatio();
    error InsufficientLiquidity();
    error InsufficientOutputAmount();

    function addLiquidity(uint256 amount0, uint256 amount1, address liquidityProvider) external;
    function removeLiquidity(uint256 lpTokensAmount, address liquidityRemover) external;
    function swapTokens(address tokenIn, uint256 amountIn, uint256 minAmountOut, address swapper) external;
}
