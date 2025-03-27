// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {BaseTest} from "./Base.t.sol";
import {PiscineV1Exchange} from "../src/contracts/PiscineV1Exchange.sol";
import {IPiscineV1Exchange} from "../src/interfaces/IPiscineV1Exchange.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

contract SwapTokensTest is BaseTest {
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    uint256 amountOut;

    function setUp() public override {
        super.setUp();
        setupLiquidityAndBalances();

        tokenIn = tokenB;
        tokenOut = tokenA;
        amountIn = 1_500_000;
    }

    function _calculateAmountOut() private {
        uint256 amountInWithFee = (amountIn * 997) / 1000;

        if (tokenIn == token0) {
            amountOut = (balance1 * amountInWithFee) / (balance0 + amountInWithFee);
        } else {
            amountOut = (balance0 * amountInWithFee) / (balance1 + amountInWithFee);
        }
    }

    function test_swap_tokens_succeedsWhenPoolDoesNotExistAndForwardSwapToUniswapV2() public {
        string memory rpcUrl = vm.rpcUrl("mainnet");
        vm.createSelectFork(rpcUrl, 22193947);

        PiscineV1Exchange exchange = new PiscineV1Exchange();

        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

        deal(usdc, address(this), amountIn);
        IERC20(usdc).approve(address(exchange), amountIn);

        uint256 balanceUsdc = IERC20(usdc).balanceOf(address(this));
        uint256 balanceDai = IERC20(dai).balanceOf(address(this));

        uint256 _amountOut = exchange.swapTokens(usdc, dai, amountIn);

        assertGt(_amountOut, 0, "amountOut is not correct");
        assertLt(IERC20(usdc).balanceOf(address(this)), balanceUsdc, "balanceUsdc is not correct");
        assertGt(IERC20(dai).balanceOf(address(this)), balanceDai, "balanceDai is not correct");
    }

    function test_swap_tokens_succeedsWhenPoolExistsAndTokenInIsToken0() public {
        exchange.swapTokens(tokenIn, tokenOut, amountIn);

        _calculateAmountOut();

        assertEq(pool.balance0(), balance0 + amountIn, "balance0 is not correct");
        assertEq(pool.balance1(), balance1 - amountOut, "balance1 is not correct");
        assertEq(tokenAMock.balanceOf(address(this)), balanceA + amountOut, "tokenA balance is not correct");
        assertEq(tokenBMock.balanceOf(address(this)), balanceB - amountIn, "tokenB balance is not correct");
    }

    function test_swap_tokens_succeedsWhenPoolExistsAndTokenInIsToken1() public {
        tokenIn = tokenA;
        tokenOut = tokenB;

        exchange.swapTokens(tokenIn, tokenOut, amountIn);

        _calculateAmountOut();

        assertEq(pool.balance0(), balance0 - amountOut, "balance0 is not correct");
        assertEq(pool.balance1(), balance1 + amountIn, "balance1 is not correct");
        assertEq(tokenAMock.balanceOf(address(this)), balanceA - amountIn, "tokenA balance is not correct");
        assertEq(tokenBMock.balanceOf(address(this)), balanceB + amountOut, "tokenB balance is not correct");
    }

    function test_swap_tokens_succeedsWhenPoolExistsWithMultipleSwapers() public {
        vm.startPrank(user1);
        exchange.swapTokens(tokenIn, tokenOut, amountIn);

        _calculateAmountOut();

        assertEq(pool.balance0(), balance0 + amountIn, "balance0 is not correct");
        assertEq(pool.balance1(), balance1 - amountOut, "balance1 is not correct");
        assertEq(tokenAMock.balanceOf(user1), balanceAUser1 + amountOut, "tokenA balance is not correct");
        assertEq(tokenBMock.balanceOf(user1), balanceBUser1 - amountIn, "tokenB balance is not correct");
        vm.stopPrank();

        balance0 = pool.balance0();
        balance1 = pool.balance1();

        vm.startPrank(user2);
        exchange.swapTokens(tokenIn, tokenOut, amountIn);

        _calculateAmountOut();

        assertEq(pool.balance0(), balance0 + amountIn, "balance0 is not correct");
        assertEq(pool.balance1(), balance1 - amountOut, "balance1 is not correct");
        assertEq(tokenAMock.balanceOf(user2), balanceAUser2 + amountOut, "tokenA balance is not correct");
        assertEq(tokenBMock.balanceOf(user2), balanceBUser2 - amountIn, "tokenB balance is not correct");
        vm.stopPrank();
    }

    function test_swap_tokens_emitsTokensSwapped() public {
        _calculateAmountOut();

        vm.expectEmit();
        emit IPiscineV1Exchange.TokensSwapped(tokenIn, tokenOut, amountIn, amountOut);

        exchange.swapTokens(tokenIn, tokenOut, amountIn);
    }

    function test_swap_tokens_failsIfSameToken() public {
        vm.expectRevert(IPiscineV1Exchange.SameToken.selector);
        exchange.swapTokens(tokenIn, tokenIn, amountIn);
    }

    function test_swap_tokens_failsIfAddressZero() public {
        vm.expectRevert(IPiscineV1Exchange.AddressZero.selector);
        exchange.swapTokens(address(0), tokenOut, amountIn);
    }

    function test_swap_tokens_failsIfAmountZero() public {
        vm.expectRevert(IPiscineV1Exchange.AmountZero.selector);
        exchange.swapTokens(tokenIn, tokenOut, 0);
    }

    function test_fuzz_swapTokens(uint256 _amountIn) public {
        vm.assume(_amountIn > 0);
        vm.assume(_amountIn <= type(uint128).max);

        tokenBMock.mint(address(this), _amountIn);
        tokenBMock.approve(computedPoolAddress, _amountIn);

        amountIn = _amountIn;
        balance0 = pool.balance0();
        balance1 = pool.balance1();
        balanceA = tokenAMock.balanceOf(address(this));
        balanceB = tokenBMock.balanceOf(address(this));

        exchange.swapTokens(tokenIn, tokenOut, _amountIn);

        _calculateAmountOut();

        assertEq(pool.balance0(), balance0 + _amountIn, "balance0 is not correct");
        assertEq(pool.balance1(), balance1 - amountOut, "balance1 is not correct");
        assertEq(tokenAMock.balanceOf(address(this)), balanceA + amountOut, "tokenA balance is not correct");
        assertEq(tokenBMock.balanceOf(address(this)), balanceB - _amountIn, "tokenB balance is not correct");
    }
}
