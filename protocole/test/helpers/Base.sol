// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {PiscineV1Exchange} from "../../src/contracts/PiscineV1Exchange.sol";
import {PiscineV1Pool} from "../../src/contracts/PiscineV1Pool.sol";
import {PiscineV1Library} from "../../src/librairies/PiscineV1Library.sol";

abstract contract BaseTest is Test {
    using Math for uint256;

    ERC20Mock public tokenAMock;
    ERC20Mock public tokenBMock;

    address public tokenA;
    address public tokenB;
    uint256 public amountA;
    uint256 public amountB;

    address public token0;
    address public token1;
    uint256 public amount0;
    uint256 public amount1;

    PiscineV1Exchange public exchange;
    address public computedPoolAddress;
    PiscineV1Pool public pool;

    address public user1;
    address public user2;

    uint256 public balanceA;
    uint256 public balanceB;
    uint256 public balance0;
    uint256 public balance1;

    uint256 public balanceAUser1;
    uint256 public balanceBUser1;
    uint256 public balanceAUser2;
    uint256 public balanceBUser2;

    function setUp() public virtual {
        tokenAMock = new ERC20Mock();
        tokenBMock = new ERC20Mock();

        tokenA = address(tokenAMock);
        tokenB = address(tokenBMock);
        amountA = 10_000_000;
        amountB = 20_000_000;

        (token0, token1, amount0, amount1) = PiscineV1Library._sortTokensAndAmounts(tokenA, tokenB, amountA, amountB);

        exchange = new PiscineV1Exchange();
        computedPoolAddress = PiscineV1Library._getPoolAddress(tokenA, tokenB, address(exchange));
        pool = PiscineV1Pool(computedPoolAddress);

        tokenAMock.mint(address(this), 100_000_000);
        tokenBMock.mint(address(this), 100_000_000);
        tokenAMock.approve(address(exchange), 100_000_000);
        tokenBMock.approve(address(exchange), 100_000_000);

        user1 = address(1);
        user2 = address(2);

        tokenAMock.mint(user1, 100_000_000);
        tokenBMock.mint(user1, 100_000_000);
        tokenAMock.mint(user2, 100_000_000);
        tokenBMock.mint(user2, 100_000_000);

        vm.startPrank(user1);
        tokenAMock.approve(address(exchange), 100_000_000);
        tokenBMock.approve(address(exchange), 100_000_000);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenAMock.approve(address(exchange), 100_000_000);
        tokenBMock.approve(address(exchange), 100_000_000);
        vm.stopPrank();
    }

    function _setupLiquidityAndBalances() internal {
        exchange.addLiquidity(tokenA, tokenB, amountA, amountB);

        balanceA = tokenAMock.balanceOf(address(this));
        balanceB = tokenBMock.balanceOf(address(this));
        balance0 = pool.balance0();
        balance1 = pool.balance1();

        balanceAUser1 = tokenAMock.balanceOf(user1);
        balanceBUser1 = tokenBMock.balanceOf(user1);
        balanceAUser2 = tokenAMock.balanceOf(user2);
        balanceBUser2 = tokenBMock.balanceOf(user2);
    }
}
