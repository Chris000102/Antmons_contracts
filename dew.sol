pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract dew is ERC20,Ownable{
    constructor()ERC20("DEW","DEW"){
        _mint(_msgSender(),1e26);
    }
    function Mint(address to,uint amount)public onlyOwner{
        _mint(to,amount);
    }
}