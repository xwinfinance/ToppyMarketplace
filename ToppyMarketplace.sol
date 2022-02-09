pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ToppyMasterSetting.sol";
import "./ToppyMint.sol";
import "./TransferHelper.sol";
import "./ToppySupportPayment.sol";


contract ToppyMarketPlace is Ownable{

    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Offer {
        bytes32 key;
        uint offerPrice; // wei
        address buyer;
        address tokenPayment;
        PriceType priceType;
        uint bidAt; // time
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

    mapping (bytes32 => Offer) public highestOffer;
    mapping (bytes32 => Listing) internal tokenIdToListing;
    mapping (address => EnumerableSet.Bytes32Set) private nftsForSaleByAddress;
    mapping (address => EnumerableSet.Bytes32Set) private nftsForSaleIds;
    mapping (address => Offer[]) private pendingWithdrawals;

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
    event AuctionOffer(bytes32 key, uint listingId, address nftContract, uint256 tokenId, uint256 totalPrice, address owner, address offeror, address previousBidder, address tokenPayment);

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
        Listing memory listing_ = tokenIdToListing[_key];
        Offer memory highestOff = highestOffer[listing_.key];
        
        require(nftsForSaleIds[address(this)].contains(listing_.key), "Trying to extend listing which is not listed yet!");        
        require(ERC721(listing_.nftContract).ownerOf(listing_.tokenId) == msg.sender, "you are not owner of nft");
        require(_isAuctionExpired(listing_.startedAt, listing_.duration), "cannot extend before it expires");
        require(highestOff.buyer == address(0), "cannot extend if there is bidder");

        tokenIdToListing[_key].startedAt = uint(block.timestamp);      
        
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

    function createBulkListing(
        ListingParams memory _listingParams,
        uint [] calldata tokenIds) public {
    
        // check storage requirements
        require(_listingParams.listingPrice > 0 && _listingParams.listingPrice < 340282366920938463463374607431768211455, "invalid listing price"); // 128 bits
        require(_listingParams.endingPrice < 340282366920938463463374607431768211455, "invalid endingPrice"); // 128 bits
        require(_listingParams.duration <= 18446744073709551615, "invalid duration"); // 64 bits
        require(supportPayment.isEligibleToken(_listingParams.tokenPayment), "currency not support");
        if(_listingParams.listingType != ListingType.Fix) require(_listingParams.duration >= 1 minutes);
        if(_listingParams.listingType == ListingType.Dutch) require(_listingParams.endingPrice < _listingParams.listingPrice, "ending price should less than starting price");

        for (uint i = 0; i < tokenIds.length; i++) {
            require(ERC721(_listingParams.nftContract).ownerOf(tokenIds[i]) == msg.sender, "you are not owner of nft");
            _createListing(_listingParams, tokenIds[i]);
        } 
    }

    function createListing(ListingParams memory _listingParams) public {
        
        require(_listingParams.listingPrice > 0 && _listingParams.listingPrice < 340282366920938463463374607431768211455, "invalid listing price"); // 128 bits
        require(_listingParams.endingPrice < 340282366920938463463374607431768211455, "invalid endingPrice"); // 128 bits
        require(_listingParams.duration <= 18446744073709551615, "invalid duration"); // 64 bits
        require(supportPayment.isEligibleToken(_listingParams.tokenPayment), "currency not support");
        require(ERC721(_listingParams.nftContract).ownerOf(_listingParams.tokenId) == msg.sender, "you are not owner of nft");
    
        if(_listingParams.listingType != ListingType.Fix) require(_listingParams.duration >= 1 minutes);
        if(_listingParams.listingType == ListingType.Dutch) require(_listingParams.endingPrice < _listingParams.listingPrice, "ending price should less than starting price");

        _createListing(_listingParams, _listingParams.tokenId);
    }

    function _createListing(ListingParams memory _listingParams, uint _tokenId) internal {

        bytes32 key = _getId(_listingParams.nftContract, _tokenId);
        Listing memory listing = Listing(
            key,
            _listingParams.listingType,
            uint(listingId),
            msg.sender,
            _tokenId,
            uint(_listingParams.listingPrice),
            uint(_listingParams.endingPrice),
            uint(_listingParams.duration),
            uint(block.timestamp),
            _listingParams.tokenPayment,
            _listingParams.priceType,
            _listingParams.nftContract
        );

        tokenIdToListing[key] = listing;
        nftsForSaleIds[address(this)].add(key);
        nftsForSaleByAddress[msg.sender].add(key);
        nftsForSaleByAddress[_listingParams.nftContract].add(key);
            
        emit ListingCreated(
            key, 
            msg.sender, 
            listingId, 
            _listingParams.nftContract, 
            _tokenId, 
            _listingParams.listingType, 
            _listingParams.listingPrice, 
            _listingParams.endingPrice, 
            _listingParams.duration,
            _listingParams.tokenPayment
            );
  
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
        require(listing_.startedAt > 0, "This key does not have a Listing");
        return listing_;
    }

    function cancelListingByKey(bytes32 _key) public {
      
        Listing memory _listing = tokenIdToListing[_key];

        require(_listing.startedAt > 0);
        require(nftsForSaleIds[address(this)].contains(_listing.key), "Trying to unlist an NFT which is not listed yet!");
        require(ERC721(_listing.nftContract).ownerOf(_listing.tokenId) == msg.sender, "you are not owner of nft");

        delete tokenIdToListing[_listing.key];
        nftsForSaleIds[address(this)].remove(_listing.key);
        nftsForSaleByAddress[msg.sender].remove(_listing.key);
        nftsForSaleByAddress[_listing.nftContract].remove(_listing.key);
        _cancelEnglishOffer(_listing);
        emit ListingCancelled(_listing.key, msg.sender, _listing.id, _listing.nftContract, _listing.tokenId, _listing.tokenPayment);
    }

    function _cancelEnglishOffer(Listing memory _listing) internal {
        if(_listing.listingType == ListingType.English){
            Offer memory highestOff = highestOffer[_listing.key];
            pendingWithdrawals[highestOff.buyer].push(highestOff);
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
        
        Offer memory highestOff = highestOffer[listing_.key];
        
        address ownerNFT = ERC721(listing_.nftContract).ownerOf(listing_.tokenId);
        _handlePayment(listing_, highestOff.offerPrice, ownerNFT);

        ERC721(listing_.nftContract).transferFrom(ownerNFT, highestOff.buyer, listing_.tokenId);
        delete tokenIdToListing[listing_.key];
        delete highestOffer[listing_.key];
        nftsForSaleIds[address(this)].remove(listing_.key);
        nftsForSaleByAddress[listing_.seller].remove(listing_.key);
        nftsForSaleByAddress[listing_.nftContract].remove(listing_.key);
        emit ListingSuccessful(listing_.key, listing_.id, listing_.nftContract, listing_.tokenId, highestOff.offerPrice, ownerNFT, highestOff.buyer, listing_.tokenPayment);
    }

    function offer(bytes32 _key, uint256 _amount) public payable {
        Listing memory listing_ = tokenIdToListing[_key];
        require(listing_.startedAt > 0);
        require(ERC721(listing_.nftContract).ownerOf(listing_.tokenId) != msg.sender, "Owner cannot make offer to own nft");

        // check if expired
        require(!_isAuctionExpired(listing_.startedAt, listing_.duration), "Expired. no more offer");
        uint secondsPassed = block.timestamp - listing_.startedAt;

        Offer memory prevOffer = highestOffer[_key];
        require(_amount > prevOffer.offerPrice, "Offer less than highest offer");
        require(_amount > listing_.listingPrice, "Offer less than starting price");

        if (listing_.priceType == PriceType.TOKEN) {
            TransferHelper.safeTransferFrom(listing_.tokenPayment, msg.sender, address(this), _amount);
        }
        else { 
            require(msg.value >= _amount, "Not enough balance");
        }

        Offer memory newHighest;
        newHighest.offerPrice = _amount;
        newHighest.buyer = msg.sender;
        newHighest.key = listing_.key;
        newHighest.priceType = listing_.priceType;
        newHighest.tokenPayment = listing_.tokenPayment;
        newHighest.bidAt = uint(block.timestamp);

        highestOffer[_key] = newHighest;

        // set up pending withdraw for refund
        if (prevOffer.offerPrice > 0) {
            pendingWithdrawals[prevOffer.buyer].push(prevOffer);
        }

        // extend bidding period for another 10 minutes if remaining time less than 10 mins
        uint remainingTiming = (listing_.duration - secondsPassed);
        if (remainingTiming < masterSetting.durationExtension()) {
            tokenIdToListing[_key].duration = listing_.duration + masterSetting.durationExtension() - remainingTiming;
        }

        emit AuctionOffer(listing_.key, listing_.id, listing_.nftContract, listing_.tokenId, _amount, listing_.seller, msg.sender, prevOffer.buyer, listing_.tokenPayment);
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
        nftsForSaleIds[address(this)].remove(listing_.key);
        nftsForSaleByAddress[listing_.seller].remove(listing_.key);
        nftsForSaleByAddress[listing_.nftContract].remove(listing_.key);
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

    function isAuctionExpired(bytes32 _key) public view returns (bool) {
        Listing memory listing_ = tokenIdToListing[_key];
        if(!nftsForSaleIds[address(this)].contains(listing_.key)) return false;
        return _isAuctionExpired(listing_.startedAt, listing_.duration);
    }

    function _isAuctionExpired(uint _startedAt, uint _duration) internal view returns (bool) {     
        uint secondsPassed = block.timestamp - _startedAt;
        return secondsPassed > _duration;
    }

    function getPendingWithdraws(address _user) public view returns (Offer[] memory) {
        return pendingWithdrawals[_user];
    }

    // Not sure if should implement like this or use msg.sender instead
    function withdrawRefunds() public {
        Offer[] memory pending = pendingWithdrawals[msg.sender];
        delete pendingWithdrawals[msg.sender];
        for (uint256 i; i < pending.length; i++) {
            if (pending[i].priceType == PriceType.ETHER) {
                TransferHelper.safeTransferBNB(msg.sender, pending[i].offerPrice);
            } else {
                TransferHelper.safeTransfer(pending[i].tokenPayment, msg.sender, pending[i].offerPrice);
            }
        }
    }
}
