pragma solidity ^0.8.4;
import "./lib/nftBase.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract lootBox is antmonsBase{
    using SafeMath for uint;
    uint public _mintLimit;
    constructor(string memory name,string memory symbol,uint limit)ERC721(name,symbol){//Antmons NFT Normal/Rare/Epic
        _id = 1;
        _grantRole(DEFAULT_ADMIN_ROLE,_msgSender());
        _grantRole(MINT_ROLE,_msgSender());
        _mintLimit = limit;
    }

    function BatchMint(address to,uint amount)public onlyRole(MINT_ROLE){//
        require(totalSupply().add(amount)<=_mintLimit,"EXCEED MINT LIMIT");
        batchMint(to,amount);
    }
}