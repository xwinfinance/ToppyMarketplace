// SPDX-License-Identifier: GPL-3.0

// by ToppyNFT
pragma solidity = 0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract ToppyStandardNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;
    
  string public baseURI;
  string public baseFileName = "/metadata.json";
  bool public paused = false;
  mapping(address => bool) public whitelisted;
  mapping(uint => bytes32) public nftCID;
  mapping (address => bool) public eligibleMINTERS;
  
  uint public TOKENID = 1;
  
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

    function setEligibleMinters(address _minter, bool _eligible) public onlyOwner {
        eligibleMINTERS[_minter] = _eligible;
    }
    
    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function burn(uint256 tokenId) public {    
        require(msg.sender == ownerOf(tokenId), "");
        _burn(tokenId);
    }

    // public
    function mint(address _to, bytes32 _cid) public returns (uint){
        
        require(eligibleMINTERS[msg.sender] == true, "not allow");
        require(!paused);
        _safeMint(_to, TOKENID);
        nftCID[TOKENID] = _cid;
        uint tmpID = TOKENID;
        TOKENID++;
        return tmpID;
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
        
        // ipfs://bafyreichtw2fahhlbxcv7fj5r6a6pectczszxobplm7onuehakdh2ugky4/metadata.json
        // currentBaseURI = "ipfs://"
        // baseFileName = "metadata.json"
        // https://bafyreif7mqmjnzv6z2mufxlmrziqnbe7qlozupb2jszmy6ugfbdvayanr4.ipfs.dweb.link/metadata.json

        bytes32 cid = nftCID[tokenId];
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, cid, baseFileName))
            : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseFileName(string memory _baseFileName) public onlyOwner {
        baseFileName = _baseFileName;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
 
}