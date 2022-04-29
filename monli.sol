pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract monli is ERC20{
    constructor()ERC20("MONLI","MONLI"){
        _mint(_msgSender(),1e26);
    }
}