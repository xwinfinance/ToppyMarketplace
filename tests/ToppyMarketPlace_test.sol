//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../contracts/ToppyMarketplace.sol";
import "../contracts/ToppyStandardNFT.sol";
import "../contracts/ToppyMint.sol";

// File name has to end with'_test.sol', this file can contain more than one testSuite contracts
/// Inherit 'ToppyMysteriousNFT' contract
contract ToppyMarketPlaceTest is ToppyMarketPlace, ToppyStandardNFT("ToppyTestNFT", "TTN", "ipfs://") {

    // Variables used to emulate different accounts
    address acc0;
    address acc1;
    address acc2;
    address acc3;
    address acc4;
    bytes32 bidKey = _getId(address(this), 1);
    bytes32 englishKey = _getId(address(this), 4);

    address _TsupportPayment;
    address _TtoppyMint;
    address _TmasterSetting;

    ///'beforeAll' runs before all other tests
    /// More special functions are :'beforeEach','beforeAll','afterEach' &'afterAll'
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
        ToppyMaster master = new ToppyMaster();
        ToppySupportPayment support = new ToppySupportPayment();
        _TmasterSetting = address(master);
        _TsupportPayment = address(support);
        ToppyMint minter = new ToppyMint(_TmasterSetting);
        _TtoppyMint = address(minter);

        updateProperties(_TsupportPayment, _TmasterSetting, _TtoppyMint, acc0);
        address[] memory a = new address[](1);
        bool[] memory b = new bool[](1);
        a[0] = address(0);
        b[0] = true;
        support.addSupportedPayments(a, b);

        setEligibleMinters(acc0, true);
        setEligibleMinters(acc1, true);
        setEligibleMinters(acc2, true);
        setEligibleMinters(acc3, true);
        setEligibleMinters(acc4, true);
        pause(false);
    }

    constructor() ToppyMarketPlace(
        _TsupportPayment,
        _TmasterSetting,
        _TtoppyMint,
        acc0) {
    }

    /// Manager a.k.a contract owner/creator
    /// Account at zero index(account-0) is default account , so manager will be set to acc0
    function checkExecutorAddress() public {
        Assert.equal(adminExecutor, acc0 , "unknown executor");
    }

    function updatePropertiesCheck() public {
        Assert.notEqual(address(toppyMint) , address(0) , "mint not initialised");
        Assert.notEqual(address(supportPayment), address(0), "supportPayment not initialised");
        Assert.notEqual(address(masterSetting), address(0), "master not initialised");
    }

    /// #sender: account-0
    function addListing() public {
        // mint nft
        uint tokenId = mint(acc0, "testcid");
        Assert.equal(tokenId, 1,"impossible");

        // create listing object
        ListingParams memory listingObj;
        listingObj.nftContract = address(this);
        listingObj.tokenId = tokenId;
        listingObj.listingType = ListingType.Fix;
        listingObj.listingPrice = 100;
        listingObj.duration = 61;
        listingObj.priceType = PriceType.ETHER;

        // get id
        bytes32 testKey = _getId(address(this), 1);

        Assert.equal(listingId, 0, "listing id not 0");
        // add listing
        ERC721.approve(address(this), tokenId);
        createListing(listingObj);
        // get listing
        Listing memory testListing = getListingByNFTKey(testKey);

        // check
        Assert.equal(testListing.id, 0, "listing id not 0");
        Assert.equal(testListing.tokenId, 1, "token id not 1");
        Assert.equal(testListing.seller, acc0, "listing owner mismatch");
        Assert.equal(testListing.nftContract, address(this), "listing contract address mismatch");
        Assert.equal(uint(testListing.listingType), 0, "listing type mismatch");
        Assert.equal(testListing.listingPrice, 100, "listing price mismatch");
        Assert.equal(testListing.duration, 61, "listing duration mismatch");
        Assert.equal(uint(testListing.priceType), 0, "listing price type mismatch");
        Assert.equal(isAuctionExpired(testKey), false, "listing expired");
    }

    /// #value: 100
    /// #sender: account-1
    function buyListing() public payable{
        Assert.equal(totalListed(), 1, "total NFTs listed in the marketplace should be 1");
        // purchase the Fix listing
        bid(bidKey);
        Assert.equal(totalListed(), 0, "total NFTs listed in the marketplace should be 0 after bid");
        Assert.equal(this.ownerOf(1), acc1, "NFT not transferred");
        // listing should no longer exist
        try this.getListingByNFTKey(bidKey) {
            Assert.ok(false, "get listing after successful bid should fail");
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, "This key does not have a Listing", "Wrong Error message");
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, "failed without reason");
        }
    }

    /// #sender: account-0
    function addAndRemoveListing() public {
        // mint nft
        uint tokenId = mint(acc0, "testcid");
        Assert.equal(tokenId, 2,"NFT token id unexpected");

        // create listing object
        ListingParams memory listingObj;
        listingObj.nftContract = address(this);
        listingObj.tokenId = tokenId;
        listingObj.listingType = ListingType.Fix;
        listingObj.listingPrice = 10 ** 15;
        listingObj.duration = 61;
        listingObj.priceType = PriceType.ETHER;

        // get id
        bytes32 testKey = _getId(address(this), tokenId);

        Assert.equal(listingId, 1, "listing id not 1");
        // add listing
        createListing(listingObj);

        // get listing
        Listing memory testListing = getListingByNFTKey(testKey);

        // check
        Assert.equal(testListing.id, 1, "listing id not 1");
        Assert.equal(testListing.tokenId, 2, "token id not 2");
        Assert.equal(testListing.seller, acc0, "listing owner mismatch");
        Assert.equal(isAuctionExpired(testKey), false, "Auction expired");

        // cancel listing
        cancelListingByKey(testKey);

        // check if deleted
        try this.getListingByNFTKey(testKey) {
            Assert.ok(false, "method execution should fail");
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, "This key does not have a Listing", "Wrong Error message");
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, "failed without reason");
        }
    }

    /// #sender: account-0
    function addDutchAndEnglishListing() public {
        // mint nft
        uint tokenId = mint(acc0, "testcidDutch");
        uint tokenId2 = mint(acc0, "testcidEnglish");
        Assert.equal(tokenId, 3, "NFT token id unexpected");
        Assert.equal(tokenId2, 4, "NFT token id unexpected");

        // create listing object
        ListingParams memory listingObj;
        listingObj.nftContract = address(this);
        listingObj.tokenId = tokenId;
        listingObj.listingType = ListingType.Dutch;
        listingObj.listingPrice = 100;
        listingObj.endingPrice = 10;
        listingObj.duration = 600;
        listingObj.priceType = PriceType.ETHER;

        ListingParams memory listingObj2;
        listingObj2.nftContract = address(this);
        listingObj2.tokenId = tokenId2;
        listingObj2.listingType = ListingType.English;
        listingObj2.listingPrice = 100;
        listingObj2.duration = 600;
        listingObj2.priceType = PriceType.ETHER;

        Assert.equal(totalListed(), 0, "total listed not 0");
        Assert.equal(totalListedByOwner(acc0), 0, "total listed by acc0 not 0");

        // add listing
        ERC721.approve(address(this), tokenId);
        ERC721.approve(address(this), tokenId2);
        createListing(listingObj);
        createListing(listingObj2);

        Assert.equal(totalListed(), 2, "total listed not 2");
        Assert.equal(totalListedByOwner(acc0), 2, "total listed by acc0 not 2");
    }

    /// #value: 10
    /// #sender: account-1
    function offerEnglishFail() public payable {

        try this.offer{value: 10}(englishKey, 10) {
            Assert.ok(false, "offer lower than starting should fail");
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, "Offer less than starting price", "Wrong Error message");
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, "failed without reason");
        }

    }

    /// #value: 1000000000000
    /// #sender: account-1
    function offerEnglish() public payable {
        Offer memory highest = highestOffer[englishKey];

        Assert.equal(highest.offerPrice, 0, "highest offer should be empty");
        offer(englishKey, 1000000000000);

        highest = highestOffer[englishKey];
        Assert.equal(highest.buyer, acc1, "highest offer should be acc1");
        Assert.equal(highest.offerPrice, 1000000000000, "highest offer should be 1000000000000");

    }

    /// #value: 2000000000000
    /// #sender: account-2
    function offerEnglishHigher() public payable {
        Offer memory highest = highestOffer[englishKey];

        Assert.equal(highest.offerPrice, 1000000000000, "highest offer should be 1000000000000");
        Assert.equal(highest.buyer, acc1, "highest offer should be acc1");
        offer(englishKey, 2000000000000);

        highest = highestOffer[englishKey];
        Assert.equal(highest.buyer, acc2, "highest offer should be empty");
        Assert.equal(highest.offerPrice, 2000000000000, "highest offer should be empty");
    }

    /// #sender: account-1
    function refundWithdraw() public {
        Offer[] memory offerArray = getPendingWithdraws(acc1);
        Assert.equal(offerArray.length, 1, "array length not 1");
        Assert.equal(offerArray[0].buyer, acc1, "buyer mismatch");
        Assert.equal(offerArray[0].offerPrice, 1000000000000, "offer price mismatch with offer");
        uint256 beforeWithdraw = acc1.balance;
        withdrawRefunds();
        Assert.greaterThan(acc1.balance, beforeWithdraw + 899999999999 , "all value should return");

        // Check if its deleted
        offerArray = getPendingWithdraws(acc1);
        Assert.equal(offerArray.length, 0, "array not empty");
    }

    /// #value: 100
    /// #sender: account-1
    function offerEnglishFail2() public payable {
        try this.offer{value : 1000000000}(englishKey, 1000000000) {
            Assert.ok(false, "offer lower than starting should fail");
        } catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, "Offer less than highest offer", "Wrong Error message");
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, "failed without reason");
        }
    }
    
    /// #sender: account-0
    function addBulk() public {
        // mint nft
        uint tokenId1 = mint(acc0, "bulk1");
        uint tokenId2 = mint(acc0, "bulk2");
        uint tokenId3 = mint(acc0, "bulk3");
        Assert.equal(tokenId1, 5, "NFT token id unexpected");
        Assert.equal(tokenId2, 6, "NFT token id unexpected");
        Assert.equal(tokenId3, 7, "NFT token id unexpected");

        // create listing object
        ListingParams memory listingObj;
        listingObj.nftContract = address(this);
        listingObj.listingType = ListingType.Fix;
        listingObj.listingPrice = 100;
        listingObj.duration = 600;
        listingObj.priceType = PriceType.ETHER;

        // create token id array
        uint[] memory idArr = new uint[](3);
        idArr[0] = tokenId1;
        idArr[1] = tokenId2;
        idArr[2] = tokenId3;


        Assert.equal(totalListed(), 2, "total listed not 2");
        Assert.equal(totalListedByOwner(acc0), 2, "total listed by acc0 not 2");
        // add listing
        ERC721.approve(address(this), tokenId1);
        ERC721.approve(address(this), tokenId2);
        ERC721.approve(address(this), tokenId3);
        createBulkListing(listingObj, idArr);

        Assert.equal(totalListed(), 5, "total listed not 5");
        Assert.equal(totalListedByOwner(acc0), 5, "total listed by acc0 not 5");
    }

    function updatingListing() public {
        bytes32 key = _getId(address(this), 3);

        ListingParams memory listingObj;
        listingObj.listingPrice = 80;
        listingObj.endingPrice = 8;
        listingObj.duration = 800;
        listingObj.priceType = PriceType.TOKEN;
        listingObj.tokenPayment = address(1);

        Listing memory listed = getListingByNFTKey(key);
        Assert.equal(listed.duration, 600, "duration not 600");
        Assert.equal(listed.listingPrice, 100, "price not 100");
        Assert.equal(listed.endingPrice, 10, "end price not 10");
        Assert.equal(uint(listed.priceType), uint(PriceType.ETHER), "price type not ETHER");
        Assert.equal(listed.tokenPayment, address(0), "token payment not 0");
        updateListing(listingObj, key);
        
        listed = getListingByNFTKey(key);
        Assert.equal(listed.duration, 800, "duration not 800");
        Assert.equal(listed.listingPrice, 80, "price not 80");
        Assert.equal(listed.endingPrice, 8, "end price not 8");
        Assert.equal(uint(listed.priceType), uint(PriceType.TOKEN), "price type not TOKEN");
        Assert.equal(listed.tokenPayment, address(1), "token payment not 0");

    }
}