pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

library EnumerableSet {

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // BytesSet

    struct BytesSet {
        Set _inner;
    }

    function add(BytesSet storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(BytesSet storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(BytesSet storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(BytesSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(BytesSet storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function values(BytesSet storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

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

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract ToppySupportPayment {
    function isEligibleToken(address _token) public view returns (bool){}
}

contract ToppyMaster {

    function getCalcFeeInfo(address _creatorOwnerAddress, uint baseAmount) public view returns (uint creatorFee, uint platformFee, uint amountAfterFee) {}
    address public platformOwner;
    uint public durationExtension;
}

interface ERC721 {

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    external;

  
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);


  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}

contract ToppyMint {
    mapping (bytes32 => address) public creators;
    mapping (address => bool) public eligibleContracts; 
}

contract ToppyMarketPlace is Ownable{

  using SafeMath for uint;
  using EnumerableSet for EnumerableSet.BytesSet;

    struct Offer {
        uint id;
        address buyer;
        uint offerPrice; // wei
        uint duration; // seconds
    }

    struct ListingParams {
        address nftContract;
        uint tokenId;
        ListingType listingType;
        uint listingPrice;
        uint endingPrice;
        uint duration;
        PriceType priceType;
        address tokenPayment;
    }  
   

  struct Listing {
      bytes32 key;
      ListingType listingType;
      uint id;
      address seller;
      uint tokenId;
      uint listingPrice; // wei
      uint endingPrice; // wei
      uint duration; // seconds
      uint startedAt; // time
      address tokenPayment;
      PriceType priceType;
      address nftContract;
  }
  
  ToppyMint public toppyMint;
  ToppySupportPayment public supportPayment;// = SupportedPayment(address(0xFb0D4DC54231a4D9A1780a8D85100347E6B6C41c));
  ToppyMaster public masterSetting;// = MasterSetting(address(0xFb0D4DC54231a4D9A1780a8D85100347E6B6C41c));
  address public adminExecutor;  //admin executor for accepting the english auction offer     
  uint public listingId = 0; // max is 18446744073709551615
  
  mapping (uint => Offer[]) public offersHistories;
  mapping (bytes32 => Offer) public highestOffer;
  mapping (bytes32 => Listing) internal tokenIdToListing;
  mapping (address => EnumerableSet.BytesSet) private nftsForSaleByAddress;
  mapping (address => EnumerableSet.BytesSet) private nftsForSaleIds;
    
    enum PriceType {
        ETHER,
        TOKEN
    }
    enum ListingType {
        Fix,
        Dutch,
        English
    }

    modifier onlyAdminExecutor() {
        require(msg.sender == adminExecutor);
        _;
    }

  event ListingCreated(bytes32 key, address from, uint listingId, address nftContract, uint tokenId, ListingType listingType, uint256 startingPrice, uint256 endingPrice, uint256 duration, address tokenPayment);
  event ListingCancelled(bytes32 key, address from, uint listingId, address nftContract, uint tokenId, address tokenPayment);
  event ListingSuccessful(bytes32 key, uint listingId, address nftContract, uint tokenId, uint256 totalPrice, address owner, address buyer, address tokenPayment);
  event AuctionOffer(bytes32 key, uint listingId, address nftContract, uint256 tokenId, uint256 totalPrice, address owner, address offeror, address tokenPayment);
  
  constructor(
        address _supportPayment,
        address _masterSetting,
        address _toppyMint,
        address _adminExecutor
      ) {
        supportPayment = ToppySupportPayment(_supportPayment);
        masterSetting = ToppyMaster(_masterSetting);
        toppyMint = ToppyMint(_toppyMint);
        adminExecutor = _adminExecutor;
  }

    function updateProperties(
        address _supportPayment,
        address _masterSetting,
        address _toppyMint,
        address _adminExecutor
        ) public onlyOwner {
        supportPayment = ToppySupportPayment(_supportPayment);
        masterSetting = ToppyMaster(_masterSetting);
        toppyMint = ToppyMint(_toppyMint);
        adminExecutor = _adminExecutor;
    }

    function getOffersHistories(uint _listingId) public view returns (Offer[] memory) {
        return  offersHistories[_listingId];
    }

    function totalListed() public view returns (uint) {
        return nftsForSaleIds[address(this)].length();
    }

    function totalListedByOwner(address owner) public view returns (uint) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return nftsForSaleByAddress[owner].length();
    }

    function _getId(address _contract, uint _tokenId) internal pure returns(bytes32) {
        bytes32 bAddress = bytes32(uint256(uint160(_contract)));
        bytes32 bTokenId = bytes32(_tokenId);
        return keccak256(abi.encodePacked(bAddress, bTokenId));
    }

    // allow owner to extend the auction without cancelling it and relist it again
    function extendListing(bytes32 _key) public {        
        Listing storage listing_ = tokenIdToListing[_key];
        Offer memory highestOff = highestOffer[listing_.key];
        
        require(nftsForSaleIds[address(this)].contains(listing_.key), "Trying to extend listing which is not listed yet!");        
        require(ERC721(listing_.nftContract).ownerOf(listing_.tokenId) == msg.sender, "you are not owner of nft");
        require(_isAuctionExpired(listing_.startedAt, listing_.duration), "cannot extend before it expires");
        require(highestOff.offerPrice == 0, "cannot extend if there is bidder");
        listing_.startedAt = uint(block.timestamp);      
        emit ListingCreated(
            listing_.key, 
            msg.sender, 
            listing_.id, 
            listing_.nftContract, 
            listing_.tokenId, 
            listing_.listingType, 
            listing_.listingPrice, 
            listing_.endingPrice, 
            listing_.duration,
            listing_.tokenPayment
            );
    }


    function createListing(
        ListingParams memory _listingParams) public {
        
        // check storage requirements
        require(_listingParams.listingPrice > 0 && _listingParams.listingPrice < 340282366920938463463374607431768211455, "invalid listing price"); // 128 bits
        require(_listingParams.endingPrice < 340282366920938463463374607431768211455, "invalid endingPrice"); // 128 bits
        require(_listingParams.duration <= 18446744073709551615, "invalid duration"); // 64 bits
        require(supportPayment.isEligibleToken(_listingParams.tokenPayment), "currency not support");
        require(ERC721(_listingParams.nftContract).ownerOf(_listingParams.tokenId) == msg.sender, "you are not owner of nft");
    
        if(_listingParams.listingType != ListingType.Fix) require(_listingParams.duration >= 1 minutes);
        if(_listingParams.listingType == ListingType.Dutch) require(_listingParams.endingPrice < _listingParams.listingPrice, "ending price should less than starting price");

        bytes32 key = _getId(_listingParams.nftContract, _listingParams.tokenId);

        Listing memory listing = Listing(
            key,
            _listingParams.listingType,
            uint(listingId),
            msg.sender,
            uint(_listingParams.tokenId),
            uint(_listingParams.listingPrice),
            uint(_listingParams.endingPrice),
            uint(_listingParams.duration),
            uint(block.timestamp),
            _listingParams.tokenPayment,
            _listingParams.priceType,
            _listingParams.nftContract
        );

        tokenIdToListing[key] = listing;
        nftsForSaleByAddress[msg.sender].add(key);
        nftsForSaleIds[address(this)].add(key);
            
        emit ListingCreated(
            key, 
            msg.sender, 
            listingId, 
            _listingParams.nftContract, 
            _listingParams.tokenId, 
            _listingParams.listingType, 
            _listingParams.listingPrice, 
            _listingParams.endingPrice, 
            _listingParams.duration,
            _listingParams.tokenPayment
            );
  
        //ERC721(listing_.nftContract).transferFrom(address(this), msg.sender, listing_.tokenId);
        listingId++;
    }

    function getListings(uint startIndex, uint endIndex) public view returns (Listing[] memory _listings) {        
        require(startIndex < endIndex, "Invalid indexes supplied!");
        uint len = endIndex - startIndex;
        require(len <= totalListed(), "Invalid length!");

        _listings = new Listing[](len);
        for (uint i = startIndex; i < endIndex; i++) {
            uint listIndex = i - startIndex;
            // bytes32 key = nftsForSaleIds.at(i);
            bytes32 key = nftsForSaleIds[address(this)].at(i);
            Listing memory listing_ = tokenIdToListing[key];
            _listings[listIndex] = listing_;
        }
        return _listings;
    }
  
    function getListingsBySeller(address seller, uint startIndex, uint endIndex) public view returns (Listing[] memory _listings) {
        require(startIndex < endIndex, "Invalid indexes supplied!");
        uint len = endIndex - startIndex;
        require(len <= totalListedByOwner(seller), "Invalid length!");

        _listings = new Listing[](len);
        for (uint i = startIndex; i < endIndex; i++) {
            uint listIndex = i - startIndex;
            bytes32 key = nftsForSaleByAddress[seller].at(i);
            Listing memory listing_ = tokenIdToListing[key];
            _listings[listIndex] = listing_;
        }
        return _listings;
    }

    function getListingByNFTKey(bytes32 _key) public view returns (Listing memory listing) {
        Listing memory listing_ = tokenIdToListing[_key];
        require(listing_.startedAt > 0);
        return listing_;
    }

    function cancelListingByKey(bytes32 _key) public {
      
      Listing memory _listing = tokenIdToListing[_key];

      require(_listing.startedAt > 0);
      require(nftsForSaleIds[address(this)].contains(_listing.key), "Trying to unlist an NFT which is not listed yet!");
      require(ERC721(_listing.nftContract).ownerOf(_listing.tokenId) == msg.sender, "you are not owner of nft");

      delete tokenIdToListing[_listing.key];
      nftsForSaleByAddress[msg.sender].remove(_listing.key);
      nftsForSaleIds[address(this)].remove(_listing.key);
      _cancelEnglishOffer(_listing);
      emit ListingCancelled(_listing.key, msg.sender, _listing.id, _listing.nftContract, _listing.tokenId, _listing.tokenPayment);
    }

    function _cancelEnglishOffer(Listing memory _listing) internal {
    
        if(_listing.listingType == ListingType.English){
            Offer storage highestOff = highestOffer[_listing.key];
            if (_listing.priceType == PriceType.ETHER) {
                TransferHelper.safeTransferBNB(highestOff.buyer, highestOff.offerPrice);
            }else{
                TransferHelper.safeTransfer(_listing.tokenPayment, highestOff.buyer, highestOff.offerPrice);
            }
            delete highestOffer[_listing.key];
        }      
    }

    function acceptOfferByAdmin(bytes32 _key) public payable onlyAdminExecutor {
      Listing memory listing_ = tokenIdToListing[_key];
      require(listing_.startedAt > 0);
      _acceptOffer(_key);
    }

    function acceptOffer(bytes32 _key) public payable {
      Listing memory listing_ = tokenIdToListing[_key];
      require(listing_.startedAt > 0);
      require(ERC721(listing_.nftContract).ownerOf(listing_.tokenId) == msg.sender, "you are not owner of nft");
      _acceptOffer(_key);
    }

    function _acceptOffer(bytes32 _key) internal {
      
      Listing memory listing_ = tokenIdToListing[_key];
      require(_isAuctionExpired(listing_.startedAt, listing_.duration), "wait until it expires");
      
      Offer storage highestOff = highestOffer[listing_.key];
      
      address ownerNFT = ERC721(listing_.nftContract).ownerOf(listing_.tokenId);
      _handlePayment(listing_, highestOff.offerPrice, ownerNFT);
  
      ERC721(listing_.nftContract).transferFrom(ownerNFT, highestOff.buyer, listing_.tokenId);
      delete tokenIdToListing[listing_.key];
      delete highestOffer[listing_.key];
      nftsForSaleByAddress[listing_.seller].remove(listing_.key);
      emit ListingSuccessful(listing_.key, listing_.id, listing_.nftContract, listing_.tokenId, highestOff.offerPrice, ownerNFT, highestOff.buyer, listing_.tokenPayment);
    }

    function offer(bytes32 _key, uint256 _amount) public payable {
      
      Listing storage listing_ = tokenIdToListing[_key];
      require(listing_.startedAt > 0);
      require(ERC721(listing_.nftContract).ownerOf(listing_.tokenId) != msg.sender, "owner cannot make offer to own nft");

      // check if expired
      require(!_isAuctionExpired(listing_.startedAt, listing_.duration), "expired. no more offer");
      uint secondsPassed = block.timestamp - listing_.startedAt;
      
      uint newDuration = (listing_.duration - secondsPassed) < masterSetting.durationExtension() ? listing_.duration + masterSetting.durationExtension() : listing_.duration;
      Offer storage highestOff = highestOffer[_key];
      require(_amount > highestOff.offerPrice, "offer less than highest offer");

      if(listing_.priceType == PriceType.TOKEN) TransferHelper.safeTransferFrom(listing_.tokenPayment, msg.sender, address(this), _amount);
      else { require (msg.value >= _amount, "not enought balance"); }
      
      address previousBuyer = highestOff.buyer;
      uint previousOfferPrice = highestOff.offerPrice;
      
      highestOff.offerPrice = _amount;
      highestOff.buyer = msg.sender;
      highestOff.id = listing_.id;
      highestOff.duration = newDuration;
      
      offersHistories[listing_.id].push(Offer(listing_.id, msg.sender, _amount, newDuration));
      
      //refund to previous bidder 
      if(previousOfferPrice > 0) listing_.priceType == PriceType.ETHER ? 
            TransferHelper.safeTransferBNB(previousBuyer, previousOfferPrice): 
            TransferHelper.safeTransfer(listing_.tokenPayment, previousBuyer, previousOfferPrice);

      //extend bidding period for another 10 minutes if remaining time less than 10 mins
      listing_.duration = newDuration;
      emit AuctionOffer(listing_.key, listing_.id, listing_.nftContract, listing_.tokenId, _amount, listing_.seller, msg.sender, listing_.tokenPayment);
    }

    /// Used by Fix price and Auction price Buy/Bid
    function bid(bytes32 _key) public payable {

      Listing memory listing_ = tokenIdToListing[_key];
      require(listing_.startedAt > 0);
      uint256 price = getCurrentPrice(listing_);
      require(price > 0, "no price");
      address ownerNFT = ERC721(listing_.nftContract).ownerOf(listing_.tokenId);
      require(ownerNFT != msg.sender, "do not buy own nft");
        
      if(listing_.priceType == PriceType.ETHER) require(msg.value >= price, "not enough balance");  
      else TransferHelper.safeTransferFrom(listing_.tokenPayment, msg.sender, address(this), price);

      uint auctionId_temp = listing_.id;
      
      _handlePayment(listing_, price, ownerNFT);

      ERC721(listing_.nftContract).transferFrom(ownerNFT, msg.sender, listing_.tokenId);
      delete tokenIdToListing[listing_.key];
      nftsForSaleByAddress[msg.sender].remove(listing_.key);
      emit ListingSuccessful(
        listing_.key, 
        auctionId_temp, 
        listing_.nftContract, 
        listing_.tokenId, 
        price, 
        ownerNFT, 
        msg.sender, 
        listing_.tokenPayment);
    }

    function _handlePayment(Listing memory listing_, uint _price, address ownerNFT) internal {

        address creatorOwnerAddress = address(0);
        bool isElig = toppyMint.eligibleContracts(listing_.nftContract);
        if(isElig) creatorOwnerAddress = toppyMint.creators(listing_.key);
        (uint creatorFee, uint fee, uint amountAfterFee) = masterSetting.getCalcFeeInfo(creatorOwnerAddress, _price);

        if (listing_.priceType == PriceType.ETHER) {
            
            if(creatorOwnerAddress != address(0)) TransferHelper.safeTransferBNB(creatorOwnerAddress, creatorFee);
            TransferHelper.safeTransferBNB(masterSetting.platformOwner(), fee);
            TransferHelper.safeTransferBNB(ownerNFT, amountAfterFee);
            
        }else{
            
            if(creatorOwnerAddress != address(0)) TransferHelper.safeTransfer(listing_.tokenPayment, creatorOwnerAddress, creatorFee);
            TransferHelper.safeTransfer(listing_.tokenPayment, masterSetting.platformOwner(), fee);
            TransferHelper.safeTransfer(listing_.tokenPayment, ownerNFT, amountAfterFee);
        }
    }

    function getCurrentPriceByKey(bytes32 _key) public view returns (uint) {
        Listing memory listing_ = tokenIdToListing[_key];
        return getCurrentPrice(listing_);
    }
  
    function getCurrentPrice(Listing memory listing_) internal view returns (uint) {
      
      if(listing_.listingType == ListingType.Fix){
          return listing_.listingPrice;
      }
      if(listing_.listingType == ListingType.Dutch){
          return _getDutchCurrentPrice(listing_);
      }
      if(listing_.listingType == ListingType.English){
          return _getEnglishCurrentPrice(listing_);
      }
      return 0;
    }

    function _getEnglishCurrentPrice(Listing memory listing_) internal view returns (uint) {
        Offer memory highestOff = highestOffer[listing_.key];
        return highestOff.offerPrice == 0 ? listing_.listingPrice : highestOff.offerPrice;
    }

    function _getDutchCurrentPrice(Listing memory listing_) internal view returns (uint) {
        require(listing_.startedAt > 0);
        uint256 secondsPassed = 0;

        secondsPassed = block.timestamp - listing_.startedAt;

        if (secondsPassed >= listing_.duration) {
            return listing_.endingPrice;
        } else {
            int256 totalPriceChange = int256(listing_.endingPrice) - int256(listing_.listingPrice);

            int256 currentPriceChange = totalPriceChange * int256(secondsPassed) / int256(listing_.duration);

            int256 currentPrice = int256(listing_.listingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
     }

     function isAuctionExpired(bytes32 _key) public view returns (bool) 
     {
        Listing memory listing_ = tokenIdToListing[_key];
        if(!nftsForSaleIds[address(this)].contains(listing_.key)) return false;
        return _isAuctionExpired(listing_.startedAt, listing_.duration);
     }

     function _isAuctionExpired(uint _startedAt, uint _duration) internal view returns (bool) 
     {     
        uint secondsPassed = block.timestamp - _startedAt;
        return secondsPassed > _duration;
     }
  
}
