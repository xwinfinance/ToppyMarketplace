// SPDX-License-Identifier: GPLv2

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ToppyMint.sol";
import "./ToppyMasterSetting.sol";
import "./BEP20.sol";

contract xWinDefi  {
    
    struct UserInfo {
        uint256 amount;     
        uint256 blockstart; 
    }
    struct PoolInfo {
        address lpToken;           
        uint256 rewardperblock;       
        uint256 multiplier;       
    }
    function DepositFarm(uint256 _pid, uint256 _amount) public {}
    function pendingXwin(uint256 _pid, address _user) public view returns (uint256) {}
    function WithdrawFarm(uint256 _pid, uint256 _amount) public {}
    
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    PoolInfo[] public poolInfo;
}

contract ToppyStaking is Ownable, ReentrancyGuard, BEP20 {
    using SafeMath for uint;
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    struct UserInfo {
        uint amount;
        uint rewardDebt;
        mapping (uint => uint) tokenStakedAmount;
         
    }

    // Info of each pool.
    struct PoolInfo {
        address nftToken;           
        uint totalStakedBalance;
        uint endPeriod;
        uint allocPoint;       // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint lastRewardBlock;  // Last block number that CAKEs distribution occurs.
        uint accCakePerShare; // Accumulated CAKEs per share, times 1e18. See below.
    }

    ToppyMaster toppyMaster = ToppyMaster(address(0x00b62376D5B2FA1EC07C326CAd3EC7F9AA633972));
    ToppyMint toppyMint = ToppyMint(address(0x9C44C1b9567261DAe866624719b0Cd2d26241A42));
    address public rewardsToken = address(0xa83575490D7df4E2F47b7D38ef351a2722cA45b9);
    address public burnAddress = address(0x000000000000000000000000000000000000dEaD);
    xWinDefi public _xwinDefi = xWinDefi(address(0xebAee150352ba99FcA309C9D57E14DC77736470e));
    PoolInfo[] public poolInfo;
    uint public burnFee = 500; 
     // CAKE tokens created per block.
    uint public xwinPerBlock;
     // Total allocation points. Must be the sum of all allocation points in all pools.
    uint public totalAllocPoint = 0;
    uint public startBlock;
    uint public BONUS_MULTIPLIER = 1;
    uint public DEFAULT_SCORE = 1e18;
    uint public xwinpid;

    /// @notice mapping of a nft token to its current properties
    mapping (uint => mapping (bytes32 => UserInfo)) public userInfo;
    
    // Mapping from token ID to owner address
    mapping (address => mapping (uint => address)) public tokenOwner;
    
    /// @notice tokenId => amount contributed
    mapping (address => mapping (uint => uint)) public nftScores;
    
    event Staked(address indexed user, uint indexed pid, uint amount, uint tokenId);
    event Unstaked(address indexed user, uint indexed pid, uint amount, uint tokenId);
    event EmergencyWithdraw(address indexed user, uint indexed pid, uint tokenId);
    event RewardPaid(address indexed user, uint reward);
    event Received(address, uint);
    

    constructor(
        string memory name,
        string memory symbol
    )  BEP20(name, symbol) {
        
        startBlock = block.number;
        _mint(address(this), 1 * 10 ** 18);
    }

    function farmTokenByAdmin() public onlyOwner {
        TransferHelper.safeApprove(address(this), address(_xwinDefi), totalSupply()); 
        _xwinDefi.DepositFarm(xwinpid, totalSupply());
    } 

    function unFarmTokenByAdmin() public onlyOwner {
        _xwinDefi.WithdrawFarm(xwinpid, totalSupply());
    }

    // initial properties needed by admin 
    function updateProperties(
        address _rewardsToken,
        uint _xwinpid,
        uint _xwinPerBlock
    ) public onlyOwner
    {
        rewardsToken = _rewardsToken;
        xwinpid = _xwinpid;
        xwinPerBlock = _xwinPerBlock;
    }

    function poolLength() external view returns (uint) {
        return poolInfo.length;
    }

    function updateSmartContract(address _toppyMaster, address _toppyMint, address _xwinDefiaddr) public onlyOwner {
        toppyMaster = ToppyMaster(_toppyMaster);
        toppyMint = ToppyMint(_toppyMint);
         _xwinDefi = xWinDefi(_xwinDefiaddr);
        
    }

    // Update the given pool's CAKE allocation point. Can only be called by the owner.
    function set(uint _pid, uint _allocPoint, bool _withUpdate, uint _newDuration) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].endPeriod = _newDuration.mul(28750).add(block.number);
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            //updateStakingPool();
        }
    }

    // admin to stop the pool staking
    function stopPool(uint _pid) public onlyOwner {
        _stopPool(_pid);
    }

    function updateDefaultScore(uint _default) public onlyOwner {
        DEFAULT_SCORE = _default;
    }

    function _stopPool(uint _pid) internal {
        
        uint prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = 0;
        poolInfo[_pid].endPeriod = block.number;
        poolInfo[_pid].lastRewardBlock = block.number;
        totalAllocPoint = totalAllocPoint.sub(prevAllocPoint);
        // _xwinDefi.WithdrawFarm(xwinpid, poolInfo[_pid].totalStakedBalance);
        // _burn(address(this), poolInfo[_pid].totalStakedBalance);
        //poolInfo[_pid].totalStakedBalance = 0;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint _allocPoint, address _nftToken, bool _withUpdate, uint _duration) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            nftToken: _nftToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accCakePerShare: 0,
            totalStakedBalance : 0,
            endPeriod: _duration.mul(28750).add(block.number)
        }));
        // updateStakingPool();
    }

    // View function to see pending CAKEs on frontend.
    function pendingRewards(uint _pid, uint _tokenId) external view returns (uint) {
        PoolInfo memory pool = poolInfo[_pid];
        bytes32 hashedKey = _getId(pool.nftToken, _tokenId);
        UserInfo storage user = userInfo[_pid][hashedKey];
        uint accCakePerShare = pool.accCakePerShare;
        if (block.number > pool.lastRewardBlock && pool.totalStakedBalance != 0) {
            
            uint multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint cakeReward = multiplier.mul(xwinPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCakePerShare = accCakePerShare.add(cakeReward.mul(1e18).div(pool.totalStakedBalance));
        }
        return user.amount.mul(accCakePerShare).div(1e18).sub(user.rewardDebt);
    }
    
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint _from, uint _to) public view returns (uint) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function updateStakingPool() internal {
        uint length = poolInfo.length;
        uint points = 0;
        for (uint pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(points);
            poolInfo[0].allocPoint = points;
        }
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint length = poolInfo.length;
        for (uint pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.totalStakedBalance == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        
        uint multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint cakeReward = multiplier.mul(xwinPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        
        //harvest from xwin farm
        _xwinDefi.DepositFarm(xwinpid, 0);
        pool.accCakePerShare = pool.accCakePerShare.add(cakeReward.mul(1e18).div(pool.totalStakedBalance));
        pool.lastRewardBlock = block.number;

        if(pool.endPeriod < block.number){
            _stopPool(_pid);
        }
    }

    /// @dev Get the rarity score of each nft at the collection base
    function getNFTScores (address _nftToken, uint _tokenId) public view returns (uint amount) {
        // if no score but still allow for interest
        if(nftScores[_nftToken][_tokenId] == 0) return DEFAULT_SCORE;
        return nftScores[_nftToken][_tokenId];
    }

    /// user to register to stake nft. Once register, any user who hold the nft can enjoy having the interests
    function stake(uint _pid, uint tokenId) external nonReentrant payable {
        PoolInfo memory pool = poolInfo[_pid];
        require(pool.endPeriod > block.number, "stop staking");
        _stake(msg.sender, _pid, tokenId);
    }

    // register nft token by user
    function _stake(
        address _user,
        uint _pid,
        uint _tokenId
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        require(IERC721(pool.nftToken).ownerOf(_tokenId) == msg.sender, "you are not owner of nft");
        bytes32 hashedKey = _getId(pool.nftToken, _tokenId);
        UserInfo storage user = userInfo[_pid][hashedKey];
        require(user.amount == 0, "already staked nft");
        uint amount = getNFTScores(pool.nftToken, _tokenId);
        require(amount > 0, "no score for staking");

        updatePool(_pid);
        if (user.amount > 0) {
            uint pending = user.amount.mul(pool.accCakePerShare).div(1e18).sub(user.rewardDebt);
            if(pending > 0) {
                _safexWINTransfer(msg.sender, pending, hashedKey);
            }
        }
        // update amount first before rewardDebt
        user.amount = user.amount.add(amount);
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e18);
        pool.totalStakedBalance = pool.totalStakedBalance.add(amount); //update total staked amount by pool basis
        user.tokenStakedAmount[_tokenId] = amount;

        /// start farming in xwin
        // _mint(address(this), amount);
        // TransferHelper.safeApprove(address(this), address(_xwinDefi), amount); 
        // _xwinDefi.DepositFarm(xwinpid, amount);
        
        emit Staked(_user, _pid, amount, _tokenId);
    }

    // harvest to get xwin as interest for nft owner
    function harvest(uint _pid, uint _tokenId) public nonReentrant payable{

        PoolInfo storage pool = poolInfo[_pid];
        require(IERC721(pool.nftToken).ownerOf(_tokenId) == msg.sender, "you are not owner of nft");
        bytes32 hashedKey = _getId(pool.nftToken, _tokenId);
        UserInfo storage user = userInfo[_pid][hashedKey];
        updatePool(_pid);
        uint pending = 0;
        if (user.amount > 0) {
            pending = user.amount.mul(pool.accCakePerShare).div(1e18).sub(user.rewardDebt);
            if(pending > 0) {
                _safexWINTransfer(msg.sender, pending, hashedKey);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e18);
        emit RewardPaid(msg.sender, pending);
    }

    // Set contribution amounts for NFTs
    function setNFTScores(
        address nftToken,
        uint[] memory tokens,
        uint[] memory amounts
    ) external onlyOwner{
        
        for (uint i = 0; i < tokens.length; i++) {
            uint tokenId = tokens[i];
            uint amount = amounts[i];
            nftScores[nftToken][tokenId] = amount;
        }
    }

    // Creator get the percentage of the fee staked
    function _safexWINTransfer(address _to, uint _amount, bytes32 _hashedKey) internal {

        address creatorOwnerAddress = toppyMint.creators(_hashedKey);
        uint royaltyFeeTotal = 0;
        if(creatorOwnerAddress != address(0)){
            (uint royaltyFee ,) = toppyMaster.creatorRoyalties(creatorOwnerAddress);
            royaltyFeeTotal = _amount.mul(royaltyFee).div(10000);
            TransferHelper.safeTransfer(rewardsToken, creatorOwnerAddress, royaltyFeeTotal); 
        }
        uint burnFeeTotal = _amount.mul(burnFee).div(10000);
        TransferHelper.safeTransfer(rewardsToken, burnAddress, burnFeeTotal); 
        TransferHelper.safeTransfer(rewardsToken, _to, _amount.sub(burnFeeTotal).sub(royaltyFeeTotal));
    }

    function _getId(address _contract, uint _tokenId) internal pure returns(bytes32) {
        bytes32 bAddress = bytes32(uint256(uint160(_contract)));
        bytes32 bTokenId = bytes32(_tokenId);
        return keccak256(abi.encodePacked(bAddress, bTokenId));
    }

    function onERC721Received(
        address,
        address,
        uint,
        bytes calldata) public pure returns(bytes4) {
        return _ERC721_RECEIVED;
    }
}