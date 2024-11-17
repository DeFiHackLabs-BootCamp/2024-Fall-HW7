// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import "../../src/week7_game/Weapon.sol";
import "../../src/week7_game/Minter.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
contract WeaponBaseTest is Test {
    address internal constant _DELEGATED_ADDRESS = address(0x123);
    address internal _ownerAddress;
    address internal _treasuryAddress;
    address internal _minterContributorAddress;

    Weapon internal _weapon;
    Minter internal _minter;
    function setUp() public {
        _ownerAddress = address(this);
        _treasuryAddress = makeAddr("treasury");
        _minterContributorAddress = makeAddr("minterContributorAddress");

        _weapon = new Weapon(_ownerAddress, _treasuryAddress);
        _minter = new Minter(_ownerAddress);

        _minter.addSpender(address(_weapon));

        _weapon.instantiateMinterContract(address(_minter));
        _weapon.createGameWeapon("Justice Golden Fist", "https://ipfs.io/ipfs/", true, true, 10_000, 1 * 10 ** 18, 10);
    }
    /// @notice Test the owner transferring ownership and the new owner accessing functions restricted to the owner.
    function testChangeOwnershipByCurrentOwner() public {
        _weapon.transferOwnership(_DELEGATED_ADDRESS);
        vm.prank(_DELEGATED_ADDRESS);
        _weapon.adjustAdminAccess(_DELEGATED_ADDRESS, true);
        assertEq(_weapon.isAdmin(_DELEGATED_ADDRESS), true);
    }
    
    /// @notice Test failing to transfer ownership from an unauthorized account.
    function testChangeOwnershipByUnauthorizedUser() public {
        vm.startPrank(msg.sender);
        vm.expectRevert();
        _weapon.transferOwnership(msg.sender);
        vm.expectRevert();
        _weapon.adjustAdminAccess(_DELEGATED_ADDRESS, true);
        assertEq(_weapon.isAdmin(_DELEGATED_ADDRESS), false);
    }
    /// @notice Test adjusting admin access from owner.
    function testAdjustAdminAccessFromOwner() public {
        _weapon.adjustAdminAccess(_DELEGATED_ADDRESS, true);
        assertEq(_weapon.isAdmin(_DELEGATED_ADDRESS), true);
    }
    /// @notice Test adjusting a weapon transferability from owner account.
    function testAdjustTransferabilityFromOwner() public {
        _weapon.mint(0, 2); 
        _weapon.adjustTransferability(0, false);
        (,, bool transferable,,,) = _weapon.allGameWeaponAttributes(0);
        assertEq(transferable, false);
    }

    /// @notice Test adjusting an weapon transferability from non owner account fails.
    function testAdjustTransferabilityFromNonOwner() public {
        _minter.transfer(msg.sender, 4_000 * 10 ** 18);
        assertEq(4_000 * 10 ** 18 == _minter.balanceOf(msg.sender), true);
        vm.startPrank(msg.sender);
        _weapon.mint(0, 2); 
        vm.expectRevert();
        _weapon.adjustTransferability(0, false);
        (,, bool transferable,,,) = _weapon.allGameWeaponAttributes(0);
        assertEq(transferable, true);
    }

    /// @notice Tests successful item burning by a designated address authorized for burning game items.
    function testBurnFromAllowedBurningAddress() public {
        _weapon.mint(0, 1);
        assertEq(_weapon.balanceOf(_ownerAddress, 0), 1);
        _weapon.setAllowedBurningAddresses(_ownerAddress);
        assertEq(_weapon.allowedBurningAddresses(_ownerAddress), true);
        _weapon.burn(_ownerAddress, 0, 1);
        assertEq(_weapon.balanceOf(_ownerAddress, 0), 0);
    }
    /// @notice Tests unsuccessful burning of item by a non authorized address.
    function testBurnFromNonAllowedBurningAddress() public {
        vm.expectRevert();
        _weapon.burn(_ownerAddress, 0, 1);
    }



    /*//////////////////////////////////////////////////////////////
                               HELPERS
    //////////////////////////////////////////////////////////////*/

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    modifier checkChallengeSolved() {
    _weapon.mint(0, 1);
    assertEq(_weapon.balanceOf(_ownerAddress, 0), 1);
    _weapon.adjustTransferability(0, false);
    _;
    assertEq(_weapon.balanceOf(_DELEGATED_ADDRESS, 0), 1);
    assertEq(_weapon.balanceOf(_ownerAddress,0 ), 0);
    (,, bool transferable,,,) = _weapon.allGameWeaponAttributes(0);
    assertEq(transferable, false);
    }
}