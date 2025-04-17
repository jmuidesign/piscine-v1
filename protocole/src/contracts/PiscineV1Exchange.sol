// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {PiscineV1Pool} from "./PiscineV1Pool.sol";
import {PiscineV1Library} from "../librairies/PiscineV1Library.sol";
import {IPiscineV1Exchange} from "../interfaces/IPiscineV1Exchange.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract PiscineV1Exchange is IPiscineV1Exchange {
    using SafeERC20 for IERC20;

    address public constant UniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public immutable owner;
    address[] public pools;
    mapping(address token0 => mapping(address token1 => address pool)) public token0ToToken1ToPool;
    mapping(address token => uint256 forwardFees) public tokenToForwardFees;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    function _checkAddresses(address tokenA, address tokenB) internal pure {
        if (tokenA == tokenB) revert SameToken();
        if (tokenA == address(0) || tokenB == address(0)) revert AddressZero();
    }

    function createPool(address tokenA, address tokenB) public {
        _checkAddresses(tokenA, tokenB);

        (address token0, address token1) = PiscineV1Library._sortTokens(tokenA, tokenB);

        if (token0ToToken1ToPool[token0][token1] != address(0)) revert PoolAlreadyExists();

        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        address poolAddress = address(new PiscineV1Pool{salt: salt}(token0, token1));

        pools.push(poolAddress);
        token0ToToken1ToPool[token0][token1] = poolAddress;

        emit PoolCreated(poolAddress, token0, token1);
    }

    function addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external {
        _checkAddresses(tokenA, tokenB);
        if (amountA == 0 || amountB == 0) revert AmountZero();

        (address token0, address token1, uint256 amount0, uint256 amount1) =
            PiscineV1Library._sortTokensAndAmounts(tokenA, tokenB, amountA, amountB);
        address computedPoolAddress = PiscineV1Library._getPoolAddress(tokenA, tokenB, address(this));

        if (token0ToToken1ToPool[token0][token1] == address(0)) createPool(tokenA, tokenB);

        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);

        IERC20(token0).safeIncreaseAllowance(computedPoolAddress, amount0);
        IERC20(token1).safeIncreaseAllowance(computedPoolAddress, amount1);

        PiscineV1Pool(computedPoolAddress).addLiquidity(amount0, amount1, msg.sender);
    }

    function removeLiquidity(address tokenA, address tokenB, uint256 lpTokensAmount) external {
        _checkAddresses(tokenA, tokenB);

        (address token0, address token1) = PiscineV1Library._sortTokens(tokenA, tokenB);
        address computedPoolAddress = PiscineV1Library._getPoolAddress(tokenA, tokenB, address(this));

        if (token0ToToken1ToPool[token0][token1] == address(0)) revert PoolDoesNotExist();

        PiscineV1Pool(computedPoolAddress).removeLiquidity(lpTokensAmount, msg.sender);
    }

    function swapTokens(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut) external {
        _checkAddresses(tokenIn, tokenOut);

        (address token0, address token1) = PiscineV1Library._sortTokens(tokenIn, tokenOut);
        address computedPoolAddress = PiscineV1Library._getPoolAddress(tokenIn, tokenOut, address(this));

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        if (token0ToToken1ToPool[token0][token1] == address(0)) {
            IUniswapV2Router02 router = IUniswapV2Router02(UniswapV2Router);

            address[] memory path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;

            uint256 amountInWithFee = (amountIn * 999) / 1000;

            IERC20(tokenIn).safeIncreaseAllowance(address(router), amountInWithFee);

            tokenToForwardFees[tokenIn] += (amountIn - amountInWithFee);

            router.swapExactTokensForTokens(
                amountInWithFee, minAmountOut, path, msg.sender, block.timestamp + 5 minutes
            )[1];
        } else {
            IERC20(tokenIn).safeIncreaseAllowance(computedPoolAddress, amountIn);

            PiscineV1Pool(computedPoolAddress).swapTokens(tokenIn, amountIn, minAmountOut, msg.sender);
        }
    }

    function withdrawForwardFees(address token, uint256 amount) external onlyOwner {
        tokenToForwardFees[token] -= amount;
        IERC20(token).safeTransfer(owner, amount);

        emit ForwardFeesWithdrawn(token, amount);
    }

    function getPoolsLength() external view returns (uint256 poolsLength) {
        return pools.length;
    }

    function getPoolTokensAndBalances(address poolAddress)
        external
        view
        returns (address token0, address token1, uint256 balance0, uint256 balance1)
    {
        return (
            PiscineV1Pool(poolAddress).token0(),
            PiscineV1Pool(poolAddress).token1(),
            PiscineV1Pool(poolAddress).balance0(),
            PiscineV1Pool(poolAddress).balance1()
        );
    }
}
