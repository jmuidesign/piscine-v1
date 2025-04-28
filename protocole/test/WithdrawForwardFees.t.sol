// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {BaseTest} from "./helpers/Base.sol";
import {PiscineV1Exchange} from "../src/contracts/PiscineV1Exchange.sol";
import {IPiscineV1Exchange} from "../src/interfaces/IPiscineV1Exchange.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract WithdrawForwardFeesTest is BaseTest {
    address usdc;
    address dai;
    uint256 amountIn;
    uint256 amountInWithFee;
    uint256 balanceUsdc;

    function setUp() public override {
        super.setUp();

        string memory rpcUrl = vm.rpcUrl("mainnet");
        vm.createSelectFork(rpcUrl, 22193947);

        exchange = new PiscineV1Exchange(vm.envAddress("UNISWAP_V2_ROUTER"));

        usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

        amountIn = 1_500_000;
        amountInWithFee = (amountIn * 999) / 1000;

        deal(usdc, address(this), amountIn);
        IERC20(usdc).approve(address(exchange), amountIn);

        exchange.swapTokens(usdc, dai, amountIn, 1);

        balanceUsdc = IERC20(usdc).balanceOf(address(this));
    }

    function test_withdrawForwardFees_succeedsWhenRemoveAllFees() public {
        uint256 forwardFees = exchange.tokenToForwardFees(usdc);
        uint256 amount = forwardFees;

        exchange.withdrawForwardFees(usdc, amount);

        assertEq(exchange.tokenToForwardFees(usdc), forwardFees - amount, "tokenToForwardFees[token] is not correct");
        assertEq(IERC20(usdc).balanceOf(address(this)), balanceUsdc + amount, "balanceUsdc is not correct");
    }

    function test_withdrawForwardFees_succeedsWhenRemovePartialFees() public {
        uint256 forwardFees = exchange.tokenToForwardFees(usdc);
        uint256 amount = forwardFees / 3;

        exchange.withdrawForwardFees(usdc, amount);

        assertEq(exchange.tokenToForwardFees(usdc), forwardFees - amount, "tokenToForwardFees[token] is not correct");
        assertEq(IERC20(usdc).balanceOf(address(this)), balanceUsdc + amount, "balanceUsdc is not correct");
    }

    function test_withdrawForwardFees_emitsForwardFeesWithdrawn() public {
        uint256 forwardFees = exchange.tokenToForwardFees(usdc);
        uint256 amount = forwardFees;

        vm.expectEmit();
        emit IPiscineV1Exchange.ForwardFeesWithdrawn(usdc, amount);

        exchange.withdrawForwardFees(usdc, amount);
    }
}
