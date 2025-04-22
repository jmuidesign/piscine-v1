// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {IPiscineV1Exchange} from "../src/interfaces/IPiscineV1Exchange.sol";
import {PiscineV1Exchange} from "../src/contracts/PiscineV1Exchange.sol";
import {PiscineV1Pool} from "../src/contracts/PiscineV1Pool.sol";
import {PiscineV1Library} from "../src/librairies/PiscineV1Library.sol";

contract CreatePoolTest is Test {
    PiscineV1Exchange public exchange;

    address public tokenA = makeAddr("tokenA");
    address public tokenB = makeAddr("tokenB");
    address public tokenC = makeAddr("tokenC");
    address public tokenD = makeAddr("tokenD");

    function setUp() public {
        exchange = new PiscineV1Exchange(vm.envAddress("UNISWAP_V2_ROUTER"));
    }

    function test_createPool_succeeds() public {
        (address token0, address token1) = PiscineV1Library._sortTokens(tokenA, tokenB);
        address computedPoolAddress = PiscineV1Library._getPoolAddress(tokenA, tokenB, address(exchange));
        PiscineV1Pool pool = PiscineV1Pool(computedPoolAddress);

        exchange.createPool(tokenA, tokenB);

        assertEq(computedPoolAddress, address(pool), "Pool address is not correct");
        assertEq(pool.token0(), token0, "Token0 is not correct");
        assertEq(pool.token1(), token1, "Token1 is not correct");
    }

    function test_createPool_succeedsMultipleTimes() public {
        (address token0, address token1) = PiscineV1Library._sortTokens(tokenA, tokenB);
        address computedPoolAddress = PiscineV1Library._getPoolAddress(tokenA, tokenB, address(exchange));
        PiscineV1Pool pool = PiscineV1Pool(computedPoolAddress);

        exchange.createPool(tokenA, tokenB);

        assertEq(computedPoolAddress, address(pool), "Pool address is not correct");
        assertEq(pool.token0(), token0, "Token0 is not correct");
        assertEq(pool.token1(), token1, "Token1 is not correct");

        (address token0Bis, address token1Bis) = PiscineV1Library._sortTokens(tokenC, tokenD);
        address computedPoolAddressBis = PiscineV1Library._getPoolAddress(tokenC, tokenD, address(exchange));
        PiscineV1Pool poolBis = PiscineV1Pool(computedPoolAddressBis);

        exchange.createPool(tokenC, tokenD);

        assertEq(computedPoolAddressBis, address(poolBis), "Pool address is not correct");
        assertEq(poolBis.token0(), token0Bis, "Token0 is not correct");
        assertEq(poolBis.token1(), token1Bis, "Token1 is not correct");
    }

    function test_createPool_emitsPoolCreated() public {
        (address token0, address token1) = PiscineV1Library._sortTokens(tokenA, tokenB);
        address computedPoolAddress = PiscineV1Library._getPoolAddress(tokenA, tokenB, address(exchange));

        vm.expectEmit();
        emit IPiscineV1Exchange.PoolCreated(computedPoolAddress, token0, token1);

        exchange.createPool(tokenA, tokenB);
    }

    function test_createPool_failsIfSameToken() public {
        vm.expectRevert(IPiscineV1Exchange.SameToken.selector);
        exchange.createPool(tokenA, tokenA);
    }

    function test_createPool_failsIfAddressZero() public {
        vm.expectRevert(IPiscineV1Exchange.AddressZero.selector);
        exchange.createPool(address(0), tokenB);
    }

    function test_createPool_failsIfPoolAlreadyExists() public {
        exchange.createPool(tokenA, tokenB);
        vm.expectRevert(IPiscineV1Exchange.PoolAlreadyExists.selector);
        exchange.createPool(tokenA, tokenB);
    }

    function test_fuzz_createPool(address _tokenA, address _tokenB) public {
        vm.assume(_tokenA != _tokenB);
        vm.assume(_tokenA != address(0));
        vm.assume(_tokenB != address(0));

        (address token0, address token1) = PiscineV1Library._sortTokens(_tokenA, _tokenB);
        address computedPoolAddress = PiscineV1Library._getPoolAddress(_tokenA, _tokenB, address(exchange));
        PiscineV1Pool pool = PiscineV1Pool(computedPoolAddress);

        exchange.createPool(_tokenA, _tokenB);

        assertEq(computedPoolAddress, address(pool), "Pool address is not correct");
        assertEq(pool.token0(), token0, "Token0 is not correct");
        assertEq(pool.token1(), token1, "Token1 is not correct");
    }
}
