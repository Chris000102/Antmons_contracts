pragma solidity ^0.7.6;
pragma abicoder v2;
import "@openzeppelin/contracts@3.4.2/math/SafeMath.sol";
import "@openzeppelin/contracts@3.4.2/utils/Address.sol";
import "@openzeppelin/contracts@3.4.2/token/ERC20/IERC20.sol";
import "./lib/MarketplaceStorage.sol";
import "./commons/Ownable.sol";
import "./commons/Pausable.sol";
import "./commons/ContextMixin.sol";
import "./commons/NativeMetaTransaction.sol";


contract BidSign is EIP712Base {
    bytes32 private constant BidSign_TYPEHASH = keccak256(
        bytes(
            "BidSign(address bider,address nftAddress,uint256 tokenId,uint256 price,bytes32 orderId)"
        )
    );

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct BidSignature {
        address bider;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        bytes32 orderId;
    }

    function hashBidSignature(BidSignature memory bidSig)
        internal
        pure
        returns (bytes32)
    {//address bider,address nftAddress,uint256 tokenId,uint256 price,bytes32 orderId
        return
            keccak256(
                abi.encode(
                    BidSign_TYPEHASH,
                    bidSig.bider,
                    bidSig.nftAddress,
                    bidSig.tokenId,
                    bidSig.price,
                    bidSig.orderId
                )
            );
    }

    // function cry(BidSignature calldata bidSig)public view returns(bytes32){
    //     return toTypedMessageHash(hashBidSignature(bidSig));
    // }
    function verify(
        BidSignature memory bidSig,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        address signer = bidSig.bider;
        require(signer != address(0), "NMT#verify: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashBidSignature(bidSig)),
                sigV,
                sigR,
                sigS
            );
    }
}


pragma solidity ^0.7.6;

/// @title 市场合约
contract Marketplace is Ownable, Pausable, MarketplaceStorage, BidSign {
  using SafeMath for uint256;
  using Address for address;
    mapping(address=>bool) _validNFT;

  constructor (
    address acceptedToken,
    address _owner
  )
  {
    // EIP712 init
    _initializeEIP712('Antmons Marketplace', '1');

    require(_owner != address(0), "Invalid owner");
    transferOwnership(_owner);

    require(acceptedToken.isContract()|| acceptedToken == address(0x0), "The accepted token address must be a deployed contract");
    _acceptedToken[acceptedToken] = true;
    _acceptedToken[address(0x0)] = true;

  }



  function setValidNFT(address nftAddress,bool valid)onlyOwner public{
      _validNFT[nftAddress]=valid;
  }

  function setValidToken(address tokenAddress)onlyOwner public{
      _acceptedToken[tokenAddress] = true;
  }

  function setPublicationFee(uint256 _publicationFee) external onlyOwner {
    publicationFeeInWei = _publicationFee;
    emit ChangedPublicationFee(publicationFeeInWei);
  }


  function setOwnerCutPerMillion(uint256 _ownerCutPerMillion) external onlyOwner {
    require(_ownerCutPerMillion < 1000000, "The owner cut should be between 0 and 999,999");

    ownerCutPerMillion = _ownerCutPerMillion;
    emit ChangedOwnerCutPerMillion(ownerCutPerMillion);
  }



  /// @notice 创建一个新的交易
  /// @param nftAddress NFT合约地址
  /// @param assetId ID NFT资产ID
  /// @param acceptedToken 交易使用的token
  /// @param priceInWei NFT资产价格，单位为wei 需要 18*0
  /// @param expiresAt NFT出售到期时间时间戳
  /// @param listAt NFT出售上架时间时间戳
  /// @param dealType 交易类型 1 定价交易 2 拍卖

  

  function createOrder(
    address nftAddress,
    uint256 assetId,
    address acceptedToken,
    uint256 priceInWei,
    uint256 expiresAt,
    uint256 listAt,
    uint256 dealType
  )
    public
    whenNotPaused
  {
    _createOrder(
      nftAddress,
      assetId,
      acceptedToken,
      priceInWei,
      expiresAt,
      listAt,
      dealType
    );
  }



  /**
    * @dev 取消一个交易
    * @param nftAddress NFT合约地址
    * @param assetId NFT资产ID
    */
  function cancelOrder(address nftAddress, uint256 assetId) public whenNotPaused {
    _cancelOrder(nftAddress, assetId);
  }




  /**
    * @dev 购买定价NFT
    * @param nftAddress NFT合约地址
    * @param assetId NFT资产ID
    * @param price 购买价格
    */
  function safeExecuteOrder(
    address nftAddress,
    uint256 assetId,
    uint256 price
  )
   public payable
   whenNotPaused
  {
    _executeOrder(
      nftAddress,
      _msgSender(),
      assetId,
      price
    );
  }

  function executeBidOrder(BidSignature memory bidSig,bytes32 sigR,bytes32 sigS,uint8 sigV)public whenNotPaused onlyOwner{
      verify(bidSig,sigR,sigS,sigV);
      Order memory order = orderByAssetId[bidSig.nftAddress][bidSig.tokenId];
      require(order.id == bidSig.orderId,"orderId not match");
      _executeOrder(
      bidSig.nftAddress,
      bidSig.bider,
      bidSig.tokenId,
      bidSig.price
    );
  }


  function auctionByAssetId(
    address nftAddress,
    uint256 assetId
  )
    public
    view
    returns
    (bytes32, address, uint256, uint256)
  {
    Order memory order = orderByAssetId[nftAddress][assetId];
    return (order.id, order.seller, order.price, order.expiresAt);
  }


  function _createOrder(
    address nftAddress,
    uint256 assetId,
    address acceptedToken,
    uint256 priceInWei,
    uint256 expiresAt,
    uint256 listAt,
    uint256 dealType
  )
    internal
  {
    _requireERC721(nftAddress);
    _requireValidNFT(nftAddress);
    require(_acceptedToken[acceptedToken],"INVALID ACCEPTED TOKEN");

    ERC721Interface nftRegistry = ERC721Interface(nftAddress);

    //todo transfer nft to address(this) 
    address assetOwner = nftRegistry.ownerOf(assetId);
    address sender = assetOwner;
    
    require(
      nftRegistry.getApproved(assetId) == address(this) || nftRegistry.isApprovedForAll(assetOwner, address(this)),
      "The contract is not authorized to manage the asset"
    );

    nftRegistry.safeTransferFrom(sender,address(this),assetId);

    //----------------------------------

    require(priceInWei > 0, "Price should be bigger than 0");
    require(expiresAt > block.timestamp.add(1 minutes), "Publication should be more than 1 minute in the future");

    bytes32 orderId = keccak256(
      abi.encodePacked(
        block.timestamp,
        assetOwner,
        assetId,
        nftAddress,
        priceInWei
      )
    );

    orderByAssetId[nftAddress][assetId] = Order({
      id: orderId,
      seller: assetOwner,
      nftAddress: nftAddress,
      acceptedToken:acceptedToken,
      price: priceInWei,
      expiresAt: expiresAt,
      listAt: listAt,
      dealType: dealType
    });

    // Check if there's a publication fee and
    // transfer the amount to marketplace owner
    if (publicationFeeInWei > 0) {
      require(
        IERC20(acceptedToken).transferFrom(sender, owner(), publicationFeeInWei),
        "Transfering the publication fee to the Marketplace owner failed"
      );
    }

    emit OrderCreated(
      orderId,
      assetId,
      assetOwner,
      nftAddress,
      acceptedToken,
      priceInWei,
      expiresAt,
      listAt,
      dealType
    );
  }


  function _cancelOrder(address nftAddress, uint256 assetId) internal returns (Order memory) {
    address sender = _msgSender();
    Order memory order = orderByAssetId[nftAddress][assetId];

    //todo asset to seller
    require(order.id != 0, "Asset not published");
    require(order.seller == sender || sender == owner(), "Unauthorized user");
    ERC721Interface(nftAddress).safeTransferFrom(address(this),order.seller,assetId);
    //------------------------------
    bytes32 orderId = order.id;
    address orderSeller = order.seller;
    address orderNftAddress = order.nftAddress;
    uint256 orderKind = order.dealType;
    delete orderByAssetId[nftAddress][assetId];

    emit OrderCancelled(
      orderId,
      assetId,
      orderSeller,
      orderNftAddress,
      orderKind,
      block.timestamp
    );

    return order;
  }


  function _executeOrder(
    address nftAddress,
    address sender,
    uint256 assetId,
    uint256 price
  )
   internal returns (Order memory)
  {
    _requireERC721(nftAddress);


    
    Order memory order = orderByAssetId[nftAddress][assetId];
    require(order.id != 0, "Asset not published");

    address seller = order.seller;

    require(seller != address(0), "Invalid address");
    require(seller != sender, "Unauthorized user");
    require(block.timestamp >= order.listAt, "Unlisted item");
    
    uint256 dealType = order.dealType;
    address tokenFrom;
    if (dealType == 1){
        tokenFrom = _msgSender();
        require(sender == _msgSender(), "not a bid deal");
        require(order.price == price, "The price is not correct");
    }

    if (dealType == 2){
        tokenFrom = sender;
        require(_msgSender() == owner(),"only admin can make bid deal");
        require(price > order.price,"The price is not correct");
    }
    
    require(block.timestamp < order.expiresAt, "The order expired");

    uint saleShareAmount = 0;

    bytes32 orderId = order.id;
    delete orderByAssetId[nftAddress][assetId];


    if(order.acceptedToken == address(0x0)){
      require(msg.value == price,"INSUFFICIENT VALUE");
      if (ownerCutPerMillion > 0) {
        saleShareAmount = price.mul(ownerCutPerMillion).div(1000000);
        payable(address(owner())).transfer(saleShareAmount);
      }
      payable(address(seller)).transfer(price.sub(saleShareAmount));
    }else{
      if (ownerCutPerMillion > 0) {
        // Calculate sale share
        saleShareAmount = price.mul(ownerCutPerMillion).div(1000000);

        // Transfer share amount for marketplace Owner
        require(
          IERC20(order.acceptedToken).transferFrom(tokenFrom, owner(), saleShareAmount),
          "Transfering the cut to the Marketplace owner failed"
        );
      }

      // Transfer sale amount to seller
      require(
        IERC20(order.acceptedToken).transferFrom(tokenFrom, seller, price.sub(saleShareAmount)),
        "Transfering the sale amount to the seller failed"
      );
    }
    

    // Transfer asset owner
    ERC721Interface(nftAddress).safeTransferFrom(
      address(this),
      sender,
      assetId
    );

    emit OrderSuccessful(
      orderId,
      assetId,
      seller,
      nftAddress,
      price,
      sender,
      dealType,
      block.timestamp
    );

    return order;
  }

  function _requireERC721(address nftAddress) internal view {
    require(nftAddress.isContract(), "The NFT Address should be a contract");

    ERC721Interface nftRegistry = ERC721Interface(nftAddress);
    require(
      nftRegistry.supportsInterface(ERC721_Interface),
      "The NFT contract has an invalid ERC721 implementation"
    );
  }

  function _requireValidNFT(address nftAddress)internal view{
      require(_validNFT[nftAddress],"The NFT Address should be valid");
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
