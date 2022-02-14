pragma solidity ^0.8.0;
// SPDX-License-Identifier: GPL-3.0-or-later

import "@openzeppelin/contracts/access/Ownable.sol";

contract ToppyMaster is Ownable{

    struct creatorRoyalty {
        uint fee;
        address owner;
    }
    
    uint public durationExtension = 600;
    uint public mintFee = 5000000000000000;
    address public platformOwner = address(0x62691eF999C7F07BC1653416df0eC4f3CDDBb0c7);
    uint public platformComm = 500;
    mapping (address => creatorRoyalty) public creatorRoyalties;
    
    // ---------------- owner modifier functions ------------------------
    function setMintFee(uint _mintFee) public onlyOwner {
        mintFee = _mintFee;
    }
    function setPlatform(uint _platformComm, address _platformOwner) public onlyOwner {
        platformComm = _platformComm;
        platformOwner = _platformOwner;
    }
    function setDurationExtension(uint _durationExtension) public onlyOwner {
        durationExtension = _durationExtension;
    }
    function updateMyRoyalty(uint _fee) public {
        
        require(_fee <= 1000, "cannot set more than 10%");
        creatorRoyalty storage creator = creatorRoyalties[msg.sender];
        creator.owner = msg.sender;
        creator.fee = _fee;
    }
    
    function getCalcFeeInfo(address _creatorOwnerAddress, uint baseAmount) public view returns (uint creatorFee, uint platformFee, uint amountAfterFee) {
        
        creatorRoyalty memory creator = creatorRoyalties[_creatorOwnerAddress];
        creatorFee = (baseAmount * creator.fee) / 10000;
        platformFee = (baseAmount * platformComm) / 10000;
        amountAfterFee = baseAmount - platformFee - creatorFee;
        return (creatorFee, platformFee, amountAfterFee);
    }
}
