// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Vm} from "forge-std/Vm.sol";
import {PiscineV1Exchange} from "../src/contracts/PiscineV1Exchange.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract Anvil is Script, StdCheats {
    PiscineV1Exchange public exchange;
    ERC20Mock public tokenAMock;
    ERC20Mock public tokenBMock;
    ERC20Mock public tokenCMock;

    function _mintTokensAndApproveExchange(address walletAddress) internal {
        tokenAMock.mint(walletAddress, 100_000_000);
        tokenBMock.mint(walletAddress, 100_000_000);
        tokenCMock.mint(walletAddress, 100_000_000);

        tokenAMock.approve(address(exchange), 100_000_000);
        tokenBMock.approve(address(exchange), 100_000_000);
        tokenCMock.approve(address(exchange), 100_000_000);
    }

    function _addSomeLiquidity() internal {
        exchange.addLiquidity(address(tokenAMock), address(tokenBMock), 10_000_000, 10_000_000);
        exchange.addLiquidity(address(tokenAMock), address(tokenCMock), 20_000_000, 40_000_000);
        exchange.addLiquidity(address(tokenBMock), address(tokenCMock), 40_000_000, 60_000_000);
    }

    function _doSomeSwaps() internal {
        exchange.swapTokens(address(tokenAMock), address(tokenBMock), 2_000_000, 1);
        exchange.swapTokens(address(tokenAMock), address(tokenCMock), 5_000_000, 1);
        exchange.swapTokens(address(tokenBMock), address(tokenCMock), 10_000_000, 1);
    }

    function run() public {
        Vm.Wallet memory wallet1 = vm.createWallet(vm.envUint("PRIVATE_KEY_1"));
        Vm.Wallet memory wallet2 = vm.createWallet(vm.envUint("PRIVATE_KEY_2"));

        vm.startBroadcast(wallet1.privateKey);

        exchange = new PiscineV1Exchange();

        tokenAMock = new ERC20Mock();
        tokenBMock = new ERC20Mock();
        tokenCMock = new ERC20Mock();

        _mintTokensAndApproveExchange(wallet1.addr);
        _addSomeLiquidity();
        _doSomeSwaps();

        vm.stopBroadcast();

        vm.startBroadcast(wallet2.privateKey);

        _mintTokensAndApproveExchange(wallet2.addr);
        _doSomeSwaps();

        vm.stopBroadcast();
    }
}
