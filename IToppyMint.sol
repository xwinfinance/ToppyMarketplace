// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

interface IToppyMint {

    event Reveal(bytes32 key, uint256 tokenId, address nftContract, address owner);
  
    event Minted(bytes32 key, address from, address nftContract, uint tokenId, string cid);

    event ListingSuccessful(bytes32 key, uint listingId, address nftContract, uint tokenId, uint256 totalPrice, address owner, address buyer, address tokenPayment);
    
    function mintNative(address _contract, string memory cid) external payable;

    function mintMysteryBox(address _contract, address _to, uint256 _mintAmount) external payable;
    
    function isElegible(address _contract) external view returns(bool);

    function getCreator(bytes32 _hash) external view returns(address);

    function reveal(address _contract, uint tokenId) external payable;

    function revealAll(address _contract, uint[] calldata tokenIds) external payable;
}