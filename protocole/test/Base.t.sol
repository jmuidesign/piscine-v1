// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {PiscineV1Exchange} from "../src/contracts/PiscineV1Exchange.sol";
import {PiscineV1Pool} from "../src/contracts/PiscineV1Pool.sol";
import {PiscineV1Library} from "../src/librairies/PiscineV1Library.sol";

contract BaseTest is Test {
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

    function setUp() public virtual {
        tokenAMock = new ERC20Mock();
        tokenBMock = new ERC20Mock();

        tokenA = address(tokenAMock);
        tokenB = address(tokenBMock);
        amountA = 100;
        amountB = 200;

        (token0, token1, amount0, amount1) = PiscineV1Library.sortTokensAndAmounts(tokenA, tokenB, amountA, amountB);

        exchange = new PiscineV1Exchange();
        computedPoolAddress = PiscineV1Library.getPoolAddress(tokenA, tokenB, address(exchange));
        pool = PiscineV1Pool(computedPoolAddress);

        tokenAMock.mint(address(this), 1000);
        tokenBMock.mint(address(this), 1000);
        tokenAMock.approve(computedPoolAddress, 1000);
        tokenBMock.approve(computedPoolAddress, 1000);

        user1 = address(1);
        user2 = address(2);

        tokenAMock.mint(user1, 1000);
        tokenBMock.mint(user1, 1000);
        tokenAMock.mint(user2, 1000);
        tokenBMock.mint(user2, 1000);

        vm.startPrank(user1);
        tokenAMock.approve(computedPoolAddress, 1000);
        tokenBMock.approve(computedPoolAddress, 1000);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenAMock.approve(computedPoolAddress, 1000);
        tokenBMock.approve(computedPoolAddress, 1000);
        vm.stopPrank();
    }
}
