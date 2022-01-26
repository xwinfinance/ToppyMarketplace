//SPDX-License-Identifier: UNLICENSED

 pragma solidity ^0.8.0;
 import "remix_tests.sol"; // this import is automatically injected by Remix.
 import "remix_accounts.sol";
 import "../contracts/ToppyMarketplace.sol";
 import "../contracts/ToppyStandardNFT.sol";

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
        setPause(false);
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
        listingObj.listingPrice = 1;
        listingObj.duration = 61;
        listingObj.priceType = PriceType.ETHER;

        // get id
        bytes32 testKey = _getId(address(this), 1);

        Assert.equal(listingId, 0, "listing id not 0");
        // add listing
        createListing(listingObj);

        // get listing
        Listing memory testListing = getListingByNFTKey(testKey);
    
        // check
        Assert.equal(testListing.id, 0, "listing id not 0");
        Assert.equal(testListing.tokenId, 1, "token id not 1");
        Assert.equal(testListing.seller, acc0, "listing owner mismatch");
        Assert.equal(isAuctionExpired(testKey), false, "Auction expired");

    }

    /// #value: 1000000000000000000
    /// #sender: account-1
    function buyListing() public {
        Assert.ok(testPay(), "Failed");
    }

    /// #sender: account-0
    function addAndRemoveListing() public {
        // mint nft
        uint tokenId = mint(acc0, "testcid");
        Assert.equal(tokenId, 2,"impossible");

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
            Assert.ok(false, "failed unexpected");
        }

    }
    // TODO
    // bid 
    // accept offer

    // types of listing, (english, dutch, fixed)
 }