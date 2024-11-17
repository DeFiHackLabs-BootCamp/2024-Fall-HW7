// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "openzeppelin-contracts/access/AccessControl.sol";

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

/// @title Minter
/// @notice ERC20 token contract representing AmazingToken.
contract Minter is ERC20, AccessControl {

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Event emitted when tokens are claimed.
    event TokensClaimed(address user, uint256 amount);

    /// @notice Event emitted when tokens are minted.
    event TokensMinted(address user, uint256 amount);    

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Role for minting tokens.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Role for staking tokens.
    bytes32 public constant STAKER_ROLE = keccak256("STAKER_ROLE");

    /// @notice Role for spending tokens.
    bytes32 public constant SPENDER_ROLE = keccak256("SPENDER_ROLE");

    uint256 public constant INITIAL_OWNER_MINT = 10**18 * 10**8 * 5;


    /// @notice Maximum supply of AMZ tokens.
    uint256 public constant MAX_SUPPLY = 10**18 * 10**9;


    /// The address that has owner power
    address _ownerAddress;

    /*//////////////////////////////////////////////////////////////
                                MAPPINGS
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping of address to admin status.
    mapping(address => bool) public isAdmin;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Grants roles to contract. 
    /// @notice Mints the initial supply of tokens.
    /// @param ownerAddress The address of the owner who deploys the contract
    /// the initial supply is minted.
    constructor(address ownerAddress)
        ERC20("AmazingToken", "Amz")
    {   
        _grantRole(DEFAULT_ADMIN_ROLE, ownerAddress);
       
        _ownerAddress = ownerAddress;
        isAdmin[_ownerAddress] = true;
        _mint(_ownerAddress, INITIAL_OWNER_MINT);
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Transfers ownership.
    /// @dev Only the owner can call.
    /// @param newOwnerAddress is new owner
    function transferOwnership(address newOwnerAddress) external {
        require(msg.sender == _ownerAddress);
        _ownerAddress = newOwnerAddress;
    }

    /// @notice Adds new minter
    /// @dev Only  owner can call
    /// @param newMinterAddress is new minter
    function addMinter(address newMinterAddress) external {
        require(msg.sender == _ownerAddress);
       _grantRole(MINTER_ROLE, newMinterAddress);
    }

    /// @notice Adds new staker
    /// @dev Only  owner can call
    /// @param newStakerAddress is new staker
    function addStaker(address newStakerAddress) external {
        require(msg.sender == _ownerAddress);
        _grantRole(STAKER_ROLE, newStakerAddress);
    }

    /// @notice Adds a new address to the spender role.
    /// @dev Only the owner address is authorized to call this function.
    /// @param newSpenderAddress The address to be added as a spender
    function addSpender(address newSpenderAddress) external {
        require(msg.sender == _ownerAddress);
        _grantRole(SPENDER_ROLE, newSpenderAddress);
    }

    /// @notice Updates admin 
    /// @dev Only the owner can call
    /// @param adminAddress is admin
    /// @param access is admin or not.
    function updateAdminAccess(address adminAddress, bool access) external {
        require(msg.sender == _ownerAddress);
        isAdmin[adminAddress] = access;
    }  

    /// @notice Approves allowances for a batch of recipients from the owner's address.
    /// @dev only admin can call
    /// @param recipients  recipient addresses
    /// @param amounts amounts for each recipient
    function airdropList(address[] calldata recipients, uint256[] calldata amounts) external {
        require(isAdmin[msg.sender]);
        require(recipients.length == amounts.length);
        uint256 recipientsLength = recipients.length;
        for (uint32 i = 0; i < recipientsLength; i++) {
            _approve(_ownerAddress, recipients[i], amounts[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint token.
    /// @dev The caller must have the minter role.
    /// @param to The address to which the tokens will be minted.
    /// @param amount The amount of tokens to be minted.
    function mint(address to, uint256 amount) public virtual {
        require(totalSupply() + amount < MAX_SUPPLY, "Mint too much");
        require(hasRole(MINTER_ROLE, msg.sender), "Be a Minter");
        _mint(to, amount);
    }

    /// @notice Burns the specified amount of tokens from the caller's address.
    /// @param amount The amount of tokens to be burned.
    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }


    /// @notice Approves the specified amount of tokens to staker
    /// @dev The caller must have the staker role.
    /// @param owner The owner of the tokens.
    /// @param spender The address for which to approve the allowance.
    /// @param amount The amount of tokens to be approved.
    function approveStaker(address owner, address spender, uint256 amount) public {
        require(
            hasRole(STAKER_ROLE, msg.sender), 
            "ERC20: must have staker role to approve staking"
        );
        _approve(owner, spender, amount);
    }

     /// @notice Approves the specified amount of tokens for the spender address.
    /// @dev The caller must have the spender role.
    /// @param account The account for which to approve the allowance.
    /// @param amount The amount of tokens to be approved.
    function approveSpender(address account, uint256 amount) public {
        require(
            hasRole(SPENDER_ROLE, msg.sender), 
            "ERC20: must have spender role to approve spending"
        );
        _approve(account, msg.sender, amount);
    }
 
}