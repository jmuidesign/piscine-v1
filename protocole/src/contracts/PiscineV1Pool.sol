// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

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

    function addLiquidity(uint256 amount0, uint256 amount1, address liquidityProvider) external {
        if (amount0 == 0 || amount1 == 0) revert AmountZero();

        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);

        uint256 lpTokensToMint;

        if (balance0 == 0 && balance1 == 0) {
            lpTokensToMint = Math.sqrt(amount0 * amount1);
        } else {
            uint256 poolRatio = (balance0 * 10 ** 18) / balance1;
            uint256 inputRatio = (amount0 * 10 ** 18) / amount1;
            uint256 margin = poolRatio / 100;

            if (inputRatio > poolRatio + margin || inputRatio < poolRatio - margin) revert InvalidRatio();

            lpTokensToMint = Math.min(amount0 * totalSupply() / balance0, amount1 * totalSupply() / balance1);
        }

        _mint(liquidityProvider, lpTokensToMint);

        balance0 += amount0;
        balance1 += amount1;

        emit LiquidityAdded(amount0, amount1, lpTokensToMint);
    }

    function removeLiquidity(uint256 lpTokensAmount, address liquidityRemover) external {
        uint256 amount0 = balance0 * lpTokensAmount / totalSupply();
        uint256 amount1 = balance1 * lpTokensAmount / totalSupply();

        _burn(liquidityRemover, lpTokensAmount);

        balance0 -= amount0;
        balance1 -= amount1;

        IERC20(token0).safeTransfer(liquidityRemover, amount0);
        IERC20(token1).safeTransfer(liquidityRemover, amount1);

        emit LiquidityRemoved(amount0, amount1, lpTokensAmount);
    }

    function swapTokens(address tokenIn, uint256 amountIn, uint256 minAmountOut, address swapper) external {
        uint256 amountInWithFee = (amountIn * 997) / 1000;
        uint256 amountOut;

        if (tokenIn == token0) {
            IERC20(token0).safeTransferFrom(msg.sender, address(this), amountIn);

            amountOut = (balance1 * amountInWithFee) / (balance0 + amountInWithFee);

            if (amountOut < minAmountOut) revert InsufficientOutputAmount();

            balance0 += amountIn;
            balance1 -= amountOut;

            IERC20(token1).safeTransfer(swapper, amountOut);
        } else {
            IERC20(token1).safeTransferFrom(msg.sender, address(this), amountIn);

            amountOut = (balance0 * amountInWithFee) / (balance1 + amountInWithFee);

            if (amountOut < minAmountOut) revert InsufficientOutputAmount();

            balance1 += amountIn;
            balance0 -= amountOut;

            IERC20(token0).safeTransfer(swapper, amountOut);
        }

        emit TokensSwapped(amountIn, amountOut);
    }
}
