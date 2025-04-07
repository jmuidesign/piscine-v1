// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {PiscineV1Pool} from "./PiscineV1Pool.sol";
import {PiscineV1Library} from "../librairies/PiscineV1Library.sol";
import {IPiscineV1Exchange} from "../interfaces/IPiscineV1Exchange.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract PiscineV1Exchange is IPiscineV1Exchange {
    address public owner;
    address[] public pools;
    mapping(address token0 => mapping(address token1 => address pool)) public token0ToToken1ToPool;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    function createPool(address tokenA, address tokenB) public returns (address pool) {
        if (tokenA == tokenB) revert SameToken();
        if (tokenA == address(0) || tokenB == address(0)) revert AddressZero();

        (address token0, address token1) = PiscineV1Library.sortTokens(tokenA, tokenB);

        if (token0ToToken1ToPool[token0][token1] != address(0)) revert PoolAlreadyExists();

        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        address poolAddress = address(new PiscineV1Pool{salt: salt}(token0, token1));

        pools.push(poolAddress);
        token0ToToken1ToPool[token0][token1] = poolAddress;

        emit PoolCreated(poolAddress, token0, token1);

        return poolAddress;
    }

    function addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external {
        if (tokenA == tokenB) revert SameToken();
        if (tokenA == address(0) || tokenB == address(0)) revert AddressZero();
        if (amountA == 0 || amountB == 0) revert AmountZero();

        (address token0, address token1, uint256 amount0, uint256 amount1) =
            PiscineV1Library.sortTokensAndAmounts(tokenA, tokenB, amountA, amountB);
        address computedPoolAddress = PiscineV1Library.getPoolAddress(tokenA, tokenB, address(this));

        if (token0ToToken1ToPool[token0][token1] == address(0)) {
            address newPool = createPool(tokenA, tokenB);
            PiscineV1Pool(newPool).addLiquidity(amount0, amount1, msg.sender);
        } else {
            PiscineV1Pool(computedPoolAddress).addLiquidity(amount0, amount1, msg.sender);
        }

        emit LiquidityAdded(token0, token1, amount0, amount1);
    }

    function removeLiquidity(address tokenA, address tokenB, uint256 lpTokensAmount) external {
        if (tokenA == tokenB) revert SameToken();
        if (tokenA == address(0) || tokenB == address(0)) revert AddressZero();
        if (lpTokensAmount == 0) revert AmountZero();

        uint256 amount0;
        uint256 amount1;

        (address token0, address token1) = PiscineV1Library.sortTokens(tokenA, tokenB);
        address computedPoolAddress = PiscineV1Library.getPoolAddress(tokenA, tokenB, address(this));

        if (token0ToToken1ToPool[token0][token1] == address(0)) {
            revert PoolDoesNotExist();
        } else {
            (amount0, amount1) = PiscineV1Pool(computedPoolAddress).removeLiquidity(lpTokensAmount, msg.sender);
        }

        emit LiquidityRemoved(token0, token1, amount0, amount1);
    }

    function swapTokens(address tokenIn, address tokenOut, uint256 amountIn) external {
        if (tokenIn == tokenOut) revert SameToken();
        if (tokenIn == address(0) || tokenOut == address(0)) revert AddressZero();
        if (amountIn == 0) revert AmountZero();

        uint256 amountOut;

        (address token0, address token1) = PiscineV1Library.sortTokens(tokenIn, tokenOut);
        address computedPoolAddress = PiscineV1Library.getPoolAddress(tokenIn, tokenOut, address(this));

        if (token0ToToken1ToPool[token0][token1] == address(0)) {
            address pair = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).getPair(tokenIn, tokenOut);
            if (pair == address(0)) revert UniswapPoolDoesNotExist();

            IUniswapV2Router02 router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

            address[] memory path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;

            IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
            IERC20(tokenIn).approve(address(router), amountIn);

            amountOut = router.swapExactTokensForTokens(amountIn, 0, path, msg.sender, block.timestamp + 5 minutes)[1];
        } else {
            amountOut = PiscineV1Pool(computedPoolAddress).swapTokens(tokenIn, amountIn, msg.sender);
        }

        emit TokensSwapped(tokenIn, tokenOut, amountIn, amountOut);
    }
}
