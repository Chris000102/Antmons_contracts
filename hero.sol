pragma solidity ^0.8.4;
import "./lib/nftBase.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract hero is antmonsBase{
    using SafeMath for uint;
    constructor()ERC721("Antmons NFT","Antmons NFT"){
        _grantRole(DEFAULT_ADMIN_ROLE,_msgSender());
        _grantRole(MINT_ROLE,_msgSender());
    }

    function SpecificMint(address to,uint id)public onlyRole(MINT_ROLE){
        require(totalSupply().add(1)<=10000,"EXCEED MINT LIMIT");
        specificMint(to,id);
    }
}