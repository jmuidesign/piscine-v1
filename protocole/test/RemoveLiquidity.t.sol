// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {BaseTest} from "./helpers/Base.sol";
import {IPiscineV1Exchange} from "../src/interfaces/IPiscineV1Exchange.sol";
import {IPiscineV1Pool} from "../src/interfaces/IPiscineV1Pool.sol";

contract RemoveLiquidityTest is BaseTest {
    uint256 public lpTokensBalance;
    bool public isTokenAToken0;

    function setUp() public override {
        super.setUp();
        _setupLiquidityAndBalances();
        lpTokensBalance = pool.balanceOf(address(this));
        isTokenAToken0 = tokenA == token0;
    }

    function test_remove_liquidity_succeedsWhenRemoveAllLiquidity() public {
        uint256 lpTokensAmount = lpTokensBalance;
        uint256 _amount0 = balance0 * lpTokensAmount / pool.totalSupply();
        uint256 _amount1 = balance1 * lpTokensAmount / pool.totalSupply();

        exchange.removeLiquidity(tokenA, tokenB, lpTokensAmount);

        assertEq(pool.balanceOf(address(this)), lpTokensBalance - lpTokensAmount, "LP tokens are not burned");
        assertEq(pool.balance0(), balance0 - _amount0, "Balance 0 is not correct");
        assertEq(pool.balance1(), balance1 - _amount1, "Balance 1 is not correct");
        assertEq(
            tokenAMock.balanceOf(address(this)),
            isTokenAToken0 ? balanceA + _amount0 : balanceA + _amount1,
            "Tokens A are not sent back"
        );
        assertEq(
            tokenBMock.balanceOf(address(this)),
            isTokenAToken0 ? balanceB + _amount1 : balanceB + _amount0,
            "Tokens B are not sent back"
        );
    }

    function test_remove_liquidity_succeedsWhenRemoveHalfOfLiquidity() public {
        uint256 lpTokensAmount = lpTokensBalance / 2;
        uint256 _amount0 = balance0 * lpTokensAmount / pool.totalSupply();
        uint256 _amount1 = balance1 * lpTokensAmount / pool.totalSupply();

        exchange.removeLiquidity(tokenA, tokenB, lpTokensAmount);

        assertEq(pool.balanceOf(address(this)), lpTokensBalance - lpTokensAmount, "LP tokens are not burned");
        assertEq(pool.balance0(), balance0 - _amount0, "Balance 0 is not correct");
        assertEq(pool.balance1(), balance1 - _amount1, "Balance 1 is not correct");
        assertEq(
            tokenAMock.balanceOf(address(this)),
            isTokenAToken0 ? balanceA + _amount0 : balanceA + _amount1,
            "Tokens A are not sent back"
        );
        assertEq(
            tokenBMock.balanceOf(address(this)),
            isTokenAToken0 ? balanceB + _amount1 : balanceB + _amount0,
            "Tokens B are not sent back"
        );
    }

    function _testUserLiquidityRemoval(address user) private {
        vm.startPrank(user);
        exchange.addLiquidity(tokenA, tokenB, amountA, amountB);

        uint256 tokenABalance = tokenAMock.balanceOf(user);
        uint256 tokenBBalance = tokenBMock.balanceOf(user);
        uint256 lpTokensAmount = lpTokensBalance;
        uint256 _balance0 = pool.balance0();
        uint256 _balance1 = pool.balance1();
        uint256 _amount0 = _balance0 * lpTokensAmount / pool.totalSupply();
        uint256 _amount1 = _balance1 * lpTokensAmount / pool.totalSupply();

        exchange.removeLiquidity(tokenA, tokenB, lpTokensAmount);

        assertEq(pool.balanceOf(user), lpTokensBalance - lpTokensAmount, "LP tokens not burned");
        assertEq(pool.balance0(), _balance0 - _amount0, "Balance 0 is not correct");
        assertEq(pool.balance1(), _balance1 - _amount1, "Balance 1 is not correct");
        assertEq(
            tokenAMock.balanceOf(user),
            isTokenAToken0 ? tokenABalance + _amount0 : tokenABalance + _amount1,
            "Tokens A are not sent back"
        );
        assertEq(
            tokenBMock.balanceOf(user),
            isTokenAToken0 ? tokenBBalance + amount1 : tokenBBalance + amount0,
            "Tokens B are not sent back"
        );
        vm.stopPrank();
    }

    function test_remove_liquidity_succeedsWithMultipleLiquidityRemovers() public {
        _testUserLiquidityRemoval(user1);
        _testUserLiquidityRemoval(user2);
    }

    function test_remove_liquidity_emitsRemoveLiquidityRemoved() public {
        uint256 lpTokensAmount = lpTokensBalance;
        uint256 _amount0 = balance0 * lpTokensAmount / pool.totalSupply();
        uint256 _amount1 = balance1 * lpTokensAmount / pool.totalSupply();

        vm.expectEmit();
        emit IPiscineV1Pool.LiquidityRemoved(_amount0, _amount1, lpTokensAmount);

        exchange.removeLiquidity(tokenA, tokenB, lpTokensAmount);
    }

    function test_removeLiquidity_failsIfSameToken() public {
        vm.expectRevert(IPiscineV1Exchange.SameToken.selector);
        exchange.removeLiquidity(tokenA, tokenA, lpTokensBalance);
    }

    function test_removeLiquidity_failsIfAddressZero() public {
        vm.expectRevert(IPiscineV1Exchange.AddressZero.selector);
        exchange.removeLiquidity(address(0), tokenB, lpTokensBalance);
    }

    function test_removeLiquidity_failsIfPoolDoesNotExist() public {
        vm.expectRevert(IPiscineV1Exchange.PoolDoesNotExist.selector);
        exchange.removeLiquidity(makeAddr("tokenC"), makeAddr("tokenD"), lpTokensBalance);
    }

    function test_fuzz_removeLiquidity(uint256 lpTokensAmount) public {
        vm.assume(lpTokensAmount <= lpTokensBalance);

        exchange.removeLiquidity(tokenA, tokenB, lpTokensAmount);
    }
}
