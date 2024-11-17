// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { Minter } from "./Minter.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/// @title Weapon
/// @notice This contract represents a collection of game weapons used in game.
contract Weapon is ERC1155 {

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Event emitted when a game weapon is bought.
    /// @param Purchaser The address of the Purchaser.
    /// @param tokenId The id of the game weapon.
    /// @param aomunt The aomunt of the game weapon.
    event PurchaseWeapon(address Purchaser, uint256 tokenId, uint256 aomunt);

    /// @notice Event emitted when an weapon is locked and thus cannot be traded.
    /// @param tokenId The id of the game weapon.
    event Locked(uint256 tokenId);

    /// @notice Event emitted when an weapon is unlocked and can be traded.
    /// @param tokenId The id of the game weapon.
    event Unlocked(uint256 tokenId);

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Struct for game weapon attributes
    struct GameWeaponAttributes {
        string name;
        bool finiteSupply;
        bool transferable;
        uint256 weaponsRemaining;
        uint256 weaponPrice;
        uint256 dailyAllowance;
    }  

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The name of this smart contract.
    string public name = " Game weapons";

    /// @notice The symbol for this smart contract.
    string public symbol = "GW";

    /// @notice List of all gameWeaponAttribute structs representing all game weapons.
    GameWeaponAttributes[] public allGameWeaponAttributes;

    /// @notice The address that recieves funds of purchased game weapons.
    address public treasuryAddress;

    /// The address that has owner privileges (initially the contract deployer).
    address _ownerAddress;

    /// Total number of game weapons.
    uint256 _weaponCount = 0;    

    /// @dev The Minter contract instance.
    Minter _minterInstance;
    
    /*//////////////////////////////////////////////////////////////
                                MAPPINGS
    //////////////////////////////////////////////////////////////*/ 

    /// @notice Mapping of address to tokenId to get remaining allowance.
    mapping(address => mapping(uint256 => uint256)) public allowanceRemaining;

    /// @notice Mapping of address to tokenId to get replenish timestamp.
    mapping(address => mapping(uint256 => uint256)) public dailyAllowanceReplenishTime;

    /// @notice Mapping tracking addresses allowed to burn game weapons.
    mapping(address => bool) public allowedBurningAddresses;

    /// @notice Mapping tracking addresses allowed to manage game weapons.
    mapping(address => bool) public isAdmin;

    /// @notice Mapping of token id to the token URI
    mapping(uint256 => string) private _tokenURIs;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the owner address and the isAdmin mapping to true for the owner address.
    /// @param ownerAddress Address of contract deployer.
    /// @param treasuryAddress_ Address of admin signer for messages.
    constructor(address ownerAddress, address treasuryAddress_) ERC1155("https://ipfs.io/ipfs/") {
        _ownerAddress = ownerAddress;
        treasuryAddress = treasuryAddress_;
        isAdmin[_ownerAddress] = true;
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/    

    /// @notice Transfers ownership from one address to another.
    /// @dev Only the owner address is authorized to call this function.
    /// @param newOwnerAddress The address of the new owner
    function transferOwnership(address newOwnerAddress) external {
        require(msg.sender == _ownerAddress);
        _ownerAddress = newOwnerAddress;
    }

    /// @notice Adjusts admin access for a user.
    /// @dev Only the owner address is authorized to call this function.
    /// @param adminAddress The address of the admin.
    /// @param access Whether the address has admin access or not.
    function adjustAdminAccess(address adminAddress, bool access) external {
        require(msg.sender == _ownerAddress);
        isAdmin[adminAddress] = access;
    }  

    /// @notice Adjusts whether the game weapon can be transferred or not
    /// @dev Only the owner address is authorized to call this function.
    /// @param tokenId The token id for the specific game weapon being adjusted.
    /// @param transferable Whether the game weapon is transferable or not
    function adjustTransferability(uint256 tokenId, bool transferable) external {
        require(msg.sender == _ownerAddress);
        allGameWeaponAttributes[tokenId].transferable = transferable;
        if (transferable) {
          emit Unlocked(tokenId);
        } else {
          emit Locked(tokenId);
        }
    }

    /// @notice Sets the Minter contract address and instantiates the contract.
    /// @dev Only the owner address is authorized to call this function.
    /// @param minterAddress The address of the Minter contract.
    function instantiateMinterContract(address minterAddress) external {
        require(msg.sender == _ownerAddress);
        _minterInstance = Minter(minterAddress);
    }

    /// @notice Mints  weapons and assigns them to the caller.
    /// @param tokenId The ID of the weapon to mint.
    /// @param aomunt The aomunt of weapons to mint.
    function mint(uint256 tokenId, uint256 aomunt) external {
        require(tokenId < _weaponCount);
        uint256 price = allGameWeaponAttributes[tokenId].weaponPrice * aomunt;
        require(_minterInstance.balanceOf(msg.sender) >= price, "Not enough token for purchase");
        require(
            allGameWeaponAttributes[tokenId].finiteSupply == false || 
            (
                allGameWeaponAttributes[tokenId].finiteSupply == true && 
                aomunt <= allGameWeaponAttributes[tokenId].weaponsRemaining
            )
        );
        require(
            dailyAllowanceReplenishTime[msg.sender][tokenId] <= block.timestamp || 
            aomunt <= allowanceRemaining[msg.sender][tokenId]
        );

        _minterInstance.approveSpender(msg.sender, price);
        bool success = _minterInstance.transferFrom(msg.sender, treasuryAddress, price);
        if (success) {
            if (dailyAllowanceReplenishTime[msg.sender][tokenId] <= block.timestamp) {
                _replenishDailyAllowance(tokenId);
            }
            allowanceRemaining[msg.sender][tokenId] -= aomunt;
            if (allGameWeaponAttributes[tokenId].finiteSupply) {
                allGameWeaponAttributes[tokenId].weaponsRemaining -= aomunt;
            }
            _mint(msg.sender, tokenId, aomunt, bytes("random"));
            emit PurchaseWeapon(msg.sender, tokenId, aomunt);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/    

    /// @notice Sets the allowed burning addresses.
    /// @dev Only the admins are authorized to call this function.
    /// @param newBurningAddress The address to allow for burning.
    function setAllowedBurningAddresses(address newBurningAddress) public {
        require(isAdmin[msg.sender]);
        allowedBurningAddresses[newBurningAddress] = true;
    }

    /// @notice Sets the token URI for a game weapon
    /// @dev Only the admins are authorized to call this function.
    /// @param tokenId The token id for the specific game weapon being queried.    
    /// @param _tokenURI The token id to be set
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(isAdmin[msg.sender]);
        _tokenURIs[tokenId] = _tokenURI;
    }

    /// @notice Creates a new game weapon with the specified attributes.
    /// @dev Only the admins are authorized to call this function.
    /// @param name_ The name of the game weapon.
    /// @param tokenURI The URI of the game weapon.
    /// @param finiteSupply Determines if the game weapon has a finite supply.
    /// @param transferable Boolean of whether or not the game weapon can be transferred
    /// @param weaponsRemaining The number of remaining weapons for the game weapon.
    /// @param weaponPrice The price of the game weapon.
    /// @param dailyAllowance The daily allowance for the game weapon.
    function createGameWeapon(
        string memory name_,
        string memory tokenURI,
        bool finiteSupply,
        bool transferable,
        uint256 weaponsRemaining,
        uint256 weaponPrice,
        uint16 dailyAllowance
    ) 
        public 
    {
        require(isAdmin[msg.sender]);
        allGameWeaponAttributes.push(
            GameWeaponAttributes(
                name_,
                finiteSupply,
                transferable,
                weaponsRemaining,
                weaponPrice,
                dailyAllowance
            )
        );
        if (!transferable) {
          emit Locked(_weaponCount);
        }
        setTokenURI(_weaponCount, tokenURI);
        _weaponCount += 1;
    }

    /// @notice Burns a specified amount of game weapons from an account.
    /// @dev Only addresses listed in allowedBurningAddresses are authorized to call this function.
    /// @param account The account from which the game weapons will be burned.
    /// @param tokenId The ID of the game weapon.
    /// @param amount The amount of game weapons to burn.
    function burn(address account, uint256 tokenId, uint256 amount) public {
        require(allowedBurningAddresses[msg.sender]);
        _burn(account, tokenId, amount);
    }

    /// @notice Returns the URI where the contract metadata is stored.
    /// @return URI where the contract metadata is stored.
    function contractURI() public pure returns (string memory) {
        return "ipfs://baaybdih3witscmml3p1234qwera5jh4rl2xre7ayd345sxmysdfpwtpaxx";
    }

    /// @notice Override the uri function to return the custom URI for each token
    /// @param tokenId The token id for the specific game weapon being queried.
    /// @return tokenURI The URI for the game weapon metadata.
    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory customURI = _tokenURIs[tokenId];
        if (bytes(customURI).length > 0) {
            return customURI;
        }
        return super.uri(tokenId);
    }        

    /// @notice Gets the amount of a game weapon that a user is still able to mint for the day
    /// @param owner The user's address.
    /// @param tokenId The token id for the specific game weapon being queried.
    /// @return remaining number of weapons that can be minted for the day.
    function getAllowanceRemaining(address owner, uint256 tokenId) public view returns (uint256) {
        uint256 remaining = allowanceRemaining[owner][tokenId];
        if (dailyAllowanceReplenishTime[owner][tokenId] <= block.timestamp) {
            remaining = allGameWeaponAttributes[tokenId].dailyAllowance;
        }
        return remaining;
    }

    /// @notice Returns the remaining supply of a game weapon with the specified tokenId.
    /// @param tokenId The ID of the game weapon.
    /// @return Remaining weapons for the queried token ID.
    function remainingSupply(uint256 tokenId) public view returns (uint256) {
        return allGameWeaponAttributes[tokenId].weaponsRemaining;
    }

    /// @notice Returns the total number of unique game tokens outstanding.
    /// @return Total number of unique game tokens.
    function uniqueTokensOutstanding() public view returns (uint256) {
        return allGameWeaponAttributes.length;
    }

    /// @notice Safely transfers an NFT from one address to another.
    /// @dev Added a check to see if the game weapon is transferable.
    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) 
        public 
        override(ERC1155)
    {
        require(allGameWeaponAttributes[tokenId].transferable);
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /*//////////////////////////////////////////////////////////////
                            PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/    

    /// @notice Replenishes the daily allowance for the specified game weapon token.
    /// @dev This function is called when a user buys a game weapon after the replenish interval has passed.
    /// @param tokenId The ID of the game weapon token.
    function _replenishDailyAllowance(uint256 tokenId) private {
        allowanceRemaining[msg.sender][tokenId] = allGameWeaponAttributes[tokenId].dailyAllowance;
        dailyAllowanceReplenishTime[msg.sender][tokenId] = uint32(block.timestamp + 1 days);
    }    
}