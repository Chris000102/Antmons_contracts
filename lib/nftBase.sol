pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
abstract contract antmonsBase is Ownable,AccessControl,ERC721Enumerable{
    using SafeMath for uint;
    uint _id;
    string public URI_PREFIX;
    bytes32 public constant MINT_ROLE = bytes32(uint(1));
    // constructor()ERC721("",""){
    //     _id = 1;
    //     grantRole(DEFAULT_ADMIN_ROLE,_msgSender());
    //     grantRole(MINT_ROLE,_msgSender());
    // }

    function setPrefix(string memory prefix)public onlyOwner{
        URI_PREFIX = prefix;
    }

    function grantMintRole(address account)public onlyOwner{
        _grantRole(MINT_ROLE, account);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || interfaceId == type(AccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    function specificMint(address to,uint id)internal{
        _mint(to,id);
    }

    function incrementMint(address to)internal{
        _mint(to,_id);
        _id = _id.add(1);
    }

    function batchMint(address to,uint amount)internal{//onlyRole(MINT_ROLE)
        for(uint index=0;index<amount;index++){
            incrementMint(to);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return URI_PREFIX;
    }
}