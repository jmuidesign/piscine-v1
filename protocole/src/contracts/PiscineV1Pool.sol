// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IPiscineV1Pool} from "../interfaces/IPiscineV1Pool.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract PiscineV1Pool is IPiscineV1Pool, ERC20 {
    using Math for uint256;
    using SafeERC20 for IERC20;

    address public immutable token0;
    address public immutable token1;
    uint256 public balance0;
    uint256 public balance1;

    constructor(address _token0, address _token1) ERC20("Piscine LP Token", "PLP") {
        token0 = _token0;
        token1 = _token1;
    }

    function addLiquidity(address liquidityProvider) external {
        uint256 _balance0 = balance0;
        uint256 _balance1 = balance1;

        uint256 amount0 = IERC20(token0).balanceOf(address(this)) - _balance0;
        uint256 amount1 = IERC20(token1).balanceOf(address(this)) - _balance1;

        uint256 lpTokensToMint;

        if (_balance0 == 0) {
            lpTokensToMint = Math.sqrt(amount0 * amount1);
        } else {
            uint256 poolRatio = (_balance0 * 10 ** 18) / _balance1;
            uint256 inputRatio = (amount0 * 10 ** 18) / amount1;
            uint256 margin = poolRatio / 100;

            if (inputRatio > poolRatio + margin || inputRatio < poolRatio - margin) revert InvalidRatio();

            lpTokensToMint = Math.min(amount0 * totalSupply() / _balance0, amount1 * totalSupply() / _balance1);
        }

        _mint(liquidityProvider, lpTokensToMint);

        balance0 += amount0;
        balance1 += amount1;

        emit LiquidityAdded(liquidityProvider, amount0, amount1, lpTokensToMint);
    }

    function removeLiquidity(uint256 lpTokensAmount, address liquidityRemover) external {
        uint256 amount0 = balance0 * lpTokensAmount / totalSupply();
        uint256 amount1 = balance1 * lpTokensAmount / totalSupply();

        _burn(liquidityRemover, lpTokensAmount);

        balance0 -= amount0;
        balance1 -= amount1;

        IERC20(token0).safeTransfer(liquidityRemover, amount0);
        IERC20(token1).safeTransfer(liquidityRemover, amount1);

        emit LiquidityRemoved(liquidityRemover, amount0, amount1, lpTokensAmount);
    }

    function swapTokens(address tokenIn, uint256 minAmountOut, address swapper) external {
        (address tokenOut, uint256 balanceIn, uint256 balanceOut) =
            tokenIn == token0 ? (token1, balance0, balance1) : (token0, balance1, balance0);

        uint256 amountIn = IERC20(tokenIn).balanceOf(address(this)) - balanceIn;
        uint256 amountInWithFee = (amountIn * 997) / 1000;
        uint256 amountOut = (balanceOut * amountInWithFee) / (balanceIn + amountInWithFee);

        if (amountOut < minAmountOut) revert InsufficientOutputAmount();

        if (tokenIn == token0) {
            balance0 += amountIn;
            balance1 -= amountOut;
        } else {
            balance1 += amountIn;
            balance0 -= amountOut;
        }

        IERC20(tokenOut).safeTransfer(swapper, amountOut);

        emit TokensSwapped(swapper, amountIn, amountOut);
    }
}
