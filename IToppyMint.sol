// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

interface IToppyMint {

    event Minted(bytes32 key, address from, address nftContract, uint tokenId, string cid);

    event ListingSuccessful(bytes32 key, uint listingId, address nftContract, uint tokenId, uint256 totalPrice, address owner, address buyer, address tokenPayment);
    
    function mintNative(address _contract, string memory cid) external payable;

    function mintMysteryBox(address _contract, address _to, uint256 _mintAmount) external payable;

    function isElegible(address _contract) external view returns(bool);

    function getCreator(bytes32 _hash) external view returns(address);
}