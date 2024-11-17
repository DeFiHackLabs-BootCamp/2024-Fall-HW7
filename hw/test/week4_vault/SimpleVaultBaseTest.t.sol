// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console.sol";
import "../../src/week4_vault/SimpleVault.sol";
import {Test, stdError} from "forge-std/Test.sol";

contract SimpleVaultBaseTest is Test {
    SimpleVault vault;
    address owner;
    address proxy1;
    address proxy2;

    function setUp() public {
        owner = address(this);
        proxy1 = address(0x123);
        proxy2 = address(0x456);
        vault = new SimpleVault();
    }

    function testInitialValues() public {
        assertEq(vault.owner(), owner);
        assertEq(vault.currentEpoch(), 1);
        assertEq(vault.withdrawReserve(), 0);
    }
    //deposit to vault

    function testDeposit() public {
        uint256 amount = 1 ether;
        (bool success,) = address(vault).call{value: amount}("");
        require(success, "Call failed");
        assertEq(vault.withdrawReserve(), amount);
    }
    //set proxy

    function testSetWithdrawProxy() public {
        // Test setWithdrawProxy by setting proxy
        vault.setWithdrawProxy(0, proxy1);
        assertEq(vault.withdrawProxies(0), proxy1);

        // If not owner should fail
        vm.prank(address(0x789)); // Change the msg.sender
        vm.expectRevert("Only owner can set the withdraw proxy");
        vault.setWithdrawProxy(1, proxy2);
    }

    // test process epoch
    function testProcessEpoch() public {
        (bool success,) = address(vault).call{value: 1 ether}("");
        require(success, "Call failed");
        vm.expectRevert("Withdraw reserve not empty");
        vault.processEpoch();
        vault.setWithdrawProxy(1, address(this));
        vault.transferWithdrawReserve();
        vault.processEpoch();
        assertEq(vault.currentEpoch(), 2);
    }

    //test withdraw to proxy
    function testTransferWithdrawReserve() public {
        uint256 amount = 1 ether;
        (bool success,) = address(vault).call{value: amount}("");
        require(success, "Call failed");
        // Set proxy for the current epoch
        vault.setWithdrawProxy(0, proxy1);
        // Transfer withdraw reserve
        vault.transferWithdrawReserve();
        // Verify withdraw reserve has been transferred and reset to 0
        assertEq(vault.withdrawReserve(), 0);
        assertEq(address(proxy1).balance, amount);
    }

    modifier checkChallengeSolved() {
        uint256 amount = 1 ether;
        (bool success,) = address(vault).call{value: amount}("");
        require(success, "Call failed");
        _;
        assertEq(vault.withdrawProxies(0), proxy1);
        assertEq(vault.withdrawProxies(1), proxy2);
        assertEq(address(vault).balance, amount);
        assertEq(address(proxy2).balance, amount);
        assertEq(vault.currentEpoch(), 2);
    }
}
