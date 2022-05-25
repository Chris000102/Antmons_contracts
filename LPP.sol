// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import './lib/Ownable.sol';
import './lib/LPTokenWrapper.sol';

interface IToken {
    function mint(address addr, uint256 amount) external;

    function approve(address spender, uint256 amount) external returns (bool);
}

contract LPPool is LPTokenWrapper, Ownable {

    IToken public _rewardToken;
    uint256 public _reward;
    address public _team;
    uint256 public constant DURATION = 1 days;

    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardChanged(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    function initialize(
        address rewardToken,
        uint reward,
        address lpt,
        address team
    ) public onlyOwner{
        require(rewardToken!=lpt,'');
        _rewardToken = IToken(rewardToken);
        _reward = reward;
        _lpt = IERC20(lpt);
        _team = team;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        uint nowTime = block.timestamp;
        uint rewardRate = _reward.div(DURATION);
        return
        rewardPerTokenStored.add(
            nowTime
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(1e18)
            .div(totalSupply())
        );
    }

    /// @notice User reward 
    /// @param account User address

    function earned(address account) public view returns (uint256) {
        return
        balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
    }

    /// @notice Token or LP stake
    /// @param amount Token amount

    function stake(uint256 amount) public updateReward(msg.sender){
        require(amount > 0, 'Cannot stake 0');
        super._stake(amount);
        emit Staked(msg.sender, amount);
    }

    /// @notice Token or LP withdraw
    /// @param amount Token withdraw

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, 'Cannot withdraw 0');
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Token or LP withdraw getreward

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    /// @notice Only getreward

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            uint256 income = reward.mul(7).div(100);
            _rewardToken.mint(msg.sender, reward.sub(income));
            _rewardToken.mint(_team, income);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function changeReward(uint reward) external onlyOwner updateReward(address(0)) {
        _reward = reward;
        emit RewardChanged(reward);
    }

}
