// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {BaseTest} from "./helpers/Base.sol";
import {IPiscineV1Exchange} from "../src/interfaces/IPiscineV1Exchange.sol";
import {IPiscineV1Pool} from "../src/interfaces/IPiscineV1Pool.sol";
import {PiscineV1Library} from "../src/librairies/PiscineV1Library.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

contract AddLiquidityTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_addLiquidity_succeedsWhenPoolDoesNotExist() public {
        uint256 expectedLPTokensToMint = Math.sqrt(amount0 * amount1);

        exchange.addLiquidity(tokenA, tokenB, amountA, amountB);

        assertEq(tokenAMock.balanceOf(computedPoolAddress), amountA, "Tokens A are not transferred");
        assertEq(tokenBMock.balanceOf(computedPoolAddress), amountB, "Tokens B are not transferred");
        assertEq(pool.balance0(), amount0, "Balance 0 is not correct");
        assertEq(pool.balance1(), amount1, "Balance 1 is not correct");
        assertEq(pool.balanceOf(address(this)), expectedLPTokensToMint, "LP tokens are not minted");
    }

    function test_addLiquidity_succeedsWhenPoolExistsWithoutLiquidity() public {
        uint256 expectedLPTokensToMint = Math.sqrt(amount0 * amount1);

        exchange.createPool(tokenA, tokenB);
        exchange.addLiquidity(tokenA, tokenB, amountA, amountB);

        assertEq(tokenAMock.balanceOf(computedPoolAddress), amountA, "Tokens A are not transferred");
        assertEq(tokenBMock.balanceOf(computedPoolAddress), amountB, "Tokens B are not transferred");
        assertEq(pool.balance0(), amount0, "Balance 0 is not correct");
        assertEq(pool.balance1(), amount1, "Balance 1 is not correct");
        assertEq(pool.balanceOf(address(this)), expectedLPTokensToMint, "LP tokens are not minted");
    }

    function test_addLiquidity_succeedsWhenPoolExistsWithLiquidity() public {
        exchange.addLiquidity(tokenA, tokenB, amountA, amountB);

        uint256 totalSupplyAfterFirstAdd = pool.totalSupply();
        uint256 expectedLPTokensToMint =
            Math.min(amount0 * pool.totalSupply() / pool.balance0(), amount1 * pool.totalSupply() / pool.balance1());

        exchange.addLiquidity(tokenA, tokenB, amountA, amountB);

        assertEq(tokenAMock.balanceOf(computedPoolAddress), amountA * 2, "Tokens A are not transferred");
        assertEq(tokenBMock.balanceOf(computedPoolAddress), amountB * 2, "Tokens B are not transferred");
        assertEq(pool.balance0(), amount0 * 2, "Balance 0 is not correct");
        assertEq(pool.balance1(), amount1 * 2, "Balance 1 is not correct");
        assertEq(
            pool.balanceOf(address(this)), totalSupplyAfterFirstAdd + expectedLPTokensToMint, "LP tokens are not minted"
        );
    }

    function test_addLiquidity_succeedsWhithMultipleLiquidityProviders() public {
        uint256 expectedLPTokensToMintForUser1 = Math.sqrt(amount0 * amount1);

        vm.startPrank(user1);
        exchange.addLiquidity(tokenA, tokenB, amountA, amountB);
        vm.stopPrank();

        uint256 expectedLPTokensToMintForUser2 =
            Math.min(amount0 * pool.totalSupply() / pool.balance0(), amount1 * pool.totalSupply() / pool.balance1());

        vm.startPrank(user2);
        exchange.addLiquidity(tokenA, tokenB, amountA, amountB);
        vm.stopPrank();

        assertEq(tokenAMock.balanceOf(computedPoolAddress), amountA * 2, "Tokens A are not transferred");
        assertEq(tokenBMock.balanceOf(computedPoolAddress), amountB * 2, "Tokens B are not transferred");
        assertEq(pool.balance0(), amount0 * 2, "Balance 0 is not correct");
        assertEq(pool.balance1(), amount1 * 2, "Balance 1 is not correct");
        assertEq(pool.balanceOf(user1), expectedLPTokensToMintForUser1, "LP tokens are not minted");
        assertEq(pool.balanceOf(user2), expectedLPTokensToMintForUser2, "LP tokens are not minted");
    }

    function test_add_liquidity_emitsLiquidityAdded() public {
        uint256 expectedLPTokensToMint = Math.sqrt(amount0 * amount1);

        vm.expectEmit();
        emit IPiscineV1Pool.LiquidityAdded(amount0, amount1, expectedLPTokensToMint);

        exchange.addLiquidity(tokenA, tokenB, amountA, amountB);
    }

    function test_addLiquidity_failsIfSameToken() public {
        vm.expectRevert(IPiscineV1Exchange.SameToken.selector);
        exchange.addLiquidity(tokenA, tokenA, amountA, amountB);
    }

    function test_addLiquidity_failsIfAddressZero() public {
        vm.expectRevert(IPiscineV1Exchange.AddressZero.selector);
        exchange.addLiquidity(address(0), tokenB, amountA, amountB);
    }

    function test_addLiquidity_failsIfAmountZero() public {
        vm.expectRevert(IPiscineV1Exchange.AmountZero.selector);
        exchange.addLiquidity(tokenA, tokenB, 0, amountB);
    }

    function test_addLiquidity_failsIfInvalidRatio() public {
        exchange.addLiquidity(tokenA, tokenB, amountA, amountB);
        vm.expectRevert(IPiscineV1Pool.InvalidRatio.selector);
        exchange.addLiquidity(tokenA, tokenB, amountA, amountB * 3);
    }

    function test_fuzz_addLiquidity(uint256 _amountA, uint256 _amountB) public {
        vm.assume(_amountA > 0);
        vm.assume(_amountB > 0);
        vm.assume(_amountA <= type(uint128).max);
        vm.assume(_amountB <= type(uint128).max);

        tokenAMock.mint(address(this), _amountA);
        tokenBMock.mint(address(this), _amountB);

        tokenAMock.approve(address(exchange), _amountA);
        tokenBMock.approve(address(exchange), _amountB);

        (,, uint256 _amount0, uint256 _amount1) =
            PiscineV1Library._sortTokensAndAmounts(tokenA, tokenB, _amountA, _amountB);

        uint256 expectedLPTokensToMint = Math.sqrt(_amount0 * _amount1);

        exchange.addLiquidity(tokenA, tokenB, _amountA, _amountB);

        assertEq(tokenAMock.balanceOf(computedPoolAddress), _amountA, "Tokens A are not transferred");
        assertEq(tokenBMock.balanceOf(computedPoolAddress), _amountB, "Tokens B are not transferred");
        assertEq(pool.balance0(), _amount0, "Balance 0 is not correct");
        assertEq(pool.balance1(), _amount1, "Balance 1 is not correct");
        assertEq(pool.balanceOf(address(this)), expectedLPTokensToMint, "LP tokens are not minted");
    }
}
