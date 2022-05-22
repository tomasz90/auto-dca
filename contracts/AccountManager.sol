// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract AccountManager {

    mapping(address => AccountParams) public accountsParams;
    address[] public accounts;
    
    address autoDca;

    IUniswapV3Factory public immutable uniswapFactory;

    struct AccountParams {
        uint256 interval;
        uint256 nextKeepUp;
        uint256 amount;
        IUniswapV3Pool pool;
        IERC20 stableToken;
        IERC20 dcaIntoToken;
        bool paused;
    }

    modifier onlyAutoDca() {
        require(msg.sender == autoDca, "Caller is not the autoDca");
        _;
    }

    constructor(IUniswapV3Factory _uniswapFactory, address _autoDca) {
        uniswapFactory = _uniswapFactory;
        autoDca = _autoDca;
    }

    function setUpAccount(uint256 _interval, uint256 _amount, IERC20 _stableToken, IERC20 _dcaIntoToken) external {
        IUniswapV3Pool pool = findPool(_stableToken, _dcaIntoToken);
        AccountParams memory params = AccountParams(
            _interval,
            block.timestamp + _interval,
            _amount,
            pool,
            _stableToken,
            _dcaIntoToken,
            false
        );
        accountsParams[msg.sender] = params;
        accounts.push(msg.sender);
    }

    function getUserNeedKeepUp() external view returns (address user){
        for(uint i; i < accounts.length; i++) {
            AccountParams memory account = accountsParams[accounts[i]];
            uint256 nextKeepUp = account.nextKeepUp;
            bool spendable = isSpendable(accounts[i], account.stableToken, account.amount);
            if(nextKeepUp < block.timestamp && spendable) {
                user = accounts[i];
            }
        }
    }

    function setUserNextKeepUp(address user) external onlyAutoDca {
        accountsParams[user].nextKeepUp += accountsParams[user].interval;
    }

    function getSwapParams(address user) external view returns (IUniswapV3Pool pool, IERC20 stableToken, IERC20 dcaIntoToken, uint256 amount) {
        pool = accountsParams[user].pool;
        stableToken = accountsParams[user].stableToken;
        dcaIntoToken = accountsParams[user].dcaIntoToken;
        amount = accountsParams[user].amount;
    }

    function findPool(IERC20 stableToken, IERC20 dcaIntoToken) private view returns (IUniswapV3Pool) {
        uint24[3] memory fee = [uint24(100), uint24(500), uint24(3000)];
        for (uint256 i; i < fee.length; i++) {
            address poolAddress = uniswapFactory.getPool(
                address(stableToken),
                address(dcaIntoToken),
                fee[i]
            );
            if (poolAddress != address(0)) {
                return IUniswapV3Pool(poolAddress);
            }
        }

        string memory message = string(
            abi.encodePacked("No pool with tokens: ", 
            address(stableToken), 
            ", ", 
            address(dcaIntoToken)));

        revert(message);
    }

    function isSpendable(address user, IERC20 stableToken, uint256 amount) private view returns(bool) {
        uint256 allowance = stableToken.allowance(user, address(this));
        return stableToken.balanceOf(user) > amount
            && allowance > amount;
    }
}