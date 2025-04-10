// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IPiscineV1Pool} from "../interfaces/IPiscineV1Pool.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

contract PiscineV1Pool is IPiscineV1Pool, ERC20 {
    using Math for uint256;

    address public token0;
    address public token1;
    uint256 public balance0;
    uint256 public balance1;

    constructor(address _token0, address _token1) ERC20("Piscine LP Token", "PLP") {
        token0 = _token0;
        token1 = _token1;
    }

    function addLiquidity(uint256 amount0, uint256 amount1, address liquidityProvider) external {
        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);

        uint256 lpTokensToMint;

        if (balance0 == 0 && balance1 == 0) {
            lpTokensToMint = Math.sqrt(amount0 * amount1);
        } else {
            uint256 poolRatio = balance0 / balance1;
            uint256 inputRatio = amount0 / amount1;
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

        IERC20(token0).transfer(liquidityRemover, amount0);
        IERC20(token1).transfer(liquidityRemover, amount1);

        emit LiquidityRemoved(amount0, amount1, lpTokensAmount);
    }

    function swapTokens(address tokenIn, uint256 amountIn, address swapper) external {
        uint256 amountInWithFee = (amountIn * 997) / 1000;
        uint256 amountOut;

        if (tokenIn == token0) {
            amountOut = (balance1 * amountInWithFee) / (balance0 + amountInWithFee);

            balance0 += amountIn;
            balance1 -= amountOut;

            IERC20(token0).transferFrom(msg.sender, address(this), amountIn);
            IERC20(token1).transfer(swapper, amountOut);
        } else {
            amountOut = (balance0 * amountInWithFee) / (balance1 + amountInWithFee);

            balance1 += amountIn;
            balance0 -= amountOut;

            IERC20(token1).transferFrom(msg.sender, address(this), amountIn);
            IERC20(token0).transfer(swapper, amountOut);
        }

        emit TokensSwapped(amountIn, amountOut);
    }
}
