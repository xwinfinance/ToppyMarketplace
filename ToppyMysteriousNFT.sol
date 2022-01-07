// SPDX-License-Identifier: GPL-3.0

// Amended by HashLips
/**
    !Disclaimer!
    These contracts have been used to create tutorials,
    and was created for the purpose to teach people
    how to create smart contracts on the blockchain.
    please review this code on your own before using any of
    the following code for production.
    HashLips will not be liable in any way if for the use 
    of the code. That being said, the code has been tested 
    to the best of the developers' knowledge to work as intended.
*/

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using SafeMath for uint;
    
  enum PriceType {
      ETHER,
      TOKEN
  }

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.05 ether;
  
  uint256 public platformComm = 500;
  uint256 public creatorComm = 1000;
  uint256 public managerComm = 1000;
  
  address public platformAddress = address(0);
  address public creatorAddress = address(0);
  address public managerAddress = address(0);

  uint256 public maxSupply = 100;
  uint256 public maxMintAmount = 5;
  bool public paused = false;
  string public notRevealedUri;
  mapping(address => bool) public whitelisted;
  mapping(uint => bool) public revealNFT;
  PriceType public priceType = PriceType.ETHER;
  address public tokenPayment = address(0);
  
  event Received(address, uint);
    
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    uint _maxSupply,
    address _platformAddress,
    address _creatorAddress,
    address _managerAddress,
    uint _platformComm,
    uint _creatorComm,
    uint _managerComm
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    maxSupply = _maxSupply;
    platformAddress = _platformAddress;
    creatorAddress = _creatorAddress;
    managerAddress = _managerAddress;
    platformComm = _platformComm;
    creatorComm = _creatorComm;
    managerComm = _managerComm;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    uint totalAmount = cost.mul(_mintAmount);
    
    if(whitelisted[msg.sender] != true) {
      if(priceType == PriceType.ETHER){
        require(msg.value >= totalAmount);
      }else{
        require(IBEP20(tokenPayment).balanceOf(msg.sender) >= totalAmount, "Not enough balance");
        TransferHelper.safeTransferFrom(tokenPayment, msg.sender, address(this), totalAmount);
      }
    }
  
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
      revealNFT[supply + i] = false;
    }
    //make payment
    _payFee(totalAmount);
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
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only nft owner
  function reveal(uint tokenId) public {

      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      require(ownerOf(tokenId) == msg.sender, "you are not owner of nft");
      revealNFT[tokenId] = true;
  }

  //only nft owner
  function revealAll(uint[] calldata tokenIds) public {
      for(uint i=0; i < tokenIds.length; i++){
        if(_exists(tokenIds[i]) && ownerOf(tokenIds[i]) == msg.sender){
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

    uint creatorFee = totalAmount.mul(creatorComm).div(10000);
    uint platformFee = totalAmount.mul(platformComm).div(10000);
    uint managerFee = totalAmount.mul(managerComm).div(10000);

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