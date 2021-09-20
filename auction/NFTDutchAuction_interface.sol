// pragma solidity ^0.4.24;
pragma solidity 0.8.0;

import "./NFToken.sol";

contract NFTDutchAuction {

  struct Auction {
      uint64 id;
      address seller;
      uint256 tokenId;
      uint128 startingPrice; // wei
      uint128 endingPrice; // wei
      uint64 duration; // seconds
      uint64 startedAt; // time
  }

  ERC721 public NFTContract;

  uint64 public auctionId; // max is 18446744073709551615

  mapping (uint256 => Auction) internal tokenIdToAuction;
  mapping (uint64 => Auction) internal auctionIdToAuction;

  event AuctionCreated(uint64 auctionId, uint256 tokenId,
                      uint256 startingPrice, uint256 endingPrice, uint256 duration);
  event AuctionCancelled(uint64 auctionId, uint256 tokenId);
  event AuctionSuccessful(uint64 auctionId, uint256 tokenId, uint256 totalPrice, address winner);

  constructor(address _NFTAddress) public {
      NFTContract = ERC721(_NFTAddress);
  }

  // return ether that is sent to this contract
 // fallback function() external {}

  function createAuction(
      uint256 _tokenId, uint256 _startingPrice,
      uint256 _endingPrice, uint256 _duration) public {
  }

  function getAuctionByAuctionId(uint64 _auctionId) public view returns (
      uint64 id,
      address seller,
      uint256 tokenId,
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 duration,
      uint256 startedAt
  ) {
  }

  function getAuctionByTokenId(uint256 _tokenId) public view returns (
      uint64 id,
      address seller,
      uint256 tokenId,
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 duration,
      uint256 startedAt
  ) {

  }

  function cancelAuctionByAuctionId(uint64 _auctionId) public {

  }

  function cancelAuctionByTokenId(uint256 _tokenId) public {

  }

  function bid(uint256 _tokenId) public payable {

  }

  function getCurrentPriceByAuctionId(uint64 _auctionId) public view returns (uint256) {

  }

  function getCurrentPriceByTokenId(uint256 _tokenId) public view returns (uint256) {

  }

  function getCurrentPrice(Auction storage _auction) internal view returns (uint256) {

  }
}
