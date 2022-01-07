// pragma solidity ^0.4.24;
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

contract ToppyMaster is Ownable{

    using SafeMath for uint;
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
    function setPlatformComm(uint _platformComm) public onlyOwner {
        platformComm = _platformComm;
    }
    function setDurationExtension(uint _durationExtension) public onlyOwner {
        durationExtension = _durationExtension;
    }
    function updateMyRoyalty(uint _fee) public {
        
        creatorRoyalty storage creator = creatorRoyalties[msg.sender];
        creator.owner = msg.sender;
        creator.fee = _fee;
    }
    
    function getCalcFeeInfo(address _creatorOwnerAddress, uint baseAmount) public view returns (uint creatorFee, uint platformFee, uint amountAfterFee) {
        
        creatorRoyalty memory creator = creatorRoyalties[_creatorOwnerAddress];
        creatorFee = baseAmount.mul(creator.fee).div(10000);
        platformFee = baseAmount.mul(platformComm).div(10000);
        amountAfterFee = baseAmount.sub(platformFee).sub(creatorFee);
        return (creatorFee, platformFee, amountAfterFee);
    }
}
