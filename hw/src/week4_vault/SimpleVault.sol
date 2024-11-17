// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleVault {
    uint256 public withdrawReserve;
    address public owner;
    uint64 public currentEpoch;
    mapping(uint64 => address) public withdrawProxies;

    event TransferWithdraw(uint256 amount, uint256 newWithdrawReserve);
    event WithdrawReserveTransferred(uint256 amount);
    event EpochProcessed(uint64 newEpoch);
    event Deposit(address depositor, uint256 amount);

    constructor() {
        owner = msg.sender;
        currentEpoch = 1;
    }
    /**
     * @notice Sets the withdraw proxy address for a specific epoch.
     * @dev Only the owner of the contract can call this function to set the withdraw proxy for each epoch.
     * @param epoch The epoch number for which the withdraw proxy is being set.
     * @param proxy The address of the withdraw proxy.
     */

    function setWithdrawProxy(uint64 epoch, address proxy) external {
        require(msg.sender == owner, "Only owner can set the withdraw proxy");
        withdrawProxies[epoch] = proxy;
    }

    /**
     * @notice Rotate epoch boundary. This must be called before the next epoch can begin.
     */
    function processEpoch() external {
        require(withdrawReserve == 0, "Withdraw reserve not empty");

        currentEpoch++;
        emit EpochProcessed(currentEpoch);
    }

    function transferWithdrawReserve() public {
        uint256 availableFunds = address(this).balance;

        emit TransferWithdraw(availableFunds, withdrawReserve);

        if (withdrawReserve <= availableFunds) {
            availableFunds = withdrawReserve;
            withdrawReserve = 0;
        } else {
            withdrawReserve -= availableFunds;
        }

        emit TransferWithdraw(availableFunds, withdrawReserve);

        address currentWithdrawProxy = withdrawProxies[currentEpoch - 1];
        // prevents transfer to a non-existent WithdrawProxy
        // withdrawProxies are indexed by the epoch where they're deployed
        if (currentWithdrawProxy != address(0)) {
            (bool success,) = currentWithdrawProxy.call{value: availableFunds}("");
            require(success, "Transfer failed");
            emit WithdrawReserveTransferred(availableFunds);
        }
    }

    receive() external payable {
        withdrawReserve += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}
