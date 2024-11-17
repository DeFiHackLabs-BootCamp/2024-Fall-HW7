// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/week4_game/Game.sol";
import {Test, console} from "forge-std/Test.sol";

contract GameBaseTest is Test {
    Game game;
    address public someUser = address(0x123);

    function setUp() public virtual {
        //setup game with 1 ether as reward
        game = new Game{value: 1 ether}();
        assertEq(address(game).balance, 1 ether);
    }

    function test_play() public {
        // A user  play the game
        vm.prank(someUser);
        //  user input a number and receive reward address
        game.guess(102, someUser);
        // user did not guess the right ans
        assertEq(address(someUser).balance, 0);
    }

    modifier checkChallengeSolved() {
        _;
        assertEq(address(game).balance, 0);
    }
}
