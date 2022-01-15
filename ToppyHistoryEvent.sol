pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later

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

contract ToppyEventHistory is Ownable{

  struct eventHistory {
        address from;
        address to;
        uint createDt;
        uint price;
        string eventType;
        address tokenPayment;
    }
  
    mapping (address => eventHistory[]) public eventHistoriesByContract;
    mapping (bytes32 => eventHistory[]) public eventHistories;
    mapping (address => bool) public eligibleContracts;
  
    constructor() {}

    function getEventHistories(bytes32 _key) public view returns (eventHistory[] memory) {
        return  eventHistories[_key];
    }
    
    function getEventHistoriesByContract(address _nftContract) public view returns (eventHistory[] memory) {
        return  eventHistoriesByContract[_nftContract];
    }
    
    function updateEligibleContract(address _contract, bool _eligible) public onlyOwner {
        eligibleContracts[_contract] = _eligible;
    }
    
    function addEventHistory(
        bytes32 _key,
        address _from,
        address _to,
        uint _price,
        string memory _eventType,
        address _tokenPayment,
        address _nftContract
        ) public {
        
        require(eligibleContracts[msg.sender] == true, "not allow");
        eventHistories[_key].push(eventHistory(_from, _to, block.timestamp, _price, _eventType, _tokenPayment));
        
        if(keccak256(bytes(_eventType)) == keccak256(bytes("acceptOffer")) 
          || keccak256(bytes(_eventType)) == keccak256(bytes("bid"))){
          eventHistoriesByContract[_nftContract].push(eventHistory(_from, _to, block.timestamp, _price, _eventType, _tokenPayment));
        }
    }
    
  
}
