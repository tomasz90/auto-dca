// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract AccountManager {

    mapping(address => AccountParams) public accountsParams;
    address[] public accounts;
    
    address public immutable autoDca;

    IUniswapV3Factory public immutable uniswapFactory;

    struct AccountParams {
        uint256 interval;
        uint256 nextExec;
        uint256 amount;
        uint24 poolFee;
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

    function setUpAccount(uint256 interval, uint256 amount, IERC20 stableToken, IERC20 dcaIntoToken) external {
        uint24 poolFee = findPool(stableToken, dcaIntoToken);
        AccountParams memory params = AccountParams(
            interval,
            block.timestamp + interval,
            amount,
            poolFee,
            stableToken,
            dcaIntoToken,
            false
        );
        bool notExists = accountsParams[msg.sender].nextExec == 0;
        accountsParams[msg.sender] = params;
        if(notExists) {
            accounts.push(msg.sender);
        }
    }

    function pause() external {
        bool exists = accountsParams[msg.sender].nextExec != 0;
        if(exists) {
            accountsParams[msg.sender].paused = true;
        }
    }

    function unpause() external {
        bool exists = accountsParams[msg.sender].nextExec != 0;
        if(exists) {
            accountsParams[msg.sender].paused = false;
        }
    }

    function getUserNeedExec() external view returns (address user) {
        for(uint i; i < accounts.length; i++) {
            AccountParams memory account = accountsParams[accounts[i]];
            uint256 nextExec = account.nextExec;
            bool spendable = isSpendable(accounts[i], account.stableToken, account.amount);
            if(nextExec < block.timestamp && spendable) {
                user = accounts[i];
            }
        }
    }

    function isExecTime(address user) external view returns(bool) {
        return accountsParams[user].nextExec < block.timestamp;
    }

    function setUserNextExec(address user) external onlyAutoDca {
        accountsParams[user].nextExec += accountsParams[user].interval;
    }

    function getSwapParams(address user) external view returns (uint24 poolFee, IERC20 stableToken, IERC20 dcaIntoToken, uint256 amount) {
        poolFee = accountsParams[user].poolFee;
        stableToken = accountsParams[user].stableToken;
        dcaIntoToken = accountsParams[user].dcaIntoToken;
        amount = accountsParams[user].amount;
    }

    function findPool(IERC20 stableToken, IERC20 dcaIntoToken) private view returns (uint24) {
        uint24[3] memory fee = [uint24(100), uint24(500), uint24(3000)];
        for (uint256 i; i < fee.length; i++) {
            address poolAddress = uniswapFactory.getPool(
                address(stableToken),
                address(dcaIntoToken),
                fee[i]
            );
            if (poolAddress != address(0)) {
                return fee[i];
            }
        }

        string memory message = string(
            abi.encodePacked("No pool with tokens: ", 
            address(stableToken), 
            ", ", 
            address(dcaIntoToken)));

        revert(message);
    }

    function isSpendable(address user, IERC20 stableToken, uint256 amount) private view returns (bool) {
        uint256 allowance = stableToken.allowance(user, autoDca);
        return stableToken.balanceOf(user) > amount
            && allowance > amount;
    }
}