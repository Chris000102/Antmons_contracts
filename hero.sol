pragma solidity ^0.8.4;
import "./lib/nftBase.sol";
contract hero is antmonsBase{
    constructor()ERC721("Antmons NFT","Antmons NFT"){
        _grantRole(DEFAULT_ADMIN_ROLE,_msgSender());
        _grantRole(MINT_ROLE,_msgSender());
    }

    function SpecificMint(address to,uint id)public onlyRole(MINT_ROLE){
        specificMint(to,id);
    }
}