// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IPiscineV1Pool {
    error InvalidRatio();
    error InsufficientLiquidity();

    function addLiquidity(uint256 amount0, uint256 amount1, address liquidityProvider) external;
    function removeLiquidity(uint256 lpTokensAmount, address liquidityRemover)
        external
        returns (uint256 amount0, uint256 amount1);
    function swapTokens(address tokenIn, uint256 amountIn, address swapper) external returns (uint256 amountOut);
}
