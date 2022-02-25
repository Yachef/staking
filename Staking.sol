// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/IERC20.sol";

/**
* @notice This staking contracts implements a simple mechanism : you receive 10 $DBAR per block while you hold.
*/
contract Staking {
    uint constant REWARDS_PER_BLOCK = 10;
    struct Deposit {
        uint amount;
        uint blockNumber;
    }

    address owner;
    RewardContract rewardContract;
    IERC20 private dbarToken;
    mapping(address => Deposit) private dbarBalance;
    mapping(address => uint) private xdbarBalance;
    uint totalStakers;

    constructor(address _dbarTokenAddress, address _rewardContract) {
        owner = msg.sender;
        dbarToken = IERC20(_dbarTokenAddress);
        rewardContract = RewardContract(_rewardContract);
    }

    /**
    * @notice User deposits the amount he wants to stake.
    * @dev We store the block number at the time of the deposit
    * @param _amount to deposit
    */
    function deposit(uint _amount) external {
        dbarToken.transferFrom(msg.sender, address(this), _amount);
        dbarBalance[msg.sender] = Deposit({amount: _amount, blockNumber: block.number});
        totalStakers++;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    /**
     * @notice Transfers rewards from the reward contract so that they can be distributed when withdrawed.
    */
    function redeem() onlyOwner external {
        uint rewardsToRetrieve = totalStakers * REWARDS_PER_BLOCK;
        rewardContract.transferRewards(rewardsToRetrieve);
    }

    /**
     * @notice Withdraws initial amount + rewards of the sender.
    */
    function withdraw() external  {
        uint reward = REWARDS_PER_BLOCK * (block.number - dbarBalance[msg.sender].blockNumber);
        uint totalAmountToWithdraw = dbarBalance[msg.sender].amount + reward;
        dbarToken.transfer(msg.sender, totalAmountToWithdraw);
        delete dbarBalance[msg.sender];
        totalStakers--;
    }
}

contract RewardContract {

    address stakingContractAddress;
    IERC20 public dbarToken;
    address owner;

    constructor(address _dbarTokenAddress, address _owner) {
        owner = _owner;
        dbarToken = IERC20(_dbarTokenAddress);
    }

    modifier onlyStakingContract() {
        require(msg.sender == stakingContractAddress, "Not authorized");
        _;
    }

    function setStakingContractAddress(address _stakingContractAddress) external {
        require(msg.sender == owner, "Not authorized");
        stakingContractAddress = _stakingContractAddress;
    }

    function transferRewards(uint _amountToRetrieve) onlyStakingContract external {
        dbarToken.transfer(msg.sender, _amountToRetrieve);
    }

}