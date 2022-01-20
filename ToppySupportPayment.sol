// pragma solidity ^0.4.24;
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

contract ToppySupportPayment is Ownable{

    mapping (address => bool) public eligibleTokens;
  
    constructor() {}

    function isEligibleToken(address _token) public view returns (bool){
        return eligibleTokens[_token];
    }
    
    function addSupportedPayments(address[] calldata _paymentAddress, bool[] calldata _eligible) public onlyOwner {
        
        for (uint i = 0; i < _paymentAddress.length; i++) {
            eligibleTokens[_paymentAddress[i]] = _eligible[i];
        }
    }
}
