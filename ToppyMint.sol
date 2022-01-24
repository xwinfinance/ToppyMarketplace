pragma solidity ^0.8.0;

// SPDX-License-Identifier: BSD-3-Clause

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ToppyMasterSetting.sol";
import "./ToppyStandardNFT.sol";
import "./TransferHelper.sol";

contract ToppyMint is Ownable {
    
    // =========== Start Smart Contract Setup ==============

    ToppyMaster masterSetting;
    mapping(address => bool) public whitelisted;
  
    event Minted(bytes32 key, address from, address nftContract, uint tokenId, string cid);
  
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

    function setCreator(address _creator, uint _tokenId, address _nftContract) public {

        bool elig = eligibleContracts[_nftContract];
        require(elig, "not eligible contract");
        bytes32 key = _getId(_nftContract, _tokenId);
        creators[key] = _creator;
    }

    function mintNative(address _contract, string memory cid) public payable {
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
    
    
}
