pragma solidity ^0.8.0;

// SPDX-License-Identifier: BSD-3-Clause
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ToppyMasterSetting.sol";
import "./ToppyStandardNFT.sol";
import "./TransferHelper.sol";
import "./ToppyStandardNFT.sol";
import "./ToppyMysteriousNFT.sol";
import "./IBEP20.sol";
import "./IToppyMint.sol";

contract ToppyMint is Ownable, ReentrancyGuard, IToppyMint {
    
    // =========== Start Smart Contract Setup ==============

    ToppyMaster masterSetting;
    mapping(address => bool) public whitelisted;
    
    constructor(
        address _masterSetting
        ) {
        masterSetting = ToppyMaster(_masterSetting);
    }
    
    mapping (bytes32 => address) public creators;
    mapping (address => bool) public eligibleContracts;
  
    function updateProperties(
        address _masterSetting
        ) public onlyOwner {
        masterSetting = ToppyMaster(_masterSetting);
    }

    function updateEligibleContract(address _contract, bool _eligible) public onlyOwner {
        eligibleContracts[_contract] = _eligible;
    }
    
    function _getId(address _contract, uint _tokenId) internal pure returns(bytes32) {
        bytes32 bAddress = bytes32(uint256(uint160(_contract)));
        bytes32 bTokenId = bytes32(_tokenId);
        return keccak256(abi.encodePacked(bAddress, bTokenId));
    }

    function mintNative(address _contract, string memory cid) external override nonReentrant payable {
        bool elig = eligibleContracts[_contract];
        require(elig, "not eligible contract");
        
        if(whitelisted[msg.sender] != true) {
            require(msg.value >= masterSetting.mintFee());
            TransferHelper.safeTransferBNB(masterSetting.platformOwner(), masterSetting.mintFee());
        }
        ToppyStandardNFT nft = ToppyStandardNFT(_contract);
        uint tokenId = nft.mint(msg.sender, cid);
        bytes32 key = _getId(_contract, tokenId);
        creators[key] = msg.sender;
        emit Minted(key, msg.sender, _contract, tokenId, cid);
    }

    function mintMysteryBox(address _contract, address _to, uint256 _mintAmount) external override nonReentrant payable {
        
        bool elig = eligibleContracts[_contract];
        require(elig, "not eligible contract");
        
        ToppyMysteriousNFT nft = ToppyMysteriousNFT(_contract);
        require(nft.validateInput(_mintAmount), "quantity not allow");
        address creator = nft.creatorAddress();
        //make payment
        _payFee(_mintAmount, nft);

        // then mint
        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint tokenId = nft.mint(_to);
            bytes32 key = _getId(_contract, tokenId);
            creators[key] = creator;
            emit Minted(key, msg.sender, _contract, tokenId, "");
            emit ListingSuccessful(key, 0, _contract, tokenId, nft.cost(), creator, msg.sender, nft.tokenPayment());
        }
    }

    function reveal(address _contract, uint tokenId) external override nonReentrant payable {

      ToppyMysteriousNFT nft = ToppyMysteriousNFT(_contract);
      bytes32 key = _getId(_contract, tokenId);
      nft.reveal(msg.sender, tokenId);
      emit Reveal(key, tokenId, _contract, msg.sender);
    }

    function revealAll(address _contract, uint[] calldata tokenIds) external override nonReentrant payable {

      ToppyMysteriousNFT nft = ToppyMysteriousNFT(_contract);
      nft.revealAll(msg.sender, tokenIds);

      for(uint i=0; i < tokenIds.length; i++){
          bytes32 key = _getId(_contract, tokenIds[i]);
          emit Reveal(key, tokenIds[i], _contract, msg.sender);
        }
    }


    function _payFee(uint _mintAmount, ToppyMysteriousNFT nft) internal {

        uint totalAmount = nft.cost() * _mintAmount;
        address tokenPayment = nft.tokenPayment();
        uint8 priceType = nft.getPriceType();
        if(priceType == 0){
            require(msg.value >= totalAmount, "not enough BNB balance");
        }else{
            require(IBEP20(tokenPayment).balanceOf(msg.sender) >= totalAmount, "Not enough token balance");
            TransferHelper.safeTransferFrom(tokenPayment, msg.sender, address(this), totalAmount);
        }

        uint creatorFee = totalAmount * nft.creatorComm() / 10000;
        uint platformFee = totalAmount * nft.platformComm() / 10000;
        uint managerFee = totalAmount * nft.managerComm() / 10000;
        address creatorAddress = nft.creatorAddress();
        address platformAddress = nft.platformAddress();
        address managerAddress = nft.managerAddress();
        
        if (priceType == 0) {
            TransferHelper.safeTransferBNB(creatorAddress, creatorFee);
            TransferHelper.safeTransferBNB(platformAddress, platformFee);
            TransferHelper.safeTransferBNB(managerAddress, managerFee);
        }else{
            TransferHelper.safeTransfer(tokenPayment, creatorAddress, creatorFee);
            TransferHelper.safeTransfer(tokenPayment, platformAddress, platformFee);
            TransferHelper.safeTransfer(tokenPayment, managerAddress, managerFee);
        }
    }

    function isElegible(address _contract) external override view returns(bool) {
        return eligibleContracts[_contract];
    }

    function getCreator(bytes32 _hash) external override view returns(address) {
        return creators[_hash];
    }

}
