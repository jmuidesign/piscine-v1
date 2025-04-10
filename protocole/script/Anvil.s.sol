// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Vm} from "forge-std/Vm.sol";
import {PiscineV1Exchange} from "../src/contracts/PiscineV1Exchange.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract Anvil is Script, StdCheats {
    ERC20Mock public tokenAMock;
    ERC20Mock public tokenBMock;
    ERC20Mock public tokenCMock;

    function run() public {
        Vm.Wallet memory wallet = vm.createWallet(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(wallet.privateKey);

        tokenAMock = new ERC20Mock();
        tokenBMock = new ERC20Mock();
        tokenCMock = new ERC20Mock();

        PiscineV1Exchange exchange = new PiscineV1Exchange();

        tokenAMock.mint(wallet.addr, 100_000_000);
        tokenBMock.mint(wallet.addr, 100_000_000);
        tokenCMock.mint(wallet.addr, 100_000_000);

        tokenAMock.approve(address(exchange), 100_000_000);
        tokenBMock.approve(address(exchange), 100_000_000);
        tokenCMock.approve(address(exchange), 100_000_000);

        exchange.addLiquidity(address(tokenAMock), address(tokenBMock), 10_000_000, 10_000_000);
        exchange.addLiquidity(address(tokenAMock), address(tokenCMock), 20_000_000, 40_000_000);
        exchange.addLiquidity(address(tokenBMock), address(tokenCMock), 40_000_000, 60_000_000);

        vm.stopBroadcast();
    }
}
