pragma solidity 0.8.0;

// SPDX-License-Identifier: BSD-3-Clause

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

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
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


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract ToppyStandardNFT {
    function mint(address _to, bytes32 _cid) public returns (uint){}
}

contract ToppyMaster {
    uint public mintFee;
    address public platformOwner;
}
contract ToppyEventHistory {

    function addEventHistory(
        bytes32 _key,
        address _from,
        address _to,
        uint _price,
        string memory _eventType,
        address _tokenPayment,
        address _nftContract
        ) public {}
        
}

contract ToppyMint is Ownable {
    
    // =========== Start Smart Contract Setup ==============

    ToppyMaster masterSetting;
    ToppyEventHistory eventHistory;// = EventHistory(address(0xFb0D4DC54231a4D9A1780a8D85100347E6B6C41c));
    mapping(address => bool) public whitelisted;
  
    constructor(
        address _eventHistory,
        address _masterSetting
        ) {
        eventHistory = ToppyEventHistory(_eventHistory);
        masterSetting = ToppyMaster(_masterSetting);
    }
    
    mapping (bytes32 => address) public creators;
    mapping (address => bool) public eligibleContracts;
  
    function updateProperties(
        address _eventHistory,
        address _masterSetting
        ) public onlyOwner {
        eventHistory = ToppyEventHistory(_eventHistory);
        masterSetting = ToppyMaster(_masterSetting);
    }

    function updateEligibleContract(address _contract, bool _eligible) public onlyOwner {
        eligibleContracts[_contract] = _eligible;
    }
    
    function _getId(address _contract, uint _tokenId) internal pure returns(bytes32) {
        bytes32 bAddress = bytes32(uint256(uint160(_contract)));
        bytes32 bTokenId = bytes32(_tokenId);
        return keccak256(abi.encodePacked(bAddress, bTokenId));
    }

    function mintNative(address _contract, bytes32 cid) public payable {
        bool elig = eligibleContracts[_contract];
        require(elig, "not eligible contract");
        
        if(whitelisted[msg.sender] != true) {
            require(msg.value >= masterSetting.mintFee());
            TransferHelper.safeTransferBNB(masterSetting.platformOwner(), masterSetting.mintFee());
        }

        ToppyStandardNFT nft = ToppyStandardNFT(_contract);
        uint tokenId = nft.mint(msg.sender, cid);
        bytes32 key = _getId(_contract, tokenId);
        creators[key] = msg.sender;
        eventHistory.addEventHistory(key, address(0), msg.sender, 0, "mint", address(0), _contract);
    }
    
    
}
