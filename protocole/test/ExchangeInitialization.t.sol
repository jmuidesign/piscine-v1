// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PiscineV1Exchange} from "../src/contracts/PiscineV1Exchange.sol";

contract ExchangeInitializationTest is Test {
    PiscineV1Exchange public exchange;

    function setUp() public {
        exchange = new PiscineV1Exchange(vm.envAddress("UNISWAP_V2_ROUTER"));
    }

    function test_initialization_succeeds() public view {
        assertEq(exchange.owner(), address(this), "Incorrect owner value");
    }
}
