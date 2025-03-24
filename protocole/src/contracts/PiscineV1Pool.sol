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
        IERC20(token0).transferFrom(liquidityProvider, address(this), amount0);
        IERC20(token1).transferFrom(liquidityProvider, address(this), amount1);

        uint256 precision = 1 ** 18;
        uint256 lpTokensToMint;

        if (balance0 == 0 && balance1 == 0) {
            lpTokensToMint = Math.sqrt((amount0 * precision) * (amount1 * precision)) / precision;
        } else {
            uint256 poolRatio = (balance0 * precision) / (balance1 * precision);
            uint256 inputRatio = (amount0 * precision) / (amount1 * precision);
            uint256 margin = poolRatio / 100;

            if (inputRatio > poolRatio + margin || inputRatio < poolRatio - margin) revert InvalidRatio();

            lpTokensToMint = Math.min(
                (amount0 * precision * totalSupply()) / (balance0 * precision),
                (amount1 * precision * totalSupply()) / (balance1 * precision)
            ) / precision;
        }

        _mint(liquidityProvider, lpTokensToMint);

        balance0 += amount0;
        balance1 += amount1;
    }
}
