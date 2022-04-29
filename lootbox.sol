pragma solidity ^0.8.4;
import "./lib/nftBase.sol";
contract lootBox is antmonsBase{
    constructor(string memory name,string memory symbol)ERC721(name,symbol){//Antmons NFT Normal/Rare/Epic
        _id = 1;
        _grantRole(DEFAULT_ADMIN_ROLE,_msgSender());
        _grantRole(MINT_ROLE,_msgSender());
    }

    function BatchMint(address to,uint amount)public onlyRole(MINT_ROLE){//
        batchMint(to,amount);
    }
}