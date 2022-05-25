pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
interface ISpecificMintable {
    function SpecificMint(address to,uint id)external;
}
contract unbox{
    address public _box;
    address public _nft;
    constructor(address addr1,address addr2){
        _box = addr1;
        _nft = addr2;
    }
    event Unbox(uint256 boxType,uint256 tokenId,address owner,uint256 heroId);
    
    function unboxe(uint256 boxType,uint256 tokenId)public{
        IERC721(_box).transferFrom(msg.sender,address(this),tokenId);
        ISpecificMintable(_nft).SpecificMint(msg.sender,tokenId);
        emit Unbox(boxType,tokenId,msg.sender,tokenId);
    }


    event OnERC721Received(address,address,uint256,bytes);
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        emit OnERC721Received(operator,from,tokenId,data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}