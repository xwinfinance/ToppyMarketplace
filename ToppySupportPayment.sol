pragma solidity ^0.8.0;
// SPDX-License-Identifier: GPL-3.0-or-later

import "@openzeppelin/contracts/access/Ownable.sol";

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
