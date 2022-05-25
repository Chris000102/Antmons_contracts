pragma solidity ^0.8.4;
import "./lib/nftBase.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MintBox is Ownable{
    using SafeMath for uint256;
    address _box;
    uint256 _commonNum;
    uint256 _rareNum;
    uint256 _epicNum;
    mapping (uint256 => uint256) _price;

    constructor(address box,uint256[3] memory price,address newOwner){
        _box = box;
        for(uint index=0;index<3;index++){
            _price[index+1] = price[index];
        }
        _commonNum = 1;
        _rareNum = 1;
        _epicNum = 1;
        transferOwnership(newOwner);
    }

    // #if RELEASE
    function getNum(uint256 boxType)internal view returns(uint256){
        if(boxType==1){
            return _commonNum;
        }
        if(boxType==2){
            return _rareNum;
        }
        if(boxType==3){
            return _epicNum;
        }
    }
    // #else
    function getNum(uint256 boxType)internal view returns(uint256){
        if(boxType==1){
            return _commonNum+20;
        }
        if(boxType==2){
            return _rareNum;
        }
        if(boxType==3){
            return _epicNum;
        }
    }
    // #endif

    function addNum(uint256 boxType,uint256 amount)internal{
        if(boxType==1){
            
            _commonNum = _commonNum.add(amount);
            require(_commonNum<=4001,"EXCEED MINT LIMIT");
        }
        if(boxType==2){
            
            _rareNum = _rareNum.add(amount);
            require(_rareNum<=8001,"EXCEED MINT LIMIT");
        }
        if(boxType==3){
            
            _epicNum = _epicNum.add(amount);
            require(_epicNum<=10001,"EXCEED MINT LIMIT");
        }
    }
    
    function mint(uint256 boxType,uint256 amount)public payable{
        require(msg.value == _price[boxType].mul(amount),"INSUFFICIENT BALANCE");
        
        uint256 start = getNum(boxType);
        for(uint index=0;index<amount;index++){
            IERC721(_box).transferFrom(address(this),msg.sender,start+index);
        }
        addNum(boxType,amount);
    }

    function withdraw(uint256 amount)public onlyOwner{
        payable(msg.sender).transfer(amount);
    }
}