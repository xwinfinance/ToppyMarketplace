// SPDX-License-Identifier: GPLv2

pragma solidity 0.8.0;

import "./ToppyMysteriousNFT.sol";


contract ReentrancyGuard {
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    
    /*function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }*/

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance')
        );
    }
    
    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

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


contract ToppyMaster {
    struct creatorRoyalty {
        uint fee;
        address owner;
    }
    mapping (address => creatorRoyalty) public creatorRoyalties;

    function getCalcFeeInfo(address _creatorOwnerAddress, uint baseAmount) 
    public view returns (uint creatorFee, uint platformFee, uint amountAfterFee) {}
    
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
    ToppyMint toppyMint = ToppyMint(address(0x762AdB198269b856D403B9B1dc3bB7dACEa9fD0C));
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
    uint public DEFAULT_SCORE = 0;
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

    function _stopPool(uint _pid) internal {
        
        uint prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = 0;
        poolInfo[_pid].endPeriod = block.number;
        poolInfo[_pid].lastRewardBlock = block.number;
        totalAllocPoint = totalAllocPoint.sub(prevAllocPoint);
        _xwinDefi.WithdrawFarm(xwinpid, poolInfo[_pid].totalStakedBalance);
        _burn(address(this), poolInfo[_pid].totalStakedBalance);
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
        _mint(address(this), amount);
        TransferHelper.safeApprove(address(this), address(_xwinDefi), amount); 
        _xwinDefi.DepositFarm(xwinpid, amount);
        
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
        bytes calldata data) public returns(bytes4) {
        return _ERC721_RECEIVED;
    }
}