// pragma solidity ^0.4.24;
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
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

contract EventHistory is Ownable{

  struct eventHistory {
        address from;
        address to;
        uint createDt;
        uint price;
        string eventType;
    }
    

    mapping (bytes32 => eventHistory[]) public eventHistories;
    mapping (address => bool) public eligibleContracts;
  
    constructor() public {}

    function getEventHistories(bytes32 _key) public view returns (eventHistory[] memory) {
        return  eventHistories[_key];
    }
    
    function addEligibleContract(address _contract) public onlyOwner {
        eligibleContracts[_contract] = true;
    }
    
    function addEventHistory(
        bytes32 _key,
        address _from,
        address _to,
        uint _price,
        string memory _eventType
        ) public {
        
        require(eligibleContracts[msg.sender] == true, "not allow");
        eventHistories[_key].push(eventHistory(_from, _to, block.timestamp, _price, _eventType));
        
    }
    
  
}
