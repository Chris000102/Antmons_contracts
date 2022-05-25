// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OnOffChain is Ownable {
    using SafeMath for uint256;
    address token0;
    address token1;
    event Deposit(address user, uint256 amount, uint256 time, bool token1Or2);
    event Withdraw(
        address user,
        uint256 amount,
        uint256 time,
        uint256 id,
        bool token1Or2
    );

    function setToken0(address _token) public onlyOwner {
        token0 = _token;
    }

    function setToken1(address _token) public onlyOwner {
        token1 = _token;
    }

    function deposit(uint256 amount, bool token1Or2) public {
        uint256 mo = amount.mul(1e18);
        address token;
        if (token1Or2) {
            token = token0;
        } else {
            token = token1;
        }
        IERC20(token).transferFrom(msg.sender, address(this), mo);
        emit Deposit(msg.sender, amount, block.timestamp, token1Or2);
    }

    function withdraw(
        address[] calldata addrs,
        uint256[] calldata amounts,
        uint256[] calldata ids,
        bool[] calldata token1Or2
    ) public onlyOwner {
        uint256 mo;
        address token;
        for (uint256 index = 0; index < addrs.length; index++) {
            if (token1Or2[index]) {
                token = token0;
            } else {
                token = token1;
            }
            mo = amounts[index].mul(1e18);
            IERC20(token).transfer(addrs[index], mo);
            emit Withdraw(
                addrs[index],
                amounts[index],
                block.timestamp,
                ids[index],
                token1Or2[index]
            );
        }
    }
}
