// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ToppyMint.sol";
import "./TransferHelper.sol";
import "./IBEP20.sol";

library ToppyUtils {
    function toHex16 (bytes16 data) internal pure returns (bytes32 result) {
        result = bytes32 (data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
              (bytes32 (data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
        result = result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
              (result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
        result = result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
              (result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
        result = result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
              (result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
        result = (result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
              (result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
        result = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
              uint256 (result) +
              (uint256 (result) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
              0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 39);
    }

  function toHex (bytes32 data) public pure returns (string memory) {
      return string (abi.encodePacked ("0x", toHex16 (bytes16 (data)), toHex16 (bytes16 (data << 128))));
  }
}

contract ToppyMysteriousNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;
    
  enum PriceType {
      ETHER,
      TOKEN
  }

  event Minted(bytes32 key, address from, address nftContract, uint tokenId, string cid);
  
  string public baseURI;
  string public baseExtension = ".json";
  string public rarityURI;
  string public notRevealedUri;
  uint256 public cost = 0.05 ether;
  
  //default fee structure
  uint256 public platformComm = 1000;
  uint256 public creatorComm = 7000;
  uint256 public managerComm = 2000;
  
  address public platformAddress = address(0);
  address public creatorAddress = address(0);
  address public managerAddress = address(0);
  address public tokenPayment = address(0);

  uint256 public maxSupply = 100;
  uint256 public maxMintAmount = 10;
  bool public paused = false;
  mapping(address => bool) public whitelisted;
  mapping(uint => bool) public revealNFT;
  PriceType public priceType = PriceType.ETHER;
  ToppyMint toppyMint = ToppyMint(address(0x762AdB198269b856D403B9B1dc3bB7dACEa9fD0C));
    
  event Received(address, uint);
    
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    uint _maxSupply,
    address _platformAddress,
    address _creatorAddress,
    address _managerAddress
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    maxSupply = _maxSupply;
    platformAddress = _platformAddress;
    creatorAddress = _creatorAddress;
    managerAddress = _managerAddress;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "temporary out of service");
    require(_mintAmount > 0, "must be greater than 0");
    require(_mintAmount <= maxMintAmount, "cannot mint more than setting at single time");
    require(supply + _mintAmount <= maxSupply, "cannot mint more than maxsupply");

    uint totalAmount = cost * _mintAmount;
    
    if(whitelisted[msg.sender] != true) {
      if(priceType == PriceType.ETHER){
        require(msg.value >= totalAmount);
      }else{
        require(IBEP20(tokenPayment).balanceOf(msg.sender) >= totalAmount, "Not enough balance");
        TransferHelper.safeTransferFrom(tokenPayment, msg.sender, address(this), totalAmount);
      }
    }
  
    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint _tokenId = supply + i;
      _safeMint(_to, _tokenId);
      revealNFT[_tokenId] = false;
      bytes32 key = _getId(address(this), _tokenId);
      toppyMint.setCreator(creatorAddress, _tokenId, address(this));
      emit Minted(key, msg.sender, address(0), _tokenId, "");
    }
    //make payment
    _payFee(totalAmount);
  }

  function _getId(address _contract, uint _tokenId) internal pure returns(bytes32) {
    bytes32 bAddress = bytes32(uint256(uint160(_contract)));
    bytes32 bTokenId = bytes32(_tokenId);
    return keccak256(abi.encodePacked(bAddress, bTokenId));
  }

  function getProperties() public view returns (
    string memory, string memory, uint, uint, uint, string memory){
    return (symbol(), name(), totalSupply(), maxSupply, cost, rarityURI);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory){
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealNFT[tokenId] == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();    
    string memory key = ToppyUtils.toHex(_getId(address(this), tokenId));

    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, key, baseExtension))
        : "";
  }

  //only nft owner
  function reveal(uint tokenId) public {

      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      require(ownerOf(tokenId) == msg.sender, "you are not owner of nft");
      require(revealNFT[tokenId] == false, "already been revealed");
      revealNFT[tokenId] = true;
  }

  //only nft owner
  function revealAll(uint[] calldata tokenIds) public {
      for(uint i=0; i < tokenIds.length; i++){
        if(_exists(tokenIds[i]) && ownerOf(tokenIds[i]) == msg.sender && revealNFT[tokenIds[i]] == false){
          revealNFT[tokenIds[i]] = true;
        }
      }
  }

  function setFeeProperties(uint256 _newCost, uint256 _managerComm, uint256 _platformComm, uint256 _creatorComm) public onlyOwner {
    cost = _newCost;
    managerComm = _managerComm;
    platformComm = _platformComm;
    creatorComm = _creatorComm;
  }

  function setPaymentMethod(address _tokenPayment, PriceType _priceType) public onlyOwner {
    tokenPayment = _tokenPayment;
    priceType = _priceType;
  }

  function setMaxSupply(uint _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setAddressProperties(address _platformAddress, address _managerAddress, address _creatorAddress) public onlyOwner {
    platformAddress = _platformAddress;
    creatorAddress = _creatorAddress;
    managerAddress = _managerAddress;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setRarityURI(string memory _newRarityURI) public onlyOwner {
    rarityURI = _newRarityURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
 function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function withdrawAll() public onlyOwner {

    uint totalAmount = 0;
    if (priceType == PriceType.ETHER) totalAmount = address(this).balance;
    else totalAmount = IBEP20(tokenPayment).balanceOf(address(this));
    
    require(totalAmount > 0, "no balance to withdraw");
    _payFee(totalAmount);
  }

  function _payFee(uint totalAmount) internal {

    uint creatorFee = totalAmount * creatorComm / 10000;
    uint platformFee = totalAmount * platformComm / 10000;
    uint managerFee = totalAmount * managerComm / 10000;

    if (priceType == PriceType.ETHER) {
      TransferHelper.safeTransferBNB(creatorAddress, creatorFee);
      TransferHelper.safeTransferBNB(platformAddress, platformFee);
      TransferHelper.safeTransferBNB(managerAddress, managerFee);
    }else{
      TransferHelper.safeTransfer(tokenPayment, creatorAddress, creatorFee);
      TransferHelper.safeTransfer(tokenPayment, platformAddress, platformFee);
      TransferHelper.safeTransfer(tokenPayment, managerAddress, managerFee);
    }
  }
}